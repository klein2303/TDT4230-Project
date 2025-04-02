#include <chrono>
#include <GLFW/glfw3.h>
#include <glad/glad.h>
#include <SFML/Audio/SoundBuffer.hpp>
#include <utilities/shader.hpp>
#include <glm/vec3.hpp>
#include <iostream>
#include <utilities/timeutils.h>
#include <utilities/mesh.h>
#include <utilities/shapes.h>
#include <utilities/glutils.h>
#include <SFML/Audio/Sound.hpp>
#include <glm/gtc/matrix_transform.hpp>
#include <glm/gtc/type_ptr.hpp>
#include <fmt/format.h>
#include "gamelogic.h"
#include "sceneGraph.hpp"
#define GLM_ENABLE_EXPERIMENTAL
#include <glm/gtx/transform.hpp>

#include "utilities/imageLoader.hpp"
#include "utilities/glfont.h"

enum KeyFrameAction
{
    BOTTOM,
    TOP
};

#include <timestamps.h>

double padPositionX = 0.0;
double padPositionZ = 0.0;
double padPositionY = 2.0;

float yaw = 0.0;
float pitch = 0.3;

unsigned int currentKeyFrame = 0;
unsigned int previousKeyFrame = 0;

SceneNode *rootNode;
SceneNode *boxNode;
SceneNode *padNode;
SceneNode *light1;
SceneNode *light2;
SceneNode *movingLightNode;
SceneNode *grassNode;

double ballRadius = 3.0f;

PNGImage charmap = loadPNGFile("../res/textures/charmap.png");
PNGImage diffuseTexture = loadPNGFile("../res/textures/Brick03_col.png");
PNGImage normalmap = loadPNGFile("../res/textures/Brick03_nrm.png");

PNGImage skyboxRight = loadPNGFile("../res/cubemap2/right.png");
PNGImage skyboxLeft = loadPNGFile("../res/cubemap2/left.png");
PNGImage skyboxUp = loadPNGFile("../res/cubemap2/up.png");
PNGImage skyboxDown = loadPNGFile("../res/cubemap2/down.png");
PNGImage skyboxFront = loadPNGFile("../res/cubemap2/front.png");
PNGImage skyboxBack = loadPNGFile("../res/cubemap2/back.png");

// Rekkefølgen må være slik:
PNGImage cubemap_images[] = {
    skyboxRight,
    skyboxLeft,
    skyboxUp,
    skyboxDown,
    skyboxFront,
    skyboxBack,
};

// These are heap allocated, because they should not be initialised at the start of the program
sf::SoundBuffer *buffer;
Gloom::Shader *shader;
Gloom::Shader *grassShader;
Gloom::Shader *skyboxShader;
sf::Sound *sound;

const glm::vec3 boxDimensions(180, 90, 90);
const glm::vec3 padDimensions(80, 0, 70);

CommandLineOptions options;

bool hasStarted = false;
bool hasLost = false;
bool jumpedToNextFrame = false;
bool isPaused = false;

bool mouseLeftPressed = false;
bool mouseLeftReleased = false;
bool mouseRightPressed = false;
bool mouseRightReleased = false;

// Modify if you want the music to start further on in the track. Measured in seconds.
const float debug_startTime = 0;
double totalElapsedTime = debug_startTime;
double gameElapsedTime = debug_startTime;

double mouseSensitivity = 1.0;
double lastMouseX = windowWidth / 2;
double lastMouseY = windowHeight / 2;
void mouseCallback(GLFWwindow *window, double x, double y)
{
    int windowWidth, windowHeight;
    glfwGetWindowSize(window, &windowWidth, &windowHeight);
    glViewport(0, 0, windowWidth, windowHeight);

    double deltaX = x - lastMouseX;
    double deltaY = y - lastMouseY;

    padPositionX -= mouseSensitivity * deltaX / windowWidth;
    padPositionZ -= mouseSensitivity * deltaY / windowHeight;

    if (padPositionX > 1)
        padPositionX = 1;
    if (padPositionX < 0)
        padPositionX = 0;
    if (padPositionZ > 1)
        padPositionZ = 1;
    if (padPositionZ < 0)
        padPositionZ = 0;

    glfwSetCursorPos(window, windowWidth / 2, windowHeight / 2);
}

