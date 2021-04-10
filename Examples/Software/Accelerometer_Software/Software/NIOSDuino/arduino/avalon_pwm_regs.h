/******************************************************************************
*  Avalon PWM Controller v1.0
* Copyright (c) Dmitry Grigoryev 2019
* 
* Distributed under LGPL 2.1 licence, refer to LICENSE.md for details                                                            *
******************************************************************************/

#ifndef __AVALON_PWM_REGS_H__
#define __AVALON_PWM_REGS_H__

#include <io.h>

#define IOADDR_AVALON_PWM_PRESCALER(base)      __IO_CALC_ADDRESS_NATIVE(base, 0)
#define IORD_AVALON_PWM_PRESCALER(base)        IORD(base, 0) 
#define IOWR_AVALON_PWM_PRESCALER(base, data)  IOWR(base, 0, data)

#define IOADDR_AVALON_PWM_POLARITY(base)       __IO_CALC_ADDRESS_NATIVE(base, 1)
#define IORD_AVALON_PWM_POLARITY(base)         IORD(base, 1) 
#define IOWR_AVALON_PWM_POLARITY(base, data)   IOWR(base, 1, data)

#define IOADDR_AVALON_PWM_CONTROL(base)        __IO_CALC_ADDRESS_NATIVE(base, 2)
#define IORD_AVALON_PWM_CONTROL(base)          IORD(base, 2) 
#define IOWR_AVALON_PWM_CONTROL(base, data)    IOWR(base, 2, data)

#define IOADDR_AVALON_PWM_DUTY_CYCLE(base, channel)       __IO_CALC_ADDRESS_NATIVE(base, 32+(channel))
#define IORD_AVALON_PWM_DUTY_CYCLE(base, channel)         IORD(base, 32+(channel)) 
#define IOWR_AVALON_PWM_DUTY_CYCLE(base, channel, data)   IOWR(base, 32+(channel), data)

// CONTROL register bits

#define AVALON_PWM_OUT_ENA  
#define AVALON_PWM_CNT_ENA  
#define AVALON_PWM_IRQL_ENA  
#define AVALON_PWM_IRQH_ENA  

#endif // __AVALON_PWM_REGS_H__
