set_global_assignment -entity "SDRAM" -library "lib_SDRAM" -name IP_TOOL_NAME "Qsys"
set_global_assignment -entity "SDRAM" -library "lib_SDRAM" -name IP_TOOL_VERSION "18.1"
set_global_assignment -entity "SDRAM" -library "lib_SDRAM" -name IP_TOOL_ENV "Qsys"
set_global_assignment -library "lib_SDRAM" -name SPD_FILE [file join $::quartus(sip_path) "../SDRAM.spd"]
set_global_assignment -library "lib_SDRAM" -name MISC_FILE [file join $::quartus(sip_path) "../../SDRAM.qsys"]

set_global_assignment -library "lib_SDRAM" -name MISC_FILE [file join $::quartus(sip_path) "SDRAM.vhd"]
set_global_assignment -library "lib_SDRAM" -name MISC_FILE [file join $::quartus(sip_path) "submodules/altera_reset_controller.v"]
set_global_assignment -library "lib_SDRAM" -name MISC_FILE [file join $::quartus(sip_path) "submodules/altera_reset_synchronizer.v"]
set_global_assignment -library "lib_SDRAM" -name MISC_FILE [file join $::quartus(sip_path) "submodules/altera_reset_controller.sdc"]
set_global_assignment -library "lib_SDRAM" -name MISC_FILE [file join $::quartus(sip_path) "submodules/SDRAM_sdram_controller_0.vhd"]
set_global_assignment -library "lib_SDRAM" -name MISC_FILE [file join $::quartus(sip_path) "submodules/SDRAM_sdram_controller_0_test_component.vhd"]