//// A few lines to help you if you've never used c++ structs
struct LightSource
{
    glm::vec3 position;
    glm::vec3 color;
};
LightSource lightSources[] =
    {
        {{0, -60, -80}, {1.0, 1.0, 1.0}},
        {{0, -60, -80}, {1.0, 1.0, 1.0}},
        {{0, -60, -80}, {1.0, 1.0, 1.0}},
};

GLuint textureID(PNGImage *image)
{
    GLuint textureID;
    glGenTextures(1, &textureID);
    glBindTexture(GL_TEXTURE_2D, textureID);

    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, image->width, image->height, 0, GL_RGBA, GL_UNSIGNED_BYTE, image->pixels.data());

    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glGenerateMipmap(GL_TEXTURE_2D);

    return textureID;
}

GLuint cubemapID(PNGImage (&images)[6])
{
    GLuint cubemapID;
    glGenTextures(1, &cubemapID);
    glBindTexture(GL_TEXTURE_CUBE_MAP, cubemapID);

    for (int i = 0; i < 6; ++i)
    {
        std::cout << "Loading cubemap texture " << i << ": "
              << "Width = " << images[i].width
              << ", Height = " << images[i].height
              << ", Pixels = " << (images[i].pixels.empty() ? "Empty" : "Loaded") << std::endl;

        glTexImage2D(GL_TEXTURE_CUBE_MAP_POSITIVE_X + i, 0, GL_RGBA, images[i].width, images[i].height, 0, GL_RGBA, GL_UNSIGNED_BYTE, images[i].pixels.data());
    }

    glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_WRAP_R, GL_CLAMP_TO_EDGE);

    return cubemapID;
}

void initGame(GLFWwindow *window, CommandLineOptions gameOptions)
{

    options = gameOptions;

    glfwSetInputMode(window, GLFW_CURSOR, GLFW_CURSOR_HIDDEN);
    glfwSetCursorPosCallback(window, mouseCallback);

    shader = new Gloom::Shader();
    shader->makeBasicShader("../res/shaders/simple.vert", "../res/shaders/simple.frag");

    grassShader = new Gloom::Shader();
    grassShader->makeBasicShader("../res/shaders/grassShader.vert", "../res/shaders/simple.frag");

    skyboxShader = new Gloom::Shader();
    skyboxShader->makeBasicShader("../res/shaders/skybox.vert", "../res/shaders/skybox.frag");

    // Create meshes
    Mesh pad = cube(padDimensions, glm::vec2(30, 40), true);
    Mesh box = cube(boxDimensions, glm::vec2(90), true, true);
    Mesh grass = grassStraw();

    // Mesh text = generateTextGeometryBuffer("testtestest", 39./29., 30*29.);
    // unsigned int textVAO = generateBuffer(text);

    // Create 2D geometry node
    SceneNode *textNode = createTextureNode(textureID(&charmap), shader);

    // Fill buffers
    unsigned int padVAO = generateBuffer(pad);
    unsigned int boxVAO = generateBuffer(box);
    unsigned int grassVAO = generateBuffer(grass);

    // Construct scene
    rootNode = createSceneNode(shader);
    padNode = createSceneNode(shader);
    
    boxNode = createSceneNode(skyboxShader);

    grassNode = createSceneNode(grassShader);

    light1 = createLightNode(0, shader);
    light2 = createLightNode(1, shader);
    movingLightNode = createLightNode(2, shader);

    addChild(rootNode, light1);
    addChild(rootNode, light2);
    addChild(rootNode, boxNode);
    addChild(rootNode, padNode);
    addChild(padNode, grassNode);

    // addChild(rootNode, textNode);

    boxNode->vertexArrayObjectID = boxVAO;
    boxNode->VAOIndexCount = box.indices.size();
    boxNode->nodeType = CUBE_MAP;

    boxNode->textureID = cubemapID(cubemap_images);
    std::cout << "Skybox Texture ID: " << boxNode->textureID << std::endl;

    padNode->vertexArrayObjectID = padVAO;
    padNode->VAOIndexCount = pad.indices.size();

    // # Sett opp gressNode på tilsvarende måte som padNode
    grassNode->vertexArrayObjectID = grassVAO;
    grassNode->VAOIndexCount = grass.indices.size();
    grassNode->nodeType = GRASS;

    // Sett posisjonen til paden
    padNode->position = glm::vec3(0.0f, 0.0f, 0.0f); // Juster posisjonen etter behov

    // Sett posisjonen til gresset
    grassNode->position = glm::vec3(0.0f, 0.0f, 0.0f); // Juster posisjonen etter behov

    // textNode->vertexArrayObjectID = textVAO;
    // textNode->VAOIndexCount       = text.indices.size();

    getTimeDeltaSeconds();

    std::cout << fmt::format("IniticurrentTransformationMatrixalized scene with {} SceneNodes.", totalChildren(rootNode)) << std::endl;

    std::cout << "Skybox VAO: " << boxNode->vertexArrayObjectID << ", Index Count: " << boxNode->VAOIndexCount << std::endl;

    std::cout << "pad VAO: " << padNode->vertexArrayObjectID << ", Index Count: " << padNode->VAOIndexCount << std::endl;
}

