/*
  GenericSerial.cpp - Generic serial library using STDIN/STDOUT

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

//! NIOSDuino custom file, (c) Dmitry Grigoryev, 2018-2020

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <inttypes.h>
#include "Arduino.h"

#include "GenericSerial.h"
#include <sys/stat.h>
#include <sys/types.h>
#include <sys/alt_dev.h>
#include <fcntl.h>

extern alt_fd alt_fd_list[];

void GenericSerial::begin(unsigned long baud, byte config)
{
	alt_fd_list[0].fd_flags = O_NONBLOCK; // set non-blocking mode for STDIN, to allow peek()
}

void GenericSerial::end()
{
	flush();
}

int GenericSerial::available(void)
{
	return (peek() != -1);
}

int GenericSerial::peek(void)
{
	if(next_char == -1) {
		unsigned char c;
		if(::read(0, &c, 1) == 1) next_char = c;
	}
	return next_char;
}

int GenericSerial::read(void)
{
	unsigned char c;
	if(next_char != -1) {
		c = next_char;
		next_char = -1;
	} else if(::read(0, &c, 1) != 1) return -1;
	return c;
}

int GenericSerial::availableForWrite(void)
{
  return 1;
}

void GenericSerial::flush()
{
#ifdef ALT_SEMIHOSTING
  alt_putbufflush();
#endif
}

size_t GenericSerial::write(uint8_t c)
{
	::write(2, (char *)&c, 1);
	return ::write(1, (char *)&c, 1);
}

GenericSerial Serial;
