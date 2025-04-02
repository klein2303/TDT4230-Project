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
in layout(location = 18) float time;
in layout(location = 19) float wind;
in layout(location = 20) float noiseValue;
in layout(location = 21) vec2 textureAnimation;
// in layout(location = 22) float shadowFactorGrass; 

out vec4 color;

float windStrength = 5.0;

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

    if(isGrassStraw == 1){
        vec3 green = vec3(0.0, 0.5, 0.0);
        green = green * (grassHeight*0.3 + 0.5);

        vec3 shadowPosition = vec3(fragPosition.x + time * (windStrength * 0.5), fragPosition.z, fragPosition.y * 0.3); // Skyggens globale posisjon
        float shadowFactorGrass = perlinNoise(shadowPosition *0.05); // Perlin noise brukes for å lage et organisk mønster. Bruker shadowposition for å beregne mønsteret. Time får det til å bevege seg. 
        //Det siste tallet bestemmer størrelsen. Lavere = større mønster. Høyere = mindre, mer detaljert mønster.
        // shadowFactor += perlinNoise(shadowPosition *0.1); // Legger til et annet lag av Perlin noise for mer kompleksitet
    
        shadowFactorGrass = 1.0 - shadowFactorGrass;

        // shadowFactor = clamp(shadowFactor, 0.0, 1.0); // Sørg for at verdiene er i området [0, 1]
        shadowFactorGrass = smoothstep(0.2, 0.7, shadowFactorGrass);
        
        vec3 shadow = green * 0.5; // skyggen er 5% av grønnfargen. Lavere = mørkere skygge

        vec3 mixColour = mix(shadow, green, shadowFactorGrass);

        // Når shadowFactorGrass = 0.0, brukes kun shadow (full skygge).
        // Når shadowFactorGrass = 1.0, brukes kun green (ingen skygge).
        // Når shadowFactorGrass er mellom 0.0 og 1.0, blir resultatet en blanding av shadow og green.

        //color = green * shadowFactorGrass;

        // float normalizedTime = mod(time, 10.0) / 10.0; // Normaliser `time` til området [0, 1]
        // float normalizedWind = wind * 0.5 + 0.5; // Normaliser `wind` til området [0, 1]
        // color = vec4(vec3(normalizedWind), 1.0);
        // //color = vec4(normalizedTime, normalizedWind, 0.0, 1.0); // Bruk rød for `time` og grønn for `wind`

        // // float normalizedNoise = noiseValue * 0.5 + 0.5; // Normaliser til området [0, 1]
        // // color = vec4(vec3(normalizedNoise), 1.0); // Visualiser støyen som en gråtone
        
        // // float normalizedX = fract(instanceOffsetX * 0.1); // Juster skalaen etter behov
        // // float normalizedZ = fract(instanceOffsetZ * 0.1); // Juster skalaen etter behov

        // // color = vec4(normalizedX, normalizedZ, 0.0, 1.0); // Rød = X, Grønn = Z
        float normalizedHeight = clamp(grassHeight, 0.0, 2.0);
        float alpha = mix(0.2, 1.0, normalizedHeight); // Alpha går fra 0.0 (bunn) til 1.0 (topp)
        
        color.rgb = mixColour;
        color.a = 1.0;
        return;
    }

    // Combine ambient, diffuse and specular 
    // color = vec4(ambient + diffuse + specular, 1.0) * diffuseColor + dither;
    // color = vec4(0.08, 0.05, 0.03, 1.0); // brown
    color = vec4(0.0, 0.2, 0.0, 1.0); // green


}