void handleKeyboardInput(GLFWwindow *window, double deltaTime)
{
    const float moveSpeed = 2.0;

    if (glfwGetKey(window, GLFW_KEY_W) == GLFW_PRESS)
    {
        padPositionZ -= 7.0 * cos(-yaw) * deltaTime;
        padPositionX -= 7.0 * sin(-yaw) * deltaTime;
    }
    if (glfwGetKey(window, GLFW_KEY_S) == GLFW_PRESS)
    {
        padPositionZ += 7.0 * cos(-yaw) * deltaTime;
        padPositionX += 7.0 * sin(-yaw) * deltaTime;
    }
    if (glfwGetKey(window, GLFW_KEY_A) == GLFW_PRESS)
    {
        padPositionZ -= 7.0 * sin(-yaw) * deltaTime;
        padPositionX -= 7.0 * cos(yaw) * deltaTime;
    }
    if (glfwGetKey(window, GLFW_KEY_D) == GLFW_PRESS)
    {
        padPositionZ += 7.0 * sin(-yaw) * deltaTime;
        padPositionX += 7.0 * cos(yaw) * deltaTime;
    }
    if (glfwGetKey(window, GLFW_KEY_SPACE) == GLFW_PRESS)
    {
        padPositionY += moveSpeed * deltaTime;
    }
    if (glfwGetKey(window, GLFW_KEY_LEFT_SHIFT) == GLFW_PRESS)
    {
        padPositionY -= moveSpeed * deltaTime;
    }
    if (glfwGetKey(window, GLFW_KEY_UP) == GLFW_PRESS)
    {
        pitch -= 1.0 * deltaTime;
    }
    if (glfwGetKey(window, GLFW_KEY_DOWN) == GLFW_PRESS)
    {
        pitch += 1.0 * deltaTime;
    }
    if (glfwGetKey(window, GLFW_KEY_LEFT) == GLFW_PRESS)
    {
        yaw -= 1.0 * deltaTime;
    }
    if (glfwGetKey(window, GLFW_KEY_RIGHT) == GLFW_PRESS)
    {
        yaw += 1.0 * deltaTime;
    }
}

