/*
  Tone.cpp
  A Tone Generator Library for the ESP8266
  Original Copyright (c) 2016 Ben Pirt. All rights reserved.
  This file is part of the esp8266 core for Arduino environment.
  This library is free software; you can redistribute it and/or
  modify it under the terms of the GNU Lesser General Public
  License as published by the Free Software Foundation; either
  version 2.1 of the License, or (at your option) any later version.
  This library is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
  Lesser General Public License for more details.
  You should have received a copy of the GNU Lesser General Public
  License along with this library; if not, write to the Free Software
  Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
 */

#include "Tone.h"
#include <Arduino.h>

void Tone::begin(uint8_t tonePin)
{
    _pin = tonePin;
}

bool Tone::isPlaying()
{
    return playing;
}

void Tone::play(uint16_t frequency, uint32_t duration)
{
    playing = true;
    tone(_pin, frequency);
    //With timer interrupt
    if(duration > 0)
    {
        delay(duration);
        playing = false;
    }
}

void Tone::stop()
{
    playing = false;
    noTone(_pin);
}