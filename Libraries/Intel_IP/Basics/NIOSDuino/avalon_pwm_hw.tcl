# Avalon PWM Controller v1.0
# Copyright (c) Dmitry Grigoryev 2019
# 
# Distributed under LGPL 2.1 licence, refer to LICENSE.md for details

package require -exact qsys 12.0


# 
# module pwm
# 
set_module_property DESCRIPTION ""
set_module_property NAME avalon_pwm
set_module_property VERSION 1.0
set_module_property INTERNAL false
set_module_property OPAQUE_ADDRESS_MAP true
set_module_property GROUP "Basic Functions/I/O"
set_module_property AUTHOR "Dmitry Grigoryev"
set_module_property DISPLAY_NAME "Avalon PWM Controller"
set_module_property INSTANTIATE_IN_SYSTEM_MODULE true
set_module_property EDITABLE true
set_module_property REPORT_TO_TALKBACK false
set_module_property ALLOW_GREYBOX_GENERATION false
set_module_property REPORT_HIERARCHY false
set_module_property VALIDATION_CALLBACK validate

# 
# file sets
# 
add_fileset QUARTUS_SYNTH QUARTUS_SYNTH "" ""
set_fileset_property QUARTUS_SYNTH TOP_LEVEL avalon_pwm
set_fileset_property QUARTUS_SYNTH ENABLE_RELATIVE_INCLUDE_PATHS false
set_fileset_property QUARTUS_SYNTH ENABLE_FILE_OVERWRITE_MODE false
add_fileset_file avalon_pwm.v VERILOG PATH avalon_pwm.v TOP_LEVEL_FILE


# 
# parameters
# 
add_parameter CLK_PRESCALER_WIDTH POSITIVE 16 "Clock prescaler (frequency divider) counter width"
set_parameter_property CLK_PRESCALER_WIDTH DEFAULT_VALUE 16
set_parameter_property CLK_PRESCALER_WIDTH DISPLAY_NAME {Clock prescaler (frequency divider) counter width}
set_parameter_property CLK_PRESCALER_WIDTH WIDTH ""
set_parameter_property CLK_PRESCALER_WIDTH TYPE POSITIVE
set_parameter_property CLK_PRESCALER_WIDTH UNITS None
set_parameter_property CLK_PRESCALER_WIDTH ALLOWED_RANGES 1:32
set_parameter_property CLK_PRESCALER_WIDTH DESCRIPTION "PWM counter frequency will be configurable as Fcnt = Fclk / (prescaler+1) "
set_parameter_property CLK_PRESCALER_WIDTH HDL_PARAMETER true
add_parameter PWM_COUNTER_WIDTH POSITIVE 8 "Duty cycle counter width (duty cycle resolution)"
set_parameter_property PWM_COUNTER_WIDTH DEFAULT_VALUE 8
set_parameter_property PWM_COUNTER_WIDTH DISPLAY_NAME {PWM cycle counter width (duty cycle resolution)}
set_parameter_property PWM_COUNTER_WIDTH WIDTH ""
set_parameter_property PWM_COUNTER_WIDTH TYPE POSITIVE
set_parameter_property PWM_COUNTER_WIDTH UNITS None
set_parameter_property PWM_COUNTER_WIDTH ALLOWED_RANGES 1:32
set_parameter_property PWM_COUNTER_WIDTH DESCRIPTION "PWM signal will have 2^N levels, PWM frequency will be Fpwm = Fcnt / 2^(N+1)"
set_parameter_property PWM_COUNTER_WIDTH HDL_PARAMETER true
add_parameter PWM_OUTPUTS_COUNT POSITIVE 4 "Number of PWM output pins"
set_parameter_property PWM_OUTPUTS_COUNT DEFAULT_VALUE 4
set_parameter_property PWM_OUTPUTS_COUNT DISPLAY_NAME {Number of PWM output pins}
set_parameter_property PWM_OUTPUTS_COUNT WIDTH ""
set_parameter_property PWM_OUTPUTS_COUNT TYPE POSITIVE
set_parameter_property PWM_OUTPUTS_COUNT UNITS None
set_parameter_property PWM_OUTPUTS_COUNT ALLOWED_RANGES 1:32
set_parameter_property PWM_OUTPUTS_COUNT DESCRIPTION "Number of PWM output pins"
set_parameter_property PWM_OUTPUTS_COUNT HDL_PARAMETER true
add_parameter PRELOAD_REGS BOOLEAN false "Use preload registers for duty cycle values"
set_parameter_property PRELOAD_REGS DEFAULT_VALUE false
set_parameter_property PRELOAD_REGS DISPLAY_NAME {Use preload registers for duty cycle values}
set_parameter_property PRELOAD_REGS WIDTH ""
set_parameter_property PRELOAD_REGS TYPE BOOLEAN
set_parameter_property PRELOAD_REGS UNITS None
set_parameter_property PRELOAD_REGS DESCRIPTION "Preload registers make duty cycles on all outputs change simultaneously"
set_parameter_property PRELOAD_REGS HDL_PARAMETER true
add_parameter CONSTANT_MAX BOOLEAN true "Output constant high level at max duty cycle"
set_parameter_property CONSTANT_MAX DEFAULT_VALUE true
set_parameter_property CONSTANT_MAX DISPLAY_NAME {Output constant high level at max duty cycle}
set_parameter_property CONSTANT_MAX WIDTH ""
set_parameter_property CONSTANT_MAX TYPE BOOLEAN
set_parameter_property CONSTANT_MAX UNITS None
set_parameter_property CONSTANT_MAX DESCRIPTION "Makes the maximum duty cycle register value correspond to 100% instead of 2^N / (2^N -1)"
set_parameter_property CONSTANT_MAX HDL_PARAMETER true
add_parameter PULSE_DITHER BOOLEAN false "Dither the PWM pulse (increases frequency above PWM period)"
set_parameter_property PULSE_DITHER DEFAULT_VALUE false
set_parameter_property PULSE_DITHER DISPLAY_NAME {Dither the PWM pulse}
set_parameter_property PULSE_DITHER WIDTH ""
set_parameter_property PULSE_DITHER TYPE BOOLEAN
set_parameter_property PULSE_DITHER UNITS None
set_parameter_property PULSE_DITHER DESCRIPTION "Produces several short pulses per period instead of a single pulse"
set_parameter_property PULSE_DITHER HDL_PARAMETER true


