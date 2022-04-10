#ifndef VHDPLUS_REMOTE
#define VHDPLUS_REMOTE

#include "Arduino.h"
#include <ESP8266WiFi.h>
#include <ESP8266WebServer.h>
//#include <functional>

#define BUTTON   'b'
#define LED      'l'
#define SWITCH   's'
#define RGB_LED  'r'
#define DISPLAY  'd'
#define SLIDER   'i'
#define JOYSTICK 'j'
#define PLOTTER  'p'
#define CONSOLE  'c'
#define VIDEO    'v'

#define MAX_LED_NUMBER 64
#define MAX_RGB_LED_NUMBER 64
#define MAX_DISPLAY_NUMBER 64
#define MAX_CONSOLE_NUMBER 64

class VHDPlusRemote
{
  protected:
    const char* ssid;
    const char* password;

    int leds_length = 0;
    String leds[MAX_LED_NUMBER];
    bool led_values[MAX_LED_NUMBER];

    int rgb_leds_length = 0;
    String rgb_leds[MAX_RGB_LED_NUMBER];
    String rgb_led_values[MAX_RGB_LED_NUMBER];

    int displays_length = 0;
    String displays[MAX_DISPLAY_NUMBER];
    String display_texts[MAX_DISPLAY_NUMBER];

    int consoles_length = 0;
    String consoles[MAX_CONSOLE_NUMBER];
    String console_texts[MAX_CONSOLE_NUMBER];

    void callSend();
    void callRead();
    void sendResult(String content);

  public:
    VHDPlusRemote() : server(80) { }

    ESP8266WebServer server;

    void (*_onButton)(String);
    void (*_onSwitch)(String, bool);
    void (*_onSlider)(String, int);
    String (*_onConsole)(String, String);

    void begin(char const* ssid, char const* password);
    bool connected();
    IPAddress localIP();
    void run();
    void setLED(String id, bool on);
    void setRGBLED(String id, String hexColor);
    void setDisplay(String id, String text);
    void setConsole(String id, String text);
    void setPlotter(String id, int* values);
    void onButtonHandler(void (*f)(String)) { _onButton = f; }
    void onSwitchHandler(void (*f)(String, bool)) { _onSwitch = f; }
    void onSliderHandler(void (*f)(String, int)) { _onSlider = f; }
    void onConsoleHandler(String (*f)(String, String)) { _onConsole = f; }

};

#endif