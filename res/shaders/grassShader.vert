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

uniform float time;

out layout(location = 0) vec3 normal_out;
out layout(location = 1) vec2 textureCoordinates_out;
out layout(location = 2) vec3 fragPosition;
out layout(location = 11) float height;
out layout(location = 18) float time_out;
out layout(location = 19) float wind_out;
out layout(location = 20) float noiseValue;
out layout(location = 21) float instanceOffsetX;
out layout(location = 22) float instanceOffsetZ;

float hash(vec3 p) {
    p = fract(p * 0.1031);
    p += dot(p, p.yzx + 31.32);
    return fract((p.x + p.y) * p.z);
}

float fade(float t) {
    return t * t * t * (t * (t * 6.0 - 15.0) + 10.0);
}

float grad(int hash, float x, float y, float z) {
    int h = hash & 15;
    float u = h < 8 ? x : y;
    float v = h < 4 ? y : h == 12 || h == 14 ? x : z;
    return ((h & 1) == 0 ? u : -u) + ((h & 2) == 0 ? v : -v);
}

float perlinNoise(vec3 p) {
    vec3 Pi = floor(p);
    vec3 Pf = fract(p);

    vec3 fadePf = vec3(fade(Pf.x), fade(Pf.y), fade(Pf.z));

    int A = int(Pi.x) + int(Pi.y) * 57 + int(Pi.z) * 113;
    int AA = A + 1;
    int AB = A + 57;
    int BA = A + 113;
    int BB = A + 170;

    float res = mix(
        mix(
            mix(grad(A, Pf.x, Pf.y, Pf.z), grad(AA, Pf.x - 1.0, Pf.y, Pf.z), fadePf.x),
            mix(grad(AB, Pf.x, Pf.y - 1.0, Pf.z), grad(AA + 57, Pf.x - 1.0, Pf.y - 1.0, Pf.z), fadePf.x),
            fadePf.y
        ),
        mix(
            mix(grad(BA, Pf.x, Pf.y, Pf.z - 1.0), grad(BB, Pf.x - 1.0, Pf.y, Pf.z - 1.0), fadePf.x),
            mix(grad(AB + 113, Pf.x, Pf.y - 1.0, Pf.z - 1.0), grad(BB + 57, Pf.x - 1.0, Pf.y - 1.0, Pf.z - 1.0), fadePf.x),
            fadePf.y
        ),
        fadePf.z
    );

    return res;
}

void main()
{
    int numInstancesX = int(padDimensions.x / 0.03); // Number of instances along the x-axis
    int numInstancesZ = int(padDimensions.z / 0.03); // Number of instances along the z-axis
    float spacingX = padDimensions.x / numInstancesX;
    float spacingZ = padDimensions.z / numInstancesZ;
    
    vec3 instanceOffset = vec3(float(gl_InstanceID % numInstancesX) * spacingX , 0.0, float(gl_InstanceID / numInstancesX) * spacingZ );

    // place grass straw more randomly
    instanceOffset.x += hash(instanceOffset);
    instanceOffset.y += hash(instanceOffset);
    instanceOffset.z += hash(instanceOffset);

    // Add wind effect with Perlin noise
    float scaledTime = time * 0.01; // Skalerer tiden
    float windStrength = 7.0; // Juster styrken på vinden
    float wind = perlinNoise(vec3(instanceOffset.x, instanceOffset.z, scaledTime)) * windStrength;
    instanceOffset.x += wind; // Legg til forskyvning i x-retningen
    instanceOffset.z += wind * 0.05; // Legg til forskyvning i z-retningen

    // Add the offset to the position and adjust for the pad's position
    vec4 worldPosition = modelMatrix * vec4(position + instanceOffset + padPosition - vec3(padDimensions.x / 2.0, 0.0, padDimensions.z / 2.0), 1.0);
    fragPosition = worldPosition.xyz;
    normal_out = normalMatrix * normal_in;
    textureCoordinates_out = textureCoordinates_in;

    height = position.y;

    time_out = scaledTime;
    wind_out = wind;

    instanceOffsetX = instanceOffset.x;
    instanceOffsetZ = instanceOffset.z; 

    // float noise= perlinNoisePeriodic(vec3(fragPosition.x, fragPosition.z, time), 50.0);
    // noiseValue = noise;

    gl_Position = MVP * worldPosition;
}