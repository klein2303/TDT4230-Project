#version 430 core

in layout(location = 0) vec3 position;
in layout(location = 1) vec3 normal_in;
in layout(location = 2) vec2 textureCoordinates_in;

uniform layout(location = 3) mat4 MVP;
uniform layout(location = 4) mat4 modelMatrix;
uniform layout(location = 8) mat3 normalMatrix;
uniform layout(location = 9) mat4 viewMatrix;

out layout(location = 0) vec3 normal_out;
out layout(location = 1) vec2 textureCoordinates_out;
out layout(location = 2) vec3 fragPosition;


void main()
{
    normal_out = normalize(normalMatrix * normal_in);
    textureCoordinates_out = textureCoordinates_in;
    gl_Position = MVP * vec4(position, 1.0f);

    fragPosition = (modelMatrix * vec4(position, 1.0)).xyz;

}