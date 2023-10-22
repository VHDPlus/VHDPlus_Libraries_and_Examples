
#include <Arduino.h>
#include "lib/W5500/Ethernet.h"

// Enter a MAC address and IP address for your controller below.
// The IP address will be dependent on your local network:
byte mac[] = {
    0xDE, 0xAD, 0xBE, 0xEF, 0xFE, 0xED
};
IPAddress ip(169, 254, 200, 187);

// Initialize the Ethernet server library
// with the IP address and port you want to use
// (port 80 is default for HTTP):
EthernetServer server(80);

int i = 0;

void setup() {
    // You can use Ethernet.init(pin) to configure the CS pin
    Ethernet.init(0);

    // Open serial communications and wait for port to open:
    Serial0.begin(115200);
    
    Serial0.println("Start");

    // start the Ethernet connection and the server:
    Ethernet.begin(mac, ip);

    // Check for Ethernet hardware present
    while (Ethernet.hardwareStatus() == EthernetNoHardware) {
        delay(1000);
    }
    
    Serial0.println("Hardware Detected");

    // Check for Ethernet link status
    if (Ethernet.linkStatus() == LinkOFF) {
        Serial0.println("Ethernet cable is not connected.");
    }
    
    Serial0.println("Connected");

    // start the server
    server.begin();
    Serial0.print("server is at ");
    Serial0.println(Ethernet.localIP());
}


void loop() {
    // listen for incoming clients
    EthernetClient client = server.available();
    if (client) {
        Serial0.println("new client");
        // an HTTP request ends with a blank line
        bool currentLineIsBlank = true;
        while (client.connected()) {
            if (client.available()) {
                char c = client.read();
                Serial0.write(c);
                
                // if you've gotten to the end of the line (received a newline
                // character) and the line is blank, the HTTP request has ended,
                // so you can send a reply
                if (c == '\n' && currentLineIsBlank) {
                    i ++;
                    
                    // send a standard HTTP response header
                    client.println("HTTP/1.1 200 OK");
                    client.println("Content-Type: text/html");
                    client.println("Connection: close");  // the connection will be closed after completion of the response
                    client.println("Refresh: 5");  // refresh the page automatically every 5 sec
                    client.println();
                    client.println("<!DOCTYPE HTML>");
                    client.println("<html>");
                    // output the value of each analog input pin
                    client.print("Update: ");
                    client.print(i);
                    client.println("<br />");
                    client.println("</html>");
                    break;
                }
                if (c == '\n') {
                    // you're starting a new line
                    currentLineIsBlank = true;
                } else if (c != '\r') {
                    // you've gotten a character on the current line
                    currentLineIsBlank = false;
                }
            }
        }
        // give the web browser time to receive the data
        delay(1);
        // close the connection:
        client.stop();
        Serial0.println("client disconnected");
    }
}