# 
# display items
# 
# display group
add_display_item {} {Basic Settings} GROUP
add_display_item {} {Output Settings} GROUP

add_display_item {Basic Settings} CLK_PRESCALER_WIDTH PARAMETER
add_display_item {Basic Settings} PWM_COUNTER_WIDTH PARAMETER
add_display_item {Basic Settings} PRELOAD_REGS PARAMETER

add_display_item {Output Settings} PWM_OUTPUTS_COUNT PARAMETER
add_display_item {Output Settings} CONSTANT_MAX PARAMETER
add_display_item {Output Settings} PULSE_DITHER PARAMETER

# system info parameters
add_parameter clockRate LONG
set_parameter_property clockRate DEFAULT_VALUE {0}
set_parameter_property clockRate DISPLAY_NAME {clockRate}
set_parameter_property clockRate VISIBLE {0}
set_parameter_property clockRate AFFECTS_GENERATION {1}
set_parameter_property clockRate HDL_PARAMETER {0}
set_parameter_property clockRate SYSTEM_INFO {clock_rate clock}
set_parameter_property clockRate SYSTEM_INFO_TYPE {CLOCK_RATE}
set_parameter_property clockRate SYSTEM_INFO_ARG {clock}


# 
# connection point clock
# 
add_interface clock clock end
set_interface_property clock clockRate 0
set_interface_property clock ENABLED true
set_interface_property clock EXPORT_OF ""
set_interface_property clock PORT_NAME_MAP ""
set_interface_property clock CMSIS_SVD_VARIABLES ""
set_interface_property clock SVD_ADDRESS_GROUP ""

add_interface_port clock clk clk Input 1


# 
# connection point reset
# 
add_interface reset reset end
set_interface_property reset associatedClock clock
set_interface_property reset synchronousEdges DEASSERT
set_interface_property reset ENABLED true
set_interface_property reset EXPORT_OF ""
set_interface_property reset PORT_NAME_MAP ""
set_interface_property reset CMSIS_SVD_VARIABLES ""
set_interface_property reset SVD_ADDRESS_GROUP ""

add_interface_port reset reset_n reset_n Input 1


