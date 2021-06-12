# Avalon PWM Controller v1.0
# Copyright (c) Dmitry Grigoryev 2019
# 
# Distributed under LGPL 2.1 licence, refer to LICENSE.md for details

#
# altera_avalon_timer_driver.tcl
#

# Create a new driver
create_driver avalon_pwm_driver

# Associate it with hardware known as "avalon_pwm"
set_sw_property hw_class_name avalon_pwm

# The version of this driver
set_sw_property version __VERSION_SHORT__

# This driver may be incompatible with versions of hardware less
# than specified below. Updates to hardware and device drivers
# rendering the driver incompatible with older versions of
# hardware are noted with this property assignment.
set_sw_property min_compatible_hw_version 1.0

# Initialize the driver in alt_sys_init()
set_sw_property auto_initialize false

# Location in generated BSP that above sources will be copied into
set_sw_property bsp_subdirectory drivers

# Set priority assignment for alt_sys_init()
# If left unspecified, driver priorities default to '1000'. The timer
# must be initialized before certain other drivers (JTAG UART, if
# present). Therefore, set a reasonably high priority to assure
# that the driver will be initialize first. Lower nubmer = higher
# priority.
set_sw_property alt_sys_init_priority 1000

# Interrupt properties: This driver supports both legacy and enhanced
# interrupt APIs, as well as ISR preemption.
set_sw_property isr_preemption_supported true
set_sw_property supported_interrupt_apis "legacy_interrupt_api enhanced_interrupt_api"


# Include files
# C/C++ source files
#add_sw_property c_source HAL/src/avalon_pwm.c

# Include files
#add_sw_property include_source HAL/inc/avalon_pwm.h
add_sw_property include_source inc/avalon_pwm_regs.h

# This driver supports HAL & UCOSII BSP (OS) types
add_sw_property supported_bsp_type HAL
#add_sw_property supported_bsp_type UCOSII
#add_sw_property supported_bsp_type BML

