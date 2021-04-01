//! NIOSDuino custom file, (c) Dmitry Grigoryev, 2018

#include "eeprom.h"
#include <system.h>

#ifdef __ALTERA_ONCHIP_FLASH

#include <altera_onchip_flash.h>



//#else // no __ALTERA_ONCHIP_FLASH : provide RAM emulation

volatile uint8_t eedata[E2END+1] __attribute__ ((section (".noinit")));

uint8_t eeprom_read_byte (const uint8_t *p) { return eedata[(unsigned int)p]; }

void eeprom_write_byte (uint8_t *p, uint8_t value) { eedata[(unsigned int)p] = value; }

#endif // __ALTERA_ONCHIP_FLASH
