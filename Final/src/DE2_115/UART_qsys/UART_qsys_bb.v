
module UART_qsys (
	altpll_0_areset_conduit_export,
	altpll_0_locked_conduit_export,
	altpll_0_phasedone_conduit_export,
	clk_clk,
	reset_reset_n,
	uart_0_external_connection_rxd,
	uart_0_external_connection_txd,
	avmwrapper_sv_0_conduit_end_command,
	avmwrapper_sv_0_conduit_end_valid_out);	

	input		altpll_0_areset_conduit_export;
	output		altpll_0_locked_conduit_export;
	output		altpll_0_phasedone_conduit_export;
	input		clk_clk;
	input		reset_reset_n;
	input		uart_0_external_connection_rxd;
	output		uart_0_external_connection_txd;
	output	[255:0]	avmwrapper_sv_0_conduit_end_command;
	output		avmwrapper_sv_0_conduit_end_valid_out;
endmodule
