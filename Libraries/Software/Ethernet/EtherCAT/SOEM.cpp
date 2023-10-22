#include <stdarg.h>
#include <stdio.h>
#include <Arduino.h>
#include "osal/osal_defs.h" // EC_DEBUG

#if defined(__cplusplus)
extern "C" {
    #endif
    // just for debug (not thread safe)
    void debug_print(const char* format, ...)
    {
        static char buff[1024]; // TODO non-reentrant
        
        va_list args;
        va_start( args, format );
        vsnprintf( buff, sizeof(buff), format, args );
        va_end(args);

        Serial.print(buff);
    }
    #ifdef __cplusplus
}
#endif

/**************************************************
  for Ethernet Shield (W5500)
 **************************************************/

#include <SPI.h>
#include "w5500/w5500.h"

// W5500 RAW socket
static SOCKET sock;
// W5500 RAW socket buffer
static unsigned char socketBuffer[1536];

#ifdef __cplusplus
extern "C"
{
    #endif

    // (1) open
    // return: 0=SUCCESS
    int hal_ethernet_open(int CS)
    {
        w5500.init(CS); // M5Stack's SS is GPIO26.
        w5500.writeSnMR(sock, SnMR::MACRAW);
        w5500.execCmdSn(sock, Sock_OPEN);
        return 0;
    }

    // (2) close
    void hal_ethernet_close(void)
    {
        // w5500 doesn't have close() or terminate() method
        w5500.swReset();
    }

    // (3) send
    // return: 0=SUCCESS (!!! not sent size)
    int hal_ethernet_send(unsigned char *data, int len)
    {
        w5500.send_data_processing(sock, (byte *)data, len);
        w5500.execCmdSn(sock, Sock_SEND_MAC);
        return 0;
    }

    // (4) receive
    // return: received size
    int hal_ethernet_recv(unsigned char **data)
    {
        unsigned short packetSize;
        int res = w5500.getRXReceivedSize(sock);
        if(res > 0){
            // first 2byte shows packet size
            w5500.recv_data_processing(sock, (byte*)socketBuffer, 2);
            w5500.execCmdSn(sock, Sock_RECV);
            // packet size
            packetSize  = socketBuffer[0];
            packetSize  <<= 8;
            packetSize  &= 0xFF00;
            packetSize  |= (unsigned short)( (unsigned char)socketBuffer[1] & 0x00FF);
            packetSize  -= 2;
            // get received data
            memset(socketBuffer, 0x00, 1536);
            w5500.recv_data_processing(sock, (byte *)socketBuffer, packetSize);
            w5500.execCmdSn(sock, Sock_RECV);
            *data = socketBuffer;
        }
        return packetSize;
    }

    #ifdef __cplusplus
}
#endif

