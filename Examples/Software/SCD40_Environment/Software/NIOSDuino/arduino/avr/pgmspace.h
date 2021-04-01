//! NIOSDuino custom file, (c) Dmitry Grigoryev, 2018

#ifndef __PGMSPACE_H_
#define __PGMSPACE_H_ 1

//!#define PROGMEM __ATTR_PROGMEM__
#define PROGMEM
# define PSTR(s) ((const PROGMEM char *)(s))
#define PGM_P const char *
#define pgm_read_byte(address)    *((char *)(address))
#define pgm_read_word(address)    *((short *)(address))
#define strcpy_P strcpy
#define strlen_P strlen
#endif
