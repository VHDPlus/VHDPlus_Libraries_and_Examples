
#include <Arduino.h>
#include "LIS3DH/SparkFunLIS3DH.h"

LIS3DH accel( SPI_MODE, 15 );

void setup() {
    Serial0.begin(9600); //Set Baudrate with "New Processor"
    
    accel.begin();
}

char message[32];
void loop() {
    sprintf(message, "X: %.5f", accel.readFloatAccelX());
    Serial0.println(message);
    sprintf(message, "Y: %.5f", accel.readFloatAccelY());
    Serial0.println(message);
    sprintf(message, "Z: %.5f", accel.readFloatAccelZ());
    Serial0.println(message);
    delay(100);
}
