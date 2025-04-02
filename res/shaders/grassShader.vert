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
out layout(location = 21) vec2 textureAnimation;
out layout(location = 22) float shadowFactor_out;

float hash(vec3 p) {
    p = fract(p * 0.1031);
    p += dot(p, p.yzx + 31.32);
    return fract((p.x + p.y) * p.z);
}


void main()
{
    int numInstancesX = int(padDimensions.x / 0.02); // Number of instances along the x-axis
    int numInstancesZ = int(padDimensions.z / 0.02); // Number of instances along the z-axis
    float spacingX = padDimensions.x / numInstancesX;
    float spacingZ = padDimensions.z / numInstancesZ;
    
    vec3 instanceOffset = vec3(float(gl_InstanceID % numInstancesX) * spacingX , 0.0, float(gl_InstanceID / numInstancesX) * spacingZ );

    // place grass straw more randomly
    instanceOffset.x += hash(instanceOffset);
    instanceOffset.z += hash(instanceOffset);

    // Scale the height of the grass straw
    float heightScale = 1.0 + hash(instanceOffset) * 0.5; // Scale factor between 0.5 and 1.0
    vec3 scaledPosition = position; // Start with the original position
    scaledPosition.y *= heightScale; // Scale the height (y-axis)

    // Simuler vind med sinus og cosinus
    float windX = sin(time * 0.03 + instanceOffset.x * 0.5) * 0.9; // Vind i x-retning

    instanceOffset.x += windX; // Legg til vindforskyvning i x-retningen
    
    // float windStrength = 5.0; // Juster styrken på vinden
    // float wind = perlinNoise(vec3(instanceOffset.x *0.3 , instanceOffset.z * 0.3, scaledTime)) * windStrength;
    // wind -= windStrength * 0.5; 
    // instanceOffset.x += wind; // Legg til forskyvning i x-retningen
    // instanceOffset.z += wind * 0.05; // Legg til forskyvning i z-retningen

    float bendFactor = sin(time * 0.8) * 0.5 + 0.5; // Sinuskurve forskjøvet til [0, 1]
    // First 0,5 scales the sine wave to [0.5, 0.5]
    // Second 0.5 shifts the sine wave to [0, 1] by adding 0.5

    bendFactor *= 0.3; // defines how much the grass bends

    vec3 bendDirection = vec3(-1.0, 0.0, 0.0);
    vec3 bentPosition = scaledPosition + bendDirection * bendFactor * scaledPosition.y; // Bøy basert på høyde (y)

    // Add the offset to the position and adjust for the pad's position
    vec4 worldPosition = modelMatrix * vec4(bentPosition + instanceOffset + padPosition - vec3(padDimensions.x / 2.0, 0.0, padDimensions.z / 2.0), 1.0);
    fragPosition = worldPosition.xyz;
    normal_out = normalMatrix * normal_in;
    textureCoordinates_out = textureCoordinates_in;

    height = position.y * heightScale;

    time_out = time;
    //wind_out = wind;


    // peder: prøv å beregne skygge i fragment shader :)
    // vec3 shadowPosition = vec3(instanceOffset.x + time * (windStrength*0.4), instanceOffset.z, position.y * 0.3); // Skyggens globale posisjon
    // float shadowFactor = perlinNoise(shadowPosition *0.1); // Perlin noise brukes for å lage et organisk mønster. Bruker shadowposition for å beregne mønsteret. Time får det til å bevege seg. 
    // //Det siste tallet bestemmer størrelsen. Lavere = større mønster. Høyere = mindre, mer detaljert mønster.
    // // shadowFactor += perlinNoise(shadowPosition *0.1); // Legger til et annet lag av Perlin noise for mer kompleksitet
    
    // shadowFactor = 1.0 - shadowFactor;

    // // shadowFactor = clamp(shadowFactor, 0.0, 1.0); // Sørg for at verdiene er i området [0, 1]
    // shadowFactor = smoothstep(0.2, 0.7, shadowFactor); // Brukes for å lage en myk overgang mellom lys og skygge
    // // shadowFactor = pow(shadowFactor, 2.0); // forsterker lave verdier
    // // shadowFactor = smoothstep(0.2, 0.6, pow(shadowFactor, 1.5));

    // shadowFactor_out = shadowFactor; // skyggens stryke, går fra 0 til 1 (0 = full skygge, 1 = full lys)


    gl_Position = MVP * worldPosition;
}