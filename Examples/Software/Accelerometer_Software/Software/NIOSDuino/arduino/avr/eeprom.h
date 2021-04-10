//! NIOSDuino custom file, (c) Dmitry Grigoryev, 2018

#ifndef _AVR_EEPROM_H_
#define _AVR_EEPROM_H_

#include <inttypes.h>

#ifdef __cplusplus
extern "C" {
#endif

#define E2END 1023

uint8_t eeprom_read_byte (const uint8_t *p);
void eeprom_write_byte (uint8_t *p, uint8_t value);

#ifdef __cplusplus
}
#endif

#endif
