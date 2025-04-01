#pragma once

#include <glm/glm.hpp>
#include <glm/mat4x4.hpp>
#include <glm/gtc/type_ptr.hpp>

#include <stack>
#include <vector>
#include <cstdio>
#include <stdbool.h>
#include <cstdlib> 
#include <ctime> 
#include <chrono>
#include <fstream>

#include <utilities/shader.hpp>

enum SceneNodeType {
	GEOMETRY, POINT_LIGHT, SPOT_LIGHT, GEOMETRY_2D, NORMAL_MAPPED_GEOMETRY, GRASS, CUBE_MAP, POND
};

struct SceneNode {
	SceneNode(Gloom::Shader* shader) {
		position = glm::vec3(0, 0, 0);
		rotation = glm::vec3(0, 0, 0);
		scale = glm::vec3(1, 1, 1);

        referencePoint = glm::vec3(0, 0, 0);
        vertexArrayObjectID = -1;
        VAOIndexCount = 0;

        nodeType = GEOMETRY;
		lightID = -1;

		modelMatrix = glm::mat4(1.0f);
		lightPos = glm::vec4(0, 0, 0, 1.0);

		textureID = -1;
		normal_mapped_textureID = -1;

		is2D = 0;

		this->shader = shader;
	}

	// A list of all children that belong to this node.
	// For instance, in case of the scene graph of a human body shown in the assignment text, the "Upper Torso" node would contain the "Left Arm", "Right Arm", "Head" and "Lower Torso" nodes in its list of children.
	std::vector<SceneNode*> children;
	
	// The node's position and rotation relative to its parent
	glm::vec3 position;
	glm::vec3 rotation;
	glm::vec3 scale;

	glm::mat4 modelMatrix; // Model matrix

	// A transformation matrix representing the transformation of the node's location relative to its parent. This matrix is updated every frame.
	glm::mat4 currentTransformationMatrix;

	// The location of the node's reference point
	glm::vec3 referencePoint;

	// The ID of the VAO containing the "appearance" of this SceneNode.
	int vertexArrayObjectID;
	unsigned int VAOIndexCount;

	// Node type is used to determine how to handle the contents of a node
	SceneNodeType nodeType;

	int lightID;

	int textureID;
	std::array<GLuint, 6>  cubemap_ids; 
	int normal_mapped_textureID;

	int is2D;

	glm::vec4 lightPos;

	Gloom::Shader* shader;
};

SceneNode* createSceneNode(Gloom::Shader* shader);
void addChild(SceneNode* parent, SceneNode* child);
void printNode(SceneNode* node);
int totalChildren(SceneNode* parent);
SceneNode* createLightNode(int lightID, Gloom::Shader* shader);
SceneNode* createTextureNode(int textureID, Gloom::Shader* shader);
SceneNode* createGrassNode();

// For more details, see SceneGraph.cpp.