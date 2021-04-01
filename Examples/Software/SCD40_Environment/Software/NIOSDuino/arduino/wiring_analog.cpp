/*
  wiring_analog.c - analog input and output
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

//! NIOSDuino custom file, (c) Dmitry Grigoryev, 2019-2020

#include "Arduino.h"
#include "pins_arduino.h"
#include <system.h>
#include <io.h>

#ifdef __ALTERA_MODULAR_ADC
#include <altera_modular_adc.h>
int analogRead(uint8_t pin)
{
	//adc_stop(MODULAR_ADC_0_SEQUENCER_CSR_BASE);
	//adc_set_mode_run_once(MODULAR_ADC_0_SEQUENCER_CSR_BASE);
	//adc_start(MODULAR_ADC_0_SEQUENCER_CSR_BASE);
    //while(IORD_ALTERA_MODULAR_ADC_SEQUENCER_CMD_REG(MODULAR_ADC_0_SEQUENCER_CSR_BASE)
    //         & ALTERA_MODULAR_ADC_SEQUENCER_CMD_RUN_MSK);
	return IORD_32DIRECT((MODULAR_ADC_0_SAMPLE_STORE_CSR_BASE + (pin << 2)),0);
}
#endif

uint8_t analog_reference = DEFAULT;

void analogReference(uint8_t mode)
{
	// can't actually set the register here because the default setting
	// will connect AVCC and the AREF pin, which would cause a short if
	// there's something connected to AREF.
	analog_reference = mode;
}


#ifdef __AVALON_PWM
#include <avalon_pwm_regs.h>
void analogWrite(uint8_t pin, int val)
{
	IOWR_AVALON_PWM_DUTY_CYCLE(PWM_0_BASE, pin, val);
}

void tone(uint8_t pin, unsigned int frequency, unsigned long duration)
{
	IOWR_AVALON_PWM_PRESCALER(PWM_0_BASE, (PWM_0_FREQ/512)/frequency);
	IOWR_AVALON_PWM_DUTY_CYCLE(PWM_0_BASE, pin, 128);
}

void noTone(uint8_t pin)
{
	IOWR_AVALON_PWM_DUTY_CYCLE(PWM_0_BASE, pin, 0);
}
#endif
