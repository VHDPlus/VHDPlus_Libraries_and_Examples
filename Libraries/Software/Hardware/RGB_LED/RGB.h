#ifndef _RGB_h
#define _RGB_h

#include <Arduino.h>

class RGBLED
{
public:
    void begin(uint8_t R_Pin, uint8_t G_Pin, uint8_t B_Pin);
    float* rgb2hsv(float r, float g, float b, float* hsv);
    float* hsv2rgb(float h, float s, float b, float* rgb);
    void setRGB(float r, float g, float b);
    void setHSV(float h, float s, float b);
    
private:
    uint8_t _r_pin, _g_pin, _b_pin;
    float fract(float x);
    float mix(float a, float b, float t);
    float step(float e, float x);
    
};

#endif
