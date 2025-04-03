#version 430 core

in layout(location = 0) vec3 position;
in layout(location = 1) vec3 normal_in;
in layout(location = 2) vec2 textureCoordinates_in;

uniform layout(location = 3) mat4 MVP;
uniform layout(location = 4) mat4 modelMatrix;
uniform layout(location = 8) mat3 normalMatrix;
uniform layout(location = 9) mat4 viewMatrix;
uniform layout(location = 14) vec3 padPosition;
uniform layout(location = 15) int isNormal;
uniform layout (location = 16) int isGrassStraw;
uniform layout(location = 17) vec3 padDimensions; 

uniform float time;

out layout(location = 0) vec3 normal_out;
out layout(location = 1) vec2 textureCoordinates_out;
out layout(location = 2) vec3 fragPosition;
out layout(location = 11) float height;

float hash(vec3 p) {
    p = fract(p * 0.1031);
    p += dot(p, p.yzx + 31.32);
    return fract((p.x + p.y) * p.z);
}

//	Classic Perlin 3D Noise 
//	by Stefan Gustavson (https://github.com/stegu/webgl-noise)
//
vec4 permute(vec4 x){return mod(((x*34.0)+1.0)*x, 289.0);}
vec4 taylorInvSqrt(vec4 r){return 1.79284291400159 - 0.85373472095314 * r;}
vec3 fade(vec3 t) {return t*t*t*(t*(t*6.0-15.0)+10.0);}

float cnoise(vec3 P){
  vec3 Pi0 = floor(P); // Integer part for indexing
  vec3 Pi1 = Pi0 + vec3(1.0); // Integer part + 1
  Pi0 = mod(Pi0, 289.0);
  Pi1 = mod(Pi1, 289.0);
  vec3 Pf0 = fract(P); // Fractional part for interpolation
  vec3 Pf1 = Pf0 - vec3(1.0); // Fractional part - 1.0
  vec4 ix = vec4(Pi0.x, Pi1.x, Pi0.x, Pi1.x);
  vec4 iy = vec4(Pi0.yy, Pi1.yy);
  vec4 iz0 = Pi0.zzzz;
  vec4 iz1 = Pi1.zzzz;

  vec4 ixy = permute(permute(ix) + iy);
  vec4 ixy0 = permute(ixy + iz0);
  vec4 ixy1 = permute(ixy + iz1);

  vec4 gx0 = ixy0 / 7.0;
  vec4 gy0 = fract(floor(gx0) / 7.0) - 0.5;
  gx0 = fract(gx0);
  vec4 gz0 = vec4(0.5) - abs(gx0) - abs(gy0);
  vec4 sz0 = step(gz0, vec4(0.0));
  gx0 -= sz0 * (step(0.0, gx0) - 0.5);
  gy0 -= sz0 * (step(0.0, gy0) - 0.5);

  vec4 gx1 = ixy1 / 7.0;
  vec4 gy1 = fract(floor(gx1) / 7.0) - 0.5;
  gx1 = fract(gx1);
  vec4 gz1 = vec4(0.5) - abs(gx1) - abs(gy1);
  vec4 sz1 = step(gz1, vec4(0.0));
  gx1 -= sz1 * (step(0.0, gx1) - 0.5);
  gy1 -= sz1 * (step(0.0, gy1) - 0.5);

  vec3 g000 = vec3(gx0.x,gy0.x,gz0.x);
  vec3 g100 = vec3(gx0.y,gy0.y,gz0.y);
  vec3 g010 = vec3(gx0.z,gy0.z,gz0.z);
  vec3 g110 = vec3(gx0.w,gy0.w,gz0.w);
  vec3 g001 = vec3(gx1.x,gy1.x,gz1.x);
  vec3 g101 = vec3(gx1.y,gy1.y,gz1.y);
  vec3 g011 = vec3(gx1.z,gy1.z,gz1.z);
  vec3 g111 = vec3(gx1.w,gy1.w,gz1.w);

  vec4 norm0 = taylorInvSqrt(vec4(dot(g000, g000), dot(g010, g010), dot(g100, g100), dot(g110, g110)));
  g000 *= norm0.x;
  g010 *= norm0.y;
  g100 *= norm0.z;
  g110 *= norm0.w;
  vec4 norm1 = taylorInvSqrt(vec4(dot(g001, g001), dot(g011, g011), dot(g101, g101), dot(g111, g111)));
  g001 *= norm1.x;
  g011 *= norm1.y;
  g101 *= norm1.z;
  g111 *= norm1.w;

  float n000 = dot(g000, Pf0);
  float n100 = dot(g100, vec3(Pf1.x, Pf0.yz));
  float n010 = dot(g010, vec3(Pf0.x, Pf1.y, Pf0.z));
  float n110 = dot(g110, vec3(Pf1.xy, Pf0.z));
  float n001 = dot(g001, vec3(Pf0.xy, Pf1.z));
  float n101 = dot(g101, vec3(Pf1.x, Pf0.y, Pf1.z));
  float n011 = dot(g011, vec3(Pf0.x, Pf1.yz));
  float n111 = dot(g111, Pf1);

  vec3 fade_xyz = fade(Pf0);
  vec4 n_z = mix(vec4(n000, n100, n010, n110), vec4(n001, n101, n011, n111), fade_xyz.z);
  vec2 n_yz = mix(n_z.xy, n_z.zw, fade_xyz.y);
  float n_xyz = mix(n_yz.x, n_yz.y, fade_xyz.x); 
  return 2.2 * n_xyz;
}
// End of Perlin noise code