void updateFrame(GLFWwindow *window)
{
    // printf("Pad VAO: %d, Index Count: %d\n", padNode->vertexArrayObjectID, padNode->VAOIndexCount);

    glfwSetInputMode(window, GLFW_CURSOR, GLFW_CURSOR_DISABLED);

    double timeDelta = getTimeDeltaSeconds();

    handleKeyboardInput(window, timeDelta);

    const float cameraWallOffset = 30; // Arbitrary addition to prevent ball from going too much into camera

    glm::mat4 projection = glm::perspective(glm::radians(80.0f), float(windowWidth) / float(windowHeight), 0.1f, 350.f);

    // glm::vec3 cameraPosition = glm::vec3(0, 2, -20);
    glm::vec3 cameraPosition = glm::vec3(padPositionX, padPositionY, padPositionZ);

    // Some math to make the camera move in a nice way
    float lookRotation = -0.6 / (1 + exp(-5 * (padPositionX - 0.5))) + 0.3;
    glm::mat4 cameraTransform =
        // glm::rotate(0.3f + 0.2f * float(-padPositionZ*padPositionZ), glm::vec3(1, 0, 0)) *
        glm::rotate(pitch, glm::vec3(1, 0, 0)) *
        glm::rotate(yaw, glm::vec3(0, 1, 0)) *
        glm::translate(-cameraPosition);

    glm::mat4 VP = projection * cameraTransform;
    glm::mat4 modelMatrix = glm::mat4(1.0f);

    // Move and rotate various SceneNodes
    // boxNode->position = { 0, -10, -80 };

    // padNode->position  = {
    //     boxNode->position.x - (boxDimensions.x/2) + (padDimensions.x/2) + (1 - padPositionX) * (boxDimensions.x - padDimensions.x),
    //     boxNode->position.y - (boxDimensions.y/2) + (padDimensions.y/2),
    //     boxNode->position.z - (boxDimensions.z/2) + (padDimensions.z/2) + (1 - padPositionZ) * (boxDimensions.z - padDimensions.z)
    // };

    glm::mat4 viewMatrix = cameraTransform;

    skyboxShader->activate();
    glUniformMatrix4fv(9, 1, GL_FALSE, glm::value_ptr(viewMatrix));
    glUniform3fv(10, 1, glm::value_ptr(cameraPosition));

    int location = skyboxShader->getUniformFromName("projection");
    glUniformMatrix4fv(location, 1, GL_FALSE, glm::value_ptr(projection));
  
    // glm::mat4 view = glm::mat4(glm::mat3(cameraTransform));
    // glUniformMatrix4fv(glGetUniformLocation(skyboxShader->get(), "view"), 1, GL_FALSE, glm::value_ptr(view));
    // int viewLocation = skyboxShader->getUniformFromName("view");
    // glUniformMatrix4fv(viewLocation, 1, GL_FALSE, glm::value_ptr(viewMatrix));

    // std::cout << "View Matrix:" << std::endl;
    // for (int i = 0; i < 4; ++i)
    // {
    //     for (int j = 0; j < 4; ++j)
    //     {
    //         std::cout << view[i][j] << " ";
    //     }
    //     std::cout << std::endl;
    // }


    // Create orthographic projection matrix
    glm::mat4 orthoProjection = glm::ortho(0.0f, float(windowWidth), 0.0f, float(windowHeight));
    glUniformMatrix4fv(13, 1, GL_FALSE, glm::value_ptr(orthoProjection));

    updateNodeTransformations(rootNode, VP, modelMatrix);
}

void updateNodeTransformations(SceneNode *node, glm::mat4 transformationThusFar, glm::mat4 modelMatrix)
{

    glm::mat4 transformationMatrix =
        glm::translate(node->position) * glm::translate(node->referencePoint) * glm::rotate(node->rotation.y, glm::vec3(0, 1, 0)) * glm::rotate(node->rotation.x, glm::vec3(1, 0, 0)) * glm::rotate(node->rotation.z, glm::vec3(0, 0, 1)) * glm::scale(node->scale) * glm::translate(-node->referencePoint);

    node->modelMatrix = transformationMatrix * modelMatrix;                           // Model matrix
    node->currentTransformationMatrix = transformationThusFar * transformationMatrix; // MVP

    for (SceneNode *child : node->children)
    {
        updateNodeTransformations(child, node->currentTransformationMatrix, node->modelMatrix);
    }

    // if (node == padNode) {
    //     printf("PadNode Light Positions: %f, %f, %f\n", light1->lightPos.x, light1->lightPos.y, light1->lightPos.z);
    // }

    // if (node->lightID == 1 || node->lightID == 2 || node->lightID == 3) {
    // printf("Light %d Position: %f, %f, %f\n", node->lightID, node->lightPos.x, node->lightPos.y, node->lightPos.z);
    // }
}