# 
# connection point avalon_slave_0
# 
add_interface avalon_slave_0 avalon end
set_interface_property avalon_slave_0 addressUnits WORDS
set_interface_property avalon_slave_0 associatedClock clock
set_interface_property avalon_slave_0 associatedReset reset
set_interface_property avalon_slave_0 bitsPerSymbol 8
set_interface_property avalon_slave_0 burstOnBurstBoundariesOnly false
set_interface_property avalon_slave_0 burstcountUnits WORDS
set_interface_property avalon_slave_0 explicitAddressSpan 0
set_interface_property avalon_slave_0 holdTime 0
set_interface_property avalon_slave_0 linewrapBursts false
set_interface_property avalon_slave_0 maximumPendingReadTransactions 0
set_interface_property avalon_slave_0 maximumPendingWriteTransactions 0
set_interface_property avalon_slave_0 readLatency 0
set_interface_property avalon_slave_0 readWaitTime 1
set_interface_property avalon_slave_0 setupTime 0
set_interface_property avalon_slave_0 timingUnits Cycles
set_interface_property avalon_slave_0 writeWaitTime 0
set_interface_property avalon_slave_0 ENABLED true
set_interface_property avalon_slave_0 EXPORT_OF ""
set_interface_property avalon_slave_0 PORT_NAME_MAP ""
set_interface_property avalon_slave_0 CMSIS_SVD_VARIABLES ""
set_interface_property avalon_slave_0 SVD_ADDRESS_GROUP ""

add_interface_port avalon_slave_0 chipselect chipselect Input 1
add_interface_port avalon_slave_0 address address Input 6
add_interface_port avalon_slave_0 write write Input 1
add_interface_port avalon_slave_0 writedata writedata Input 32
add_interface_port avalon_slave_0 read read Input 1
add_interface_port avalon_slave_0 readdata readdata Output 32
set_interface_assignment avalon_slave_0 embeddedsw.configuration.isFlash 0
set_interface_assignment avalon_slave_0 embeddedsw.configuration.isMemoryDevice 0
set_interface_assignment avalon_slave_0 embeddedsw.configuration.isNonVolatileStorage 0
set_interface_assignment avalon_slave_0 embeddedsw.configuration.isPrintableDevice 0


# 
# connection point ext
# 
add_interface ext conduit end
set_interface_property ext associatedClock clock
set_interface_property ext associatedReset reset
set_interface_property ext ENABLED true
set_interface_property ext EXPORT_OF ""
set_interface_property ext PORT_NAME_MAP ""
set_interface_property ext CMSIS_SVD_VARIABLES ""
set_interface_property ext SVD_ADDRESS_GROUP ""

add_interface_port ext pwm_out out Output PWM_OUTPUTS_COUNT


# 
# connection point interrupt_sender
# 
add_interface interrupt_sender interrupt end
set_interface_property interrupt_sender associatedAddressablePoint ""
set_interface_property interrupt_sender associatedClock clock
set_interface_property interrupt_sender bridgedReceiverOffset ""
set_interface_property interrupt_sender bridgesToReceiver ""
set_interface_property interrupt_sender ENABLED true
set_interface_property interrupt_sender EXPORT_OF ""
set_interface_property interrupt_sender PORT_NAME_MAP ""
set_interface_property interrupt_sender CMSIS_SVD_VARIABLES ""
set_interface_property interrupt_sender SVD_ADDRESS_GROUP ""

add_interface_port interrupt_sender irq irq Output 1


proc validate {} {
	set CLK_PRESCALER_WIDTH [ get_parameter_value CLK_PRESCALER_WIDTH ]
	set PWM_COUNTER_WIDTH [ get_parameter_value PWM_COUNTER_WIDTH ]
	set PWM_OUTPUTS_COUNT [ get_parameter_value PWM_OUTPUTS_COUNT ]
	
	set PRELOAD_REGS [ get_parameter_value PRELOAD_REGS ]
	set CONSTANT_MAX [ get_parameter_value CONSTANT_MAX ]
	set PULSE_DITHER [ get_parameter_value PULSE_DITHER ]
	
	set CLOCK_RATE [ get_parameter_value clockRate ]
	
	set_module_assignment embeddedsw.CMacro.CLK_PRESCALER_WIDTH "$CLK_PRESCALER_WIDTH"
	set_module_assignment embeddedsw.CMacro.PWM_COUNTER_WIDTH "$PWM_COUNTER_WIDTH"
	set_module_assignment embeddedsw.CMacro.PWM_OUTPUTS_COUNT "$PWM_OUTPUTS_COUNT"
	
	set_module_assignment embeddedsw.CMacro.PRELOAD_REGS "$PRELOAD_REGS"
	set_module_assignment embeddedsw.CMacro.CONSTANT_MAX "$CONSTANT_MAX"
	set_module_assignment embeddedsw.CMacro.PULSE_DITHER "$PULSE_DITHER"
	
	set_module_assignment embeddedsw.CMacro.FREQ "$CLOCK_RATE"
}

add_documentation_link "Readme" https://github.com/dimag0g/avalon_pwm 