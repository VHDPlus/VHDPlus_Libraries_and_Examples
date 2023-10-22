
#include <Arduino.h>
#include "lib/W5500/Ethernet.h"
#include "lib/Profinet/Profinet.h"

// Enter a MAC address for your controller below.
// Newer Ethernet shields have a MAC address printed on a sticker on the shield
// The IP address will be dependent on your local network:
byte mac[] = {
    0xDE, 0xAD, 0xBE, 0xEF, 0xFE, 0xED
};
IPAddress Local(169, 254, 200, 69);
IPAddress PLC(169, 254, 200, 187); // update with the IP Address of your Modbus server

int DBNum = 100; // This DB must be present in your PLC
byte Buffer[1024];

S7Client Client;

unsigned long Elapsed; // To calc the execution time
//----------------------------------------------------------------------
// Setup : Init Ethernet and Serial0 port
//----------------------------------------------------------------------
void setup() {
    // You can use Ethernet.init(pin) to configure the CS pin
    Ethernet.init(0);
    
    // Open Serial0 communications and wait for port to open:
    Serial0.begin(115200);
    
    //--------------------------------Wired Ethernet Shield Initialization
    // Start the Ethernet Library
    EthernetInit(mac, Local);
    // Setup Time, someone said me to leave 2000 because some
    // rubbish compatible boards are a bit deaf.
    delay(2000);
    Serial0.println("");
    Serial0.println("Cable connected");
    Serial0.print("Local IP address : ");
    Serial0.println(Ethernet.localIP());
}
//----------------------------------------------------------------------
// Connects to the PLC
//----------------------------------------------------------------------
bool Connect()
{
    int Result=Client.ConnectTo(PLC,
                                0,  // Rack (see the doc.)
                                2); // Slot (see the doc.)
    Serial0.print("Connecting to ");Serial0.println(PLC);
    if (Result==0)
    {
        Serial0.print("Connected ! PDU Length = ");Serial0.println(Client.GetPDULength());
    }
    else
        Serial0.println("Connection error");
    return Result==0;
}
//----------------------------------------------------------------------
// Dumps a buffer (a very rough routine)
//----------------------------------------------------------------------
void Dump(void *Buffer, int Length)
{
    int i, cnt=0;
    pbyte buf;
    
    if (Buffer!=NULL)
        buf = pbyte(Buffer);
    else
        buf = pbyte(&PDU.DATA[0]);

    Serial0.print("[ Dumping ");Serial0.print(Length);
    Serial0.println(" bytes ]===========================");
    for (i=0; i<Length; i++)
    {
        cnt++;
        if (buf[i]<0x10)
            Serial0.print("0");
        Serial0.print(buf[i], HEX);
        Serial0.print(" ");
        if (cnt==16)
        {
            cnt=0;
            Serial0.println();
        }
    }
    Serial0.println("===============================================");
}
//----------------------------------------------------------------------
// Prints the Error number
//----------------------------------------------------------------------
void CheckError(int ErrNo)
{
    Serial0.print("Error No. 0x");
    Serial0.println(ErrNo, HEX);
    
    // Checks if it's a Severe Error => we need to disconnect
    if (ErrNo & 0x00FF)
    {
        Serial0.println("SEVERE ERROR, disconnecting.");
        Client.Disconnect();
    }
}
//----------------------------------------------------------------------
// Profiling routines
//----------------------------------------------------------------------
void MarkTime()
{
    Elapsed=millis();
}
//----------------------------------------------------------------------
void ShowTime()
{
    // Calcs the time
    Elapsed=millis()-Elapsed;
    Serial0.print("Job time (ms) : ");
    Serial0.println(Elapsed);
}
//----------------------------------------------------------------------
// Main Loop
//----------------------------------------------------------------------
void loop()
{
    int Size, Result;
    void *Target;
    
    #ifdef DO_IT_SMALL
    Size=64;
    Target = NULL; // Uses the internal Buffer (PDU.DATA[])
    #else
    Size=1024;
    Target = &Buffer; // Uses a larger buffer
    #endif
    
    // Connection
    while (!Client.Connected)
    {
        if (!Connect())
            delay(500);
    }
    
    Serial0.print("Reading ");Serial0.print(Size);Serial0.print(" bytes from DB");Serial0.println(DBNum);
    // Get the current tick
    MarkTime();
    Result=Client.ReadArea(S7AreaDB, // We are requesting DB access
                           DBNum,    // DB Number
                           0,        // Start from byte N.0
                           Size,     // We need "Size" bytes
                           Target);  // Put them into our target (Buffer or PDU)
    if (Result==0)
    {
        ShowTime();
        Dump(Target, Size);
    }
    else
        CheckError(Result);
    
    delay(500);
}