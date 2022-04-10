#include "vhdplus_remote.h"
#include "Arduino.h"
#include <ESP8266WiFi.h>
#include <ESP8266WebServer.h>
//#include <functional>

void onB(String hook){

}

void onS(String hook, bool value){

}

void onSl(String hook, int value){

}

String onC(String hook, String value){
  return "";
}

void VHDPlusRemote::setLED(String id, bool on){
  int i = 0;
  for (; i < leds_length; i ++){
    if (leds[i] == id) {
      led_values[i] = on; 
      break;
    }
  }
  if(i == leds_length && i < MAX_LED_NUMBER){
    leds[i] = id;
    led_values[i] = on; 
    leds_length++;
  }
}

void VHDPlusRemote::setRGBLED(String id, String hexColor){
  int i = 0;
  for (; i < rgb_leds_length; i ++){
    if (rgb_leds[i] == id) {
      rgb_led_values[i] = hexColor; 
      break;
    }
  }
  if(i == rgb_leds_length && i < MAX_RGB_LED_NUMBER){
    rgb_leds[i] = id;
    rgb_led_values[i] = hexColor; 
    rgb_leds_length++;
  }
}

void VHDPlusRemote::setDisplay(String id, String text){
  int i = 0;
  for (; i < displays_length; i ++){
    if (displays[i] == id) {
      display_texts[i] = text; 
      break;
    }
  }
  if(i == displays_length && i < MAX_DISPLAY_NUMBER){
    displays[i] = id;
    display_texts[i] = text; 
    displays_length++;
  }
}

void VHDPlusRemote::setConsole(String id, String text){
  int i = 0;
  for (; i < consoles_length; i ++){
    if (consoles[i] == id) {
      console_texts[i] = text; 
      break;
    }
  }
  if(i == consoles_length && i < MAX_CONSOLE_NUMBER){
    consoles[i] = id;
    console_texts[i] = text; 
    consoles_length++;
  }
}

void VHDPlusRemote::setPlotter(String id, int* values){

}

bool VHDPlusRemote::connected(){
  return WiFi.status() == WL_CONNECTED;
}

IPAddress VHDPlusRemote::localIP(){
  return WiFi.localIP();
}

void VHDPlusRemote::run(){
  server.handleClient();
}

void VHDPlusRemote::sendResult(String content){
  server.send(200, "text/html", content);  
}

void VHDPlusRemote::callSend(){
  String answer = "A~OK";
  for (int i = 0; i < server.args(); i++) {
      String parameterName = server.argName(i);
      String parameterValue = server.arg(i);
      if(parameterName.length() > 0){
        int separator = parameterValue.indexOf('~');
        String hook = parameterValue;
        String value = "";
        if (separator > -1){
          hook = parameterValue.substring(0,separator);
          value = parameterValue.substring(separator+1);
        }
        switch (parameterName[0]){
          case BUTTON:
            _onButton(hook);
            break;
          case SWITCH:
             _onSwitch(hook, value == "1");
            break;
          case SLIDER:
            _onSlider(hook, value.toInt());
            break;
          case CONSOLE:
            answer = "C~" + _onConsole(hook, value);
            break;
        }
      }
  }
  sendResult(answer);
}

void VHDPlusRemote::callRead(){
  String answer = "R";
  bool error = false;
  for (int i = 0; i < server.args() && !error; i++) {
      String parameterName = server.argName(i);
      String parameterValue = server.arg(i) + "~";
      if (parameterName == "hooks") {
        int  s = 0; //start index
        char t = ' '; //type
        String id = "";
        for (int i=0; i < parameterValue.length() && !error; i++) //example: ~l_1~...
        { 
          if(parameterValue.charAt(i) == '~'){
            if(i > 0){
              answer += "~";
              switch (t){
                case LED:
                  for (int i = 0; i < leds_length; i ++){
                    if (leds[i] == id){
                      answer += led_values[i]?"1":"0";
                      break;
                    }
                  }
                  break;
                case RGB_LED:
                  for (int i = 0; i < rgb_leds_length; i ++){
                    if (rgb_leds[i] == id){
                      answer += rgb_led_values[i];
                      break;
                    }
                  }
                  break;
                case DISPLAY:
                  for (int i = 0; i < displays_length; i ++){
                    if (displays[i] == id){
                      answer += display_texts[i];
                      break;
                    }
                  }
                  break;
                case CONSOLE:
                  for (int i = 0; i < consoles_length; i ++){
                    if (consoles[i] == id){
                      answer += console_texts[i];
                      break;
                    }
                  }
                  break;
              }
            }
            s = i;
            id = "";
          }
          else if(i == s+1) t = parameterValue.charAt(i);
          else if(i == s+2) {
            if (parameterValue.charAt(i) != '_') error = true;
          }
          else id += parameterValue.charAt(i);

        }
      }
  }

  sendResult(answer);
}

void VHDPlusRemote::begin(char const* mySSID, char const* myPassword){
  ssid = mySSID;
  password = myPassword;

  _onButton = &onB;
  _onSwitch = &onS;
  _onSlider = &onSl;
  _onConsole = &onC;

  WiFi.begin(ssid, password);
 
  while (WiFi.status() != WL_CONNECTED) { 
    delay(500);
  }

  server.on("/send", std::bind(&VHDPlusRemote::callSend, this));
  server.on("/read", std::bind(&VHDPlusRemote::callRead, this));
     
  server.begin();
}