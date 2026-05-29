set_global_assignment -entity "fft_0519" -library "lib_fft_0519" -name IP_TOOL_NAME "Qsys"
set_global_assignment -entity "fft_0519" -library "lib_fft_0519" -name IP_TOOL_VERSION "15.0"
set_global_assignment -entity "fft_0519" -library "lib_fft_0519" -name IP_TOOL_ENV "Qsys"
set_global_assignment -library "lib_fft_0519" -name SPD_FILE [file join $::quartus(sip_path) "../fft_0519.spd"]
set_global_assignment -library "lib_fft_0519" -name MISC_FILE [file join $::quartus(sip_path) "../../fft_0519.qsys"]

set_global_assignment -library "lib_fft_0519" -name MISC_FILE [file join $::quartus(sip_path) "fft_0519.v"]
set_global_assignment -library "lib_fft_0519" -name MISC_FILE [file join $::quartus(sip_path) "submodules/fft_0519_fft_ii_0_2n4096sin.hex"]
set_global_assignment -library "lib_fft_0519" -name MISC_FILE [file join $::quartus(sip_path) "submodules/fft_0519_fft_ii_0_3n4096cos.hex"]
set_global_assignment -library "lib_fft_0519" -name MISC_FILE [file join $::quartus(sip_path) "submodules/fft_0519_fft_ii_0_3n4096sin.hex"]
set_global_assignment -library "lib_fft_0519" -name MISC_FILE [file join $::quartus(sip_path) "submodules/fft_0519_fft_ii_0_1n4096cos.hex"]
set_global_assignment -library "lib_fft_0519" -name MISC_FILE [file join $::quartus(sip_path) "submodules/fft_0519_fft_ii_0_2n4096cos.hex"]
set_global_assignment -library "lib_fft_0519" -name MISC_FILE [file join $::quartus(sip_path) "submodules/fft_0519_fft_ii_0_1n4096sin.hex"]
set_global_assignment -library "lib_fft_0519" -name MISC_FILE [file join $::quartus(sip_path) "submodules/fft_0519_fft_ii_0.vo"]
