/*
  wiring_digital.c - digital input and output functions
  Part of Arduino - http://www.arduino.cc/

  Copyright (c) 2005-2006 David A. Mellis

  This library is free software; you can redistribute it and/or
  modify it under the terms of the GNU Lesser General Public
  License as published by the Free Software Foundation; either
  version 2.1 of the License, or (at your option) any later version.

  This library is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
  Lesser General Public License for more details.

  You should have received a copy of the GNU Lesser General
  Public License along with this library; if not, write to the
  Free Software Foundation, Inc., 59 Temple Place, Suite 330,
  Boston, MA  02111-1307  USA

  Modified 28 September 2010 by Mark Sproul
*/

//! NIOSDuino custom file, (c) Dmitry Grigoryev, 2018

#include "Arduino.h"
#if defined(PIO_0_BASE) || defined(PIO_1_BASE) || defined(PIO_2_BASE)
#include "pins_arduino.h"
#include <system.h>
#include <altera_avalon_pio_regs.h>

/*
 * IOs = pin 0-31
 * Outputs = pin 32-63
 */
void pinMode(uint8_t pin, uint8_t mode)
{
#if PIO_2_BASE && PIO_0_BASE
	if (pin < 32) {
		uint32_t data = IORD_ALTERA_AVALON_PIO_DIRECTION(PIO_0_BASE);
		if (mode == OUTPUT) data |= (1 << pin);
		else data &= ~(1 << pin);
		IOWR_ALTERA_AVALON_PIO_DIRECTION(PIO_0_BASE, data);
	}
	else {
		uint32_t data = IORD_ALTERA_AVALON_PIO_DIRECTION(PIO_2_BASE);
		if (mode == OUTPUT) data |= (1 << (pin - 32));
		else data &= ~(1 << (pin - 32));
		IOWR_ALTERA_AVALON_PIO_DIRECTION(PIO_2_BASE, data);
	}
#elif PIO_0_BASE
	uint32_t data = IORD_ALTERA_AVALON_PIO_DIRECTION(PIO_0_BASE);
	if (mode == OUTPUT) data |= (1 << pin);
	else data &= ~(1 << pin);
	IOWR_ALTERA_AVALON_PIO_DIRECTION(PIO_0_BASE, data);
#else 
	uint32_t data = IORD_ALTERA_AVALON_PIO_DIRECTION(PIO_2_BASE);
	if (mode == OUTPUT) data |= (1 << pin);
	else data &= ~(1 << pin);
	IOWR_ALTERA_AVALON_PIO_DIRECTION(PIO_2_BASE, data);
#endif
}

/*
 * IOs = pin 0-31
 * Outputs = pin 32-63
 */
void digitalWrite(uint8_t pin, uint8_t val)
{
#if PIO_2_BASE && PIO_0_BASE
	if (pin < 32) {
		if (val) IOWR_ALTERA_AVALON_PIO_SET_BITS(PIO_0_BASE, 1 << pin);
		else IOWR_ALTERA_AVALON_PIO_CLEAR_BITS(PIO_0_BASE, 1 << pin);
	}
	else {
		if (val) IOWR_ALTERA_AVALON_PIO_SET_BITS(PIO_2_BASE, 1 << (pin - 32));
		else IOWR_ALTERA_AVALON_PIO_CLEAR_BITS(PIO_2_BASE, 1 << (pin - 32));
	}
#elif PIO_0_BASE
	if (val) IOWR_ALTERA_AVALON_PIO_SET_BITS(PIO_0_BASE, 1 << pin);
	else IOWR_ALTERA_AVALON_PIO_CLEAR_BITS(PIO_0_BASE, 1 << pin);
#else
if (val) IOWR_ALTERA_AVALON_PIO_SET_BITS(PIO_2_BASE, 1 << pin);
else IOWR_ALTERA_AVALON_PIO_CLEAR_BITS(PIO_2_BASE, 1 << pin);
#endif
}

/*
 * IOs = pin 0-31
 * Inputs = pin 32-63
 */
int digitalRead(uint8_t pin)
{
#if PIO_1_BASE && PIO_0_BASE
	if (pin < 32) {
		uint32_t val = IORD_ALTERA_AVALON_PIO_DATA(PIO_0_BASE);
		return (val >> pin) & 1;
	}
	else {
		uint32_t val = IORD_ALTERA_AVALON_PIO_DATA(PIO_1_BASE);
		return (val >> (pin - 32)) & 1;
	}
#elif PIO_0_BASE
	uint32_t val = IORD_ALTERA_AVALON_PIO_DATA(PIO_0_BASE);
	return (val >> pin) & 1;
#else 
	uint32_t val = IORD_ALTERA_AVALON_PIO_DATA(PIO_1_BASE);
	return (val >> pin) & 1;
#endif
}
#endif