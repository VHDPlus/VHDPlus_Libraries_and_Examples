/*
  HardwareSerial.cpp - Hardware serial library for Wiring
  Copyright (c) 2006 Nicholas Zambetti.  All right reserved.

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

  Modified 23 November 2006 by David A. Mellis
  Modified 28 September 2010 by Mark Sproul
  Modified 14 August 2012 by Alarus
  Modified 3 December 2013 by Matthijs Kooijman
*/

//! NIOSDuino custom file, (c) Dmitry Grigoryev, 2018-2020

#include <stdlib.h>
#include <string.h>
#include <inttypes.h>
#include "Arduino.h"

//extern int altera_avalon_uart_read(altera_avalon_uart_state* sp, char* ptr, int len, int flags);
//extern int altera_avalon_uart_write(altera_avalon_uart_state* sp, const char* ptr, int len, int flags);
#include <sys/stat.h>
#include <sys/types.h>
#include <fcntl.h>
#include "HardwareSerial.h"

#ifdef __ALTERA_AVALON_UART
#include <altera_avalon_uart_regs.h>
#include <altera_avalon_uart.h>
#include <altera_avalon_uart_fd.h>

void HardwareSerial::begin(unsigned long baud, byte config)
{
  alt_u32 divisor = (UART_0_FREQ/baud)-1;
  IOWR_ALTERA_AVALON_UART_DIVISOR(UART_0_BASE, divisor);
   //fp = fopen(UART_0_NAME, "r+");
  fd = ::open(devname, O_RDWR);
}

void HardwareSerial::end()
{
  //fclose(fp);
}

int HardwareSerial::available(void)
{
  return 1;
}

int HardwareSerial::peek(void)
{
  return -1;
}

int HardwareSerial::read(void)
{
	char c;
	::read(fd, &c, 1);
	return (unsigned char)c;
  //return fgetc(fp);
}

int HardwareSerial::availableForWrite(void)
{
  return 1;
}

void HardwareSerial::flush()
{
  //fflush(fp);
}

size_t HardwareSerial::write(uint8_t c)
{
	return ::write(fd, (char *)&c, 1);
  //return fputc(c, fp);
}

#endif // __ALTERA_AVALON_UART
