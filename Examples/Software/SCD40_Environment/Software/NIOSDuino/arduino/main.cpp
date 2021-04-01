/*
  main.cpp - Main loop for Arduino sketches
  Copyright (c) 2005-2013 Arduino Team.  All right reserved.

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

#include <Arduino.h>
#ifdef __ALTERA_MODULAR_ADC
#include <altera_modular_adc.h>
#endif

// Declared weak in Arduino.h to allow user redefinitions.
int atexit(void (* /*func*/ )()) { return 0; }


// Weak empty variant initialization function.
// May be redefined by variant files.
void initVariant() __attribute__((weak));
void initVariant() { }

void setupUSB() __attribute__((weak));
void setupUSB() { }

int main(void)
{
	//!init();

	//!initVariant();
#ifdef __ALTERA_MODULAR_ADC
	adc_stop(MODULAR_ADC_0_SEQUENCER_CSR_BASE);
	adc_interrupt_disable(MODULAR_ADC_0_SAMPLE_STORE_CSR_BASE);
	adc_set_mode_run_continuously(MODULAR_ADC_0_SEQUENCER_CSR_BASE);
	adc_start(MODULAR_ADC_0_SEQUENCER_CSR_BASE);
#endif

#if defined(USBCON)
	USBDevice.attach();
#endif
	
	setup();
    
	for (;;) {
		loop();
		//!if (serialEventRun) serialEventRun();
	}
        
	return 0;
}

