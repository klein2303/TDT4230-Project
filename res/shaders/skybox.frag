#version 430 core

out vec4 FragColor;
out vec4 color;

in vec3 TexCoords;

uniform samplerCube skybox;

void main(){    
    FragColor = texture(skybox, TexCoords);
}