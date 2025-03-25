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

uniform layout(location = 12) int is2D;

uniform layout(location = 15) int isNormal;

uniform layout(location = 14) vec3 padPosition;
uniform layout(location = 17) vec3 padDimensions; 


uniform layout (location = 16) int isGrassStraw;

out layout(location = 0) vec3 normal_out;
out layout(location = 1) vec2 textureCoordinates_out;
out layout(location = 2) vec3 fragPosition;
out layout(location = 11) float height;

float hash(vec3 p) {
    p = fract(p * 0.1031);
    p += dot(p, p.yzx + 31.32);
    return fract((p.x + p.y) * p.z);
}

void main()
{
    int numInstancesX = int(padDimensions.x / 0.03); // Number of instances along the x-axis
    int numInstancesZ = int(padDimensions.z / 0.03); // Number of instances along the z-axis
    float spacingX = padDimensions.x / numInstancesX;
    float spacingZ = padDimensions.z / numInstancesZ;
    
    vec3 instanceOffset = vec3(float(gl_InstanceID % numInstancesX) * spacingX , 0.0, float(gl_InstanceID / numInstancesX) * spacingZ );

    instanceOffset.x += hash(instanceOffset);
    instanceOffset.y += hash(instanceOffset);
    instanceOffset.z += hash(instanceOffset);

    // Add the offset to the position and adjust for the pad's position
    vec4 worldPosition = modelMatrix * vec4(position + instanceOffset + padPosition - vec3(padDimensions.x / 2.0, 0.0, padDimensions.z / 2.0), 1.0);
    fragPosition = worldPosition.xyz;
    normal_out = normalMatrix * normal_in;
    textureCoordinates_out = textureCoordinates_in;

    height = position.y;

    gl_Position = MVP * worldPosition;
}