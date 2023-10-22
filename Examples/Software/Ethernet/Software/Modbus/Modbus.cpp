
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
IPAddress ip(169, 254, 200, 187);

EthernetServer ethServer(502);

ModbusTCPServer modbusTCPServer;

const int ledPin = 1;

void updateLED() {
    // read the current value of the coil
    int coilValue = modbusTCPServer.coilRead(0x00);

    if (coilValue) {
        // coil value set, turn LED on
        digitalWrite(ledPin, HIGH);
    } else {
        // coild value clear, turn LED off
        digitalWrite(ledPin, LOW);
    }
}

void setup() {
    // You can use Ethernet.init(pin) to configure the CS pin
    Ethernet.init(0);   // Teensy 2.0

    // Open Serial0 communications and wait for port to open:
    Serial0.begin(115200);
    Serial0.println("Ethernet Modbus TCP Example");

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

    // start the server
    ethServer.begin();
    
    // start the Modbus TCP server
    if (!modbusTCPServer.begin()) {
        Serial0.println("Failed to start Modbus TCP Server!");
        while (1);
    }

    // configure the LED
    pinMode(ledPin, OUTPUT);
    digitalWrite(ledPin, LOW);

    // configure a single coil at address 0x00
    modbusTCPServer.configureCoils(0x00, 1);
    
    Serial0.println("Start");
}

void loop() {
    // listen for incoming clients
    EthernetClient client = ethServer.available();
    
    if (client) {
        // a new client connected
        Serial0.println("new client");

        // let the Modbus TCP accept the connection
        modbusTCPServer.accept(client);

        while (client.connected()) {
            // poll for Modbus TCP requests, while client connected
            modbusTCPServer.poll();

            // update the LED
            updateLED();
        }

        Serial0.println("client disconnected");
    }
}
