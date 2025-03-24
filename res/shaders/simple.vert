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

out layout(location = 0) vec3 normal_out;
out layout(location = 1) vec2 textureCoordinates_out;

out layout(location = 2) vec3 fragPosition;

out layout(location = 3) mat3 TBN;

void main()
{
    

    if(is2D == 1){
        gl_Position = orthoProjection * modelMatrix * vec4(position, 1.0f);
        textureCoordinates_out = textureCoordinates_in;
    }
    else if(isNormal == 1){
        normal_out = normal_in;
        textureCoordinates_out = textureCoordinates_in;
       
        
        vec3 vertexTangent_modelSpace = normalize(mat3(modelMatrix)*tangents);
        vec3 vertexBitangent_modelSpace = normalize(mat3(modelMatrix)*bitangents);
        vec3 vertexNormal_modelSpace = normalize(mat3(modelMatrix)*normal_in);

        TBN = (mat3(vertexTangent_modelSpace, vertexBitangent_modelSpace, normal_in));

        gl_Position = MVP * vec4(position, 1.0f);
        fragPosition = (modelMatrix * vec4(position, 1.0)).xyz; 
    }
    else{
        normal_out = normalize(normalMatrix * normal_in);
        textureCoordinates_out = textureCoordinates_in;
        gl_Position = MVP * vec4(position, 1.0f);

        fragPosition = (modelMatrix * vec4(position, 1.0)).xyz;
    }

    }