void renderNode(SceneNode *node)
{
    // activate shader that matches the object
    node->shader->activate();

    glUniformMatrix4fv(3, 1, GL_FALSE, glm::value_ptr(node->currentTransformationMatrix));
    glUniformMatrix4fv(4, 1, GL_FALSE, glm::value_ptr(node->modelMatrix));
    glm::mat3 normalMatrix = glm::transpose(glm::inverse(glm::mat3(node->modelMatrix)));
    glUniformMatrix3fv(8, 1, GL_FALSE, glm::value_ptr(normalMatrix));

    bool is2D = node->is2D;
    glUniform1i(12, int(is2D));

    bool isNormalMapped = node->nodeType == NORMAL_MAPPED_GEOMETRY;
    glUniform1i(15, int(isNormalMapped));

    bool isGrassStraw = node->nodeType == GRASS;
    glUniform1i(16, int(isGrassStraw));

    switch (node->nodeType)
    {
    case GEOMETRY:
        if (node->vertexArrayObjectID != -1)
        {
            glBindVertexArray(node->vertexArrayObjectID);
            glDrawElements(GL_TRIANGLES, node->VAOIndexCount, GL_UNSIGNED_INT, nullptr);
        }
        break;
    case GEOMETRY_2D:
        if (node->textureID != -1)
        {
            glBindVertexArray(node->vertexArrayObjectID);
            glActiveTexture(GL_TEXTURE0);
            glBindTexture(GL_TEXTURE_2D, node->textureID);
            glDrawElements(GL_TRIANGLES, node->VAOIndexCount, GL_UNSIGNED_INT, nullptr);
        }
        break;
    case NORMAL_MAPPED_GEOMETRY:
        if (node->normal_mapped_textureID != -1)
        {
            glBindVertexArray(node->vertexArrayObjectID);
            glActiveTexture(GL_TEXTURE0);
            glBindTexture(GL_TEXTURE_2D, node->textureID);
            glActiveTexture(GL_TEXTURE1);
            glBindTexture(GL_TEXTURE_2D, node->normal_mapped_textureID);
            glDrawElements(GL_TRIANGLES, node->VAOIndexCount, GL_UNSIGNED_INT, nullptr);
        }
        break;
    case POINT_LIGHT:
        break;
    case SPOT_LIGHT:
        break;

    case GRASS:
        if (node->vertexArrayObjectID != -1)
        {
            glBindVertexArray(node->vertexArrayObjectID);
            // Sett padens posisjon som uniform
            glUniform3fv(14, 1, glm::value_ptr(padNode->position));
            glUniform3fv(17, 1, glm::value_ptr(padDimensions));
            int numInstancesX = int(padDimensions.x / 0.02);
            int numInstancesZ = int(padDimensions.z / 0.02);
            glDrawArraysInstanced(GL_TRIANGLES, 0, node->VAOIndexCount, numInstancesX * numInstancesZ);
            float currentTime = glfwGetTime(); // Hent gjeldende tid
            glUniform1f(glGetUniformLocation(node->shader->get(), "time"), currentTime);
        }

        break;
        
    case CUBE_MAP:
        if (node->textureID != -1)
        {
            glDepthFunc(GL_LEQUAL);
            glDisable(GL_CULL_FACE);
            glDepthMask(GL_FALSE);
            glBindVertexArray(node->vertexArrayObjectID);
            glActiveTexture(GL_TEXTURE0);
            glBindTexture(GL_TEXTURE_CUBE_MAP, node->textureID);
            glDrawArrays(GL_TRIANGLES, 0, 36);
            glDepthMask(GL_TRUE);
            glDepthFunc(GL_LESS);
        }
        break;
    }

    for (SceneNode *child : node->children)
    {
        renderNode(child);
    }
}

void renderFrame(GLFWwindow *window)
{
    int windowWidth, windowHeight;
    glfwGetWindowSize(window, &windowWidth, &windowHeight);
    glViewport(0, 0, windowWidth, windowHeight);

    renderNode(rootNode);
}
