
#include <Arduino.h>
#include "SCD40/scd40.h"
#include "LPS22HB/Arduino_LPS22HB.h"
#include "TSL25403/TSL25403.h"

SCD40 scd40;
TSL25403 light;

void setup() {
    Serial0.begin(9600);
    
    Serial0.println("Start");
    
    scd40.begin();
    BARO.begin();
    light.begin();
}

void loop() {
    scd40.read();
    char message[32];
    sprintf(message, "CO2: %.2fppm", scd40.co2_value());
    Serial0.println(message);
    sprintf(message, "Temperature: %.2fC", scd40.temp_value());
    Serial0.println(message);
    sprintf(message, "Humidity: %.2f%%", scd40.hum_value());
    Serial0.println(message);
    //sprintf(message, "Pressure: %.2fPa", BARO.readPressure());
    //Serial0.println(message);
    light.read();
    sprintf(message, "Light: %.2flx", light.lux_value());
    Serial0.println(message);
    sprintf(message, "IR Light: %.2flx", light.ir_lux_value());
    Serial0.println(message);
    delay(5000);
}