void main()
{
    int numInstancesX = int(padDimensions.x / 0.02); 
    int numInstancesZ = int(padDimensions.z / 0.02); 
    float spacingX = padDimensions.x / numInstancesX;
    float spacingZ = padDimensions.z / numInstancesZ;
    
    vec3 instanceOffset = vec3(float(gl_InstanceID % numInstancesX) * spacingX , 0.0, float(gl_InstanceID / numInstancesX) * spacingZ);

    // place grass straw randomly
    instanceOffset.x += cnoise(instanceOffset + vec3(float(gl_InstanceID) * 0.1, 0.0, 0.0)) * 0.1;
    instanceOffset.z += cnoise(instanceOffset + vec3(0.0, 0.0, float(gl_InstanceID) * 0.1)) * 0.1;

    // combine with more noise for more randomness
    float randomX = cnoise(instanceOffset + vec3(1.0, 0.0, 0.0)) * 0.1 +
                    cnoise(instanceOffset + vec3(2.0, 0.0, 0.0)) * 0.05;
    float randomZ = cnoise(instanceOffset + vec3(0.0, 0.0, 1.0)) * 0.1 +
                    cnoise(instanceOffset + vec3(0.0, 0.0, 2.0)) * 0.05;

    instanceOffset.x += randomX;
    instanceOffset.z += randomZ;

    // Scale the height of the grass straw
    float heightScale = 1.0 + hash(instanceOffset) * 0.5; // Scale factor between 0.5 and 1.0
    vec3 scaledPosition = position; 
    scaledPosition.y *= heightScale; // Scale the height (y-axis)

    // Generate random rotation
    float randomRotation = hash(instanceOffset) * 360.0; // rotation angle in degrees
    float rotationRadians = radians(randomRotation); // Change to radians
    mat3 rotationMatrix = mat3(
        cos(rotationRadians), 0.0, sin(rotationRadians),
        0.0,                 1.0, 0.0,
        -sin(rotationRadians), 0.0, cos(rotationRadians)
    );

    // Apply rotation
    vec3 rotatedPosition = rotationMatrix * scaledPosition;

    // Simulate wind with a sine wave
    // First 0,5 scales the sine wave to [0.5, 0.5]
    // Second 0.5 shifts the sine wave to [0, 1] by adding 0.5
    float bendFactor = sin(time * 0.8) * 0.5 + 0.5; 

    bendFactor *= 0.3; // how much the grass should bend
    
    vec3 windDirection = vec3(-1.0, 0.0, 0.0);
    vec3 bentPosition = rotatedPosition + windDirection * bendFactor * scaledPosition.y; // bending  based on y-positon

    // Add the offset to the position and adjust for the pad's position
    vec4 worldPosition = modelMatrix * vec4(bentPosition + instanceOffset + padPosition - vec3(padDimensions.x / 2.0, 0.0, padDimensions.z / 2.0), 1.0);
    
    
    fragPosition = worldPosition.xyz;
    normal_out = normalMatrix * normal_in;
    textureCoordinates_out = textureCoordinates_in;
    height = position.y * heightScale;

    gl_Position = MVP * worldPosition;
}