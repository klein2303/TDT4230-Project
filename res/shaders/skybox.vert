#version 430 core

in layout(location = 0) vec3 position;


uniform layout(location = 3) mat4 MVP;
uniform layout(location = 4) mat4 modelMatrix;

uniform layout(location = 8) mat3 normalMatrix;

uniform layout(location = 9) mat4 viewMatrix;

uniform layout(location = 19) mat4 projection;
uniform mat4 view;

out vec3 TexCoords;

void main(){
    TexCoords = position;
    gl_Position = projection * vec4(mat3(viewMatrix) * position, 1.0);
}