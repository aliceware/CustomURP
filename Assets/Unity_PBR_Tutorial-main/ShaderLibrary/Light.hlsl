#ifndef TUTORIAL_LIGHT_INCLUDED
#define TUTORIAL_LIGHT_INCLUDED

float3 _DirectionalLightColor;
float _LightIntensity;
float3 _DirectionalLightDirection;

struct Light {
    float3 color;
    float3 direction;
};

Light GetDirectionalLight() {
    Light light;
    light.color = _DirectionalLightColor * _LightIntensity;
    light.direction = _DirectionalLightDirection;
    return light;
}

#endif