#version 430 core

in layout(location = 0) vec3 position;
in layout(location = 1) vec3 normal_in;
in layout(location = 2) vec2 textureCoordinates_in;
in layout(location = 3) vec3 tangents;
in layout(location = 4) vec3 bitangents;

uniform layout(location = 3) mat4 MVP;
uniform layout(location = 4) mat4 modelMatrix;

uniform layout(location = 8) mat3 normalMatrix;

uniform layout(location = 9) mat4 viewMatrix;

uniform layout(location = 13) mat4 orthoProjection; 

uniform layout(location = 11) vec3 ballPosition;

uniform layout(location = 12) int is2D;

uniform layout(location = 15) int isNormal;

uniform layout(location = 14) vec3 padPosition;

out layout(location = 0) vec3 normal_out;
out layout(location = 1) vec2 textureCoordinates_out;
out layout(location = 2) vec3 fragPosition;

void main()
{
    vec3 instanceOffset = vec3(float(gl_InstanceID % 10) * 0.3, 0.0, float(gl_InstanceID / 10) * 0.3);

    // Legg til offset til posisjonen og juster for padens posisjon
    vec4 worldPosition = modelMatrix * vec4(position + instanceOffset + padPosition, 1.0);
    fragPosition = worldPosition.xyz;
    normal_out = normalMatrix * normal_in;
    textureCoordinates_out = textureCoordinates_in;

    gl_Position = MVP * worldPosition;
}