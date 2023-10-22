
#include <Arduino.h>
#include "lib/W5500/Ethernet.h"
#include "lib/Modbus/ArduinoRS485.h"
#include "lib/Modbus/ArduinoModbus.h"

// Enter a MAC address for your controller below.
// Newer Ethernet shields have a MAC address printed on a sticker on the shield
// The IP address will be dependent on your local network:
byte mac[] = {
    0xDE, 0xAD, 0xBE, 0xEF, 0xFE, 0xED
};
IPAddress ip(169, 254, 200, 69);

EthernetClient ethClient;
ModbusTCPClient modbusTCPClient(ethClient);

IPAddress server(169, 254, 200, 187); // update with the IP Address of your Modbus server

void setup() {
    // You can use Ethernet.init(pin) to configure the CS pin
    Ethernet.init(0);   // Teensy 2.0
    
    //Initialize Serial0 and wait for port to open:
    Serial0.begin(115200);
    while (!Serial0) {
        ; // wait for Serial0 port to connect. Needed for native USB port only
    }

    // start the Ethernet connection and the server:
    Ethernet.begin(mac, ip);

    // Check for Ethernet hardware present
    if (Ethernet.hardwareStatus() == EthernetNoHardware) {
        Serial0.println("Ethernet shield was not found.  Sorry, can't run without hardware. :(");
        while (true) {
            delay(1); // do nothing, no point running without Ethernet hardware
        }
    }
    if (Ethernet.linkStatus() == LinkOFF) {
        Serial0.println("Ethernet cable is not connected.");
    }
}

void loop() {
    if (!modbusTCPClient.connected()) {
        // client not connected, start the Modbus TCP client
        Serial0.println("Attempting to connect to Modbus TCP server");
        
        if (!modbusTCPClient.begin(server, 502)) {
            Serial0.println("Modbus TCP Client failed to connect!");
        } else {
            Serial0.println("Modbus TCP Client connected");
        }
    } else {
        // client connected

        // write the value of 0x01, to the coil at address 0x00
        if (!modbusTCPClient.coilWrite(0x00, 0x01)) {
            Serial0.print("Failed to write coil! ");
            Serial0.println(modbusTCPClient.lastError());
        }

        // wait for 1 second
        delay(1000);

        // write the value of 0x00, to the coil at address 0x00
        if (!modbusTCPClient.coilWrite(0x00, 0x00)) {
            Serial0.print("Failed to write coil! ");
            Serial0.println(modbusTCPClient.lastError());
        }

        // wait for 1 second
        delay(1000);
    }
}
