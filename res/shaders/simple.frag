#version 430 core

in layout(location = 0) vec3 normal;
in layout(location = 1) vec2 textureCoordinates;

layout(binding = 0) uniform sampler2D diffuseMap;
layout(binding = 1) uniform sampler2D normalMap;

uniform layout(location = 5) vec4 light1;
uniform layout(location = 6) vec4 light2;
uniform layout(location = 7) vec4 movingLight;

uniform layout(location = 9) mat4 viewMatrix;
uniform layout(location = 10) vec3 cameraPosition;

uniform layout(location = 12) int is2D;

uniform layout(location = 15) int isNormal;

uniform layout (location = 16) int isGrassStraw;

uniform float ballRadius;

in layout(location = 2) vec3 fragPosition;

in layout(location = 3) mat3 TBN;

in layout(location = 11) float grassHeight;

float rand(vec2 co) { return fract(sin(dot(co.xy, vec2(12.9898,78.233))) * 43758.5453); }
float dither(vec2 uv) { return (rand(uv)*2.0-1.0) / 256.0; }

vec3 reject(vec3 from, vec3 onto) {
return from - onto*dot(from, onto)/dot(onto, onto);
}

out vec4 color;

struct LightSource {
    vec3 position;
    vec3 color;
};

uniform LightSource lightSources[3];

void main()
{
    vec3 normalizedNormal = normalize(normal).rgb;
    vec4 diffuseColor = vec4(1, 1, 1, 1);


    if(is2D == 1){
        color = texture(diffuseMap, textureCoordinates);
        return;
    }

    if(isNormal == 1){
        diffuseColor = texture(diffuseMap, textureCoordinates);
        vec3 normal = TBN* (texture(normalMap, textureCoordinates).rgb * 2.0 - 1.0);
        normalizedNormal = normalize(normal);

    }

    if(isGrassStraw == 1){
        float greeness = clamp(grassHeight, 0.0, 1.0); // Clamp the height to [0, 1]
        vec4 green = vec4(0.0, 1.0, 0.0, 1.0);
        color = green * greeness;
        return;
    }

    vec3 ambient = vec3(0.1, 0.1, 0.1);

    float shininess = 32.0; // Higher values = shinier surface

    float la = 1;
    float lb = 0.01;
    float lc = 0.001;

    // eye vector (camera to fragment)
    vec3 eyeVector = normalize(cameraPosition - fragPosition);


    vec3 diffuse = vec3(0.0);
    vec3 specular = vec3(0.0);

    // Hard shadow radius
    float hardShadowRadius = ballRadius;  

    // Soft shadow radius 
    float softShadowRadius = ballRadius * 1.5;

    for (int i = 0; i < 3; i++) {
        vec3 lightDir = normalize(lightSources[i].position - fragPosition);
        
        float d = length(lightSources[i].position - fragPosition); //lightDir length

        // bool inShadow = false; for task 3

        vec3 rejection = reject(fragPosition, lightDir);
        float shadowFactor = 1.0; // 1.0 = full light, 0.0 = fully shadoiwed
        
        if (dot(lightSources[i].position - fragPosition, fragPosition) > 0 &&
            length(rejection) < softShadowRadius ) {

            if (length(rejection) < hardShadowRadius) {
                shadowFactor = 0.0; // Fully shadowed
            } else {
                // Linear interpolation between hard and soft ahadow
                float t = (length(rejection) - hardShadowRadius) / (softShadowRadius - hardShadowRadius);
                shadowFactor = mix(0.0, 1.0, t); // does the linear interpolation
            }
        }

        if (shadowFactor > 0.0) {
            float attenuation = 1.0 / (la + lb * d + lc * d * d);
            float diffIntensity = max(dot(normalizedNormal, lightDir), 0.0);
            diffuse += attenuation * diffIntensity * lightSources[i].color * shadowFactor;
            
            vec3 reflectionVector = normalize(reflect(-lightDir, normalizedNormal));
            float specIntensity = pow(max(dot(reflectionVector, eyeVector), 0.0), shininess);
            specular += attenuation * specIntensity * lightSources[i].color * shadowFactor;
        }

    }
    float dither = dither(textureCoordinates);

    // Combine ambient, diffuse and specular 
    // color = vec4(ambient + diffuse + specular, 1.0) * diffuseColor + dither;
    color = vec4(0.0, 0.2, 0.0, 1.0); 


}
