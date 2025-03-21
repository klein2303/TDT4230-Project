#include "sceneGraph.hpp"
#include <iostream>
#include <utilities/shader.hpp>

SceneNode* createSceneNode(Gloom::Shader* shader) {
	return new SceneNode(shader);
}

// Add a child node to its parent's list of children
void addChild(SceneNode* parent, SceneNode* child) {
	parent->children.push_back(child);
}

int totalChildren(SceneNode* parent) {
	int count = parent->children.size();
	for (SceneNode* child : parent->children) {
		count += totalChildren(child);
	}
	return count;
}

// Pretty prints the current values of a SceneNode instance to stdout
void printNode(SceneNode* node) {
	printf(
		"SceneNode {\n"
		"    Child count: %i\n"
		"    Rotation: (%f, %f, %f)\n"
		"    Location: (%f, %f, %f)\n"
		"    Reference point: (%f, %f, %f)\n"
		"    VAO ID: %i\n"
		"    LightID: %i\n"
		"}\n",
		int(node->children.size()),
		node->rotation.x, node->rotation.y, node->rotation.z,
		node->position.x, node->position.y, node->position.z,
		node->referencePoint.x, node->referencePoint.y, node->referencePoint.z, 
		node->vertexArrayObjectID,
		node->lightID);
}

SceneNode* createLightNode(int lightID, Gloom::Shader* shader) {
    SceneNode* node = createSceneNode(shader);
    node->nodeType = POINT_LIGHT; // Sett nodetype til POINT_LIGHT
    node->lightID = lightID; // Sett lys-ID
    return node;
}

SceneNode* createTextureNode(int textureID, Gloom::Shader* shader) {
	SceneNode* node = createSceneNode(shader);
	node->nodeType = GEOMETRY_2D; // Sett nodetype til GEOMETRY_2D
	node->textureID = textureID; // Sett tekstur-ID
	node->is2D = 1; // Sett is2D til 1
	return node;
}

// # Lag createGrassNode
// SceneNode* createGrassNode() {
// 	SceneNode* node = createSceneNode();
// 	node->nodeType = GRASS; // Sett nodetype til GRASS
// 	return node;
// };
