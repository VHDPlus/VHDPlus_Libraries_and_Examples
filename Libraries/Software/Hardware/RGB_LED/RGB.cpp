#include <Arduino.h>
#include "RGB.h"

void RGBLED::begin(uint8_t R_Pin, uint8_t G_Pin, uint8_t B_Pin)
{
    _r_pin = R_Pin;
    _g_pin = G_Pin;
    _b_pin = B_Pin;
}

float RGBLED::fract(float x) { return x - int(x); }
float RGBLED::mix(float a, float b, float t) { return a + (b - a) * t; }
float RGBLED::step(float e, float x) { return x < e ? 0.0 : 1.0; }

float* RGBLED::rgb2hsv(float r, float g, float b, float* hsv)
{
    float s = step(b, g);
    float px = mix(b, g, s);
    float py = mix(g, b, s);
    float pz = mix(-1.0, 0.0, s);
    float pw = mix(0.6666666, -0.3333333, s);
    s = step(px, r);
    float qx = mix(px, r, s);
    float qz = mix(pw, pz, s);
    float qw = mix(r, px, s);
    float d = qx - min(qw, py);
    hsv[0] = abs(qz + (qw - py) / (6.0 * d + 1e-10));
    hsv[1] = d / (qx + 1e-10);
    hsv[2] = qx;
    return hsv;
}

float* RGBLED::hsv2rgb(float h, float s, float b, float* rgb)
{
    rgb[0] = b * mix(1.0, constrain(abs(fract(h + 1.0) * 6.0 - 3.0) - 1.0, 0.0, 1.0), s);
    rgb[1] = b * mix(1.0, constrain(abs(fract(h + 0.6666666) * 6.0 - 3.0) - 1.0, 0.0, 1.0), s);
    rgb[2] = b * mix(1.0, constrain(abs(fract(h + 0.3333333) * 6.0 - 3.0) - 1.0, 0.0, 1.0), s);
    return rgb;
}

void RGBLED::setRGB(float r, float g, float b)
{
    analogWrite(_r_pin, (int)((1.0 - r) * 255));
    analogWrite(_g_pin, (int)((1.0 - g) * 255));
    analogWrite(_b_pin, (int)((1.0 - b) * 255));
}

void RGBLED::setHSV(float h, float s, float b)
{
    float rgb[3];
    hsv2rgb(h, s, b, rgb);
    setRGB(rgb[0], rgb[1], rgb[2]);
}