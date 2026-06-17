set_global_assignment -entity "FFT_615" -library "lib_FFT_615" -name IP_TOOL_NAME "Qsys"
set_global_assignment -entity "FFT_615" -library "lib_FFT_615" -name IP_TOOL_VERSION "15.0"
set_global_assignment -entity "FFT_615" -library "lib_FFT_615" -name IP_TOOL_ENV "Qsys"
set_global_assignment -library "lib_FFT_615" -name SPD_FILE [file join $::quartus(sip_path) "../FFT_615.spd"]
set_global_assignment -library "lib_FFT_615" -name MISC_FILE [file join $::quartus(sip_path) "../../FFT_615.qsys"]

set_global_assignment -library "lib_FFT_615" -name MISC_FILE [file join $::quartus(sip_path) "FFT_615.v"]
set_global_assignment -library "lib_FFT_615" -name MISC_FILE [file join $::quartus(sip_path) "submodules/FFT_615_fft_ii_0_2n4096cos.hex"]
set_global_assignment -library "lib_FFT_615" -name MISC_FILE [file join $::quartus(sip_path) "submodules/FFT_615_fft_ii_0_1n4096sin.hex"]
set_global_assignment -library "lib_FFT_615" -name MISC_FILE [file join $::quartus(sip_path) "submodules/FFT_615_fft_ii_0_3n4096cos.hex"]
set_global_assignment -library "lib_FFT_615" -name MISC_FILE [file join $::quartus(sip_path) "submodules/FFT_615_fft_ii_0_2n4096sin.hex"]
set_global_assignment -library "lib_FFT_615" -name MISC_FILE [file join $::quartus(sip_path) "submodules/FFT_615_fft_ii_0_3n4096sin.hex"]
set_global_assignment -library "lib_FFT_615" -name MISC_FILE [file join $::quartus(sip_path) "submodules/FFT_615_fft_ii_0_1n4096cos.hex"]
set_global_assignment -library "lib_FFT_615" -name MISC_FILE [file join $::quartus(sip_path) "submodules/FFT_615_fft_ii_0.vo"]
