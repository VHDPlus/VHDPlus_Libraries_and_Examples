
#include <Arduino.h>
#include "LIS3DH/SparkFunLIS3DH.h"

LIS3DH accel( SPI_MODE, 15 );

void setup() {
    Serial.begin(9600); //Set Baudrate with "New Processor"
    
    accel.begin();
}

void loop() {
    Serial.println("Hello World");
    Serial.println(accel.readFloatAccelX(), 4);
    delay(1000);
}
