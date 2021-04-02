
#include <Arduino.h>
#include "SCD40/scd40.h"
#include "LPS22HB/Arduino_LPS22HB.h"
#include "TSL25403/TSL25403.h"
#include "RGB_LED/RGB.h"
#include "Tone/Tone.h"

SCD40 scd40;
TSL25403 light;
RGBLED led;
Tone buzzer;

void setup() {
    Serial0.begin(9600);

    scd40.begin();
    BARO.begin();
    light.begin();
    led.begin(0, 1, 2);
    buzzer.begin(3);
}

void loop() {
    scd40.read();
    char message[32];
    sprintf(message, "CO2: %.0fppm", scd40.co2_value());
    Serial0.println(message);
    sprintf(message, "Temperature: %.3fC", scd40.temp_value());
    Serial0.println(message);
    sprintf(message, "Humidity: %.3f%%", scd40.hum_value());
    Serial0.println(message);
    float pressure = BARO.readPressure();
    sprintf(message, "Pressure: %.5fkPa", pressure);
    Serial0.println(message);
    float lux = light.read_lux();
    sprintf(message, "Light: %.0flx", lux);
    Serial0.println(message);
    float ir_lux = light.read_ir_lux();
    sprintf(message, "IR Light: %.0flx", ir_lux);
    Serial0.println(message);
    
    if (lux < 200) {
        buzzer.play(NOTE_G5);
    }
    led.setHSV(lux/(1023/light.divider), 1.0, 0.1);
    
    delay(200);
    if(buzzer.isPlaying()) buzzer.stop();
    delay(300);
}
