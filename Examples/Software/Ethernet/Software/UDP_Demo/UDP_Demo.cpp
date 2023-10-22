
#include <Arduino.h>
#include "Libraries/Ethernet/Ethernet.h"
#include "Libraries/Ethernet/EthernetUdp.h"

// Enter a MAC address and IP address for your controller below.
// The IP address will be dependent on your local network:
byte mac[] = {
    0xDE, 0xAD, 0xBE, 0xEF, 0xFE, 0xED
};
IPAddress ip(169, 254, 200, 187);

unsigned int localPort = 8888;      // local port to listen on

// buffers for receiving and sending data
char packetBuffer[UDP_TX_PACKET_MAX_SIZE];  // buffer to hold incoming packet,
char ReplyBuffer[] = "acknowledged";        // a string to send back

// An EthernetUDP instance to let us send and receive packets over UDP
EthernetUDP Udp;

void setup() {
    // You can use Ethernet.init(pin) to configure the CS pin
    Ethernet.init(0);

    // start the Ethernet
    Ethernet.begin(mac, ip);

    // Open serial communications and wait for port to open:
    Serial0.begin(115200);
    while (!Serial0) {
        ; // wait for serial port to connect. Needed for native USB port only
    }

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
    
    Serial0.println("Start");

    // start UDP
    Udp.begin(localPort);
}

void loop() {
    // if there's data available, read a packet
    int packetSize = Udp.parsePacket();
    if (packetSize) {
        Serial0.print("Received packet of size ");
        Serial0.println(packetSize);
        Serial0.print("From ");
        IPAddress remote = Udp.remoteIP();
        for (int i=0; i < 4; i++) {
            Serial0.print(remote[i], DEC);
            if (i < 3) {
                Serial0.print(".");
            }
        }
        Serial0.print(", port ");
        Serial0.println(Udp.remotePort());

        // read the packet into packetBuffer
        Udp.read(packetBuffer, UDP_TX_PACKET_MAX_SIZE);
        Serial0.println("Contents:");
        Serial0.println(packetBuffer);

        // send a reply to the IP address and port that sent us the packet we received
        Udp.beginPacket(Udp.remoteIP(), Udp.remotePort());
        Udp.write(ReplyBuffer);
        Udp.endPacket();
    }
    delay(10);
}
