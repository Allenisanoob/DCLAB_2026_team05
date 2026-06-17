	UART_qsys u0 (
		.altpll_0_areset_conduit_export        (<connected-to-altpll_0_areset_conduit_export>),        //     altpll_0_areset_conduit.export
		.altpll_0_locked_conduit_export        (<connected-to-altpll_0_locked_conduit_export>),        //     altpll_0_locked_conduit.export
		.altpll_0_phasedone_conduit_export     (<connected-to-altpll_0_phasedone_conduit_export>),     //  altpll_0_phasedone_conduit.export
		.clk_clk                               (<connected-to-clk_clk>),                               //                         clk.clk
		.reset_reset_n                         (<connected-to-reset_reset_n>),                         //                       reset.reset_n
		.uart_0_external_connection_rxd        (<connected-to-uart_0_external_connection_rxd>),        //  uart_0_external_connection.rxd
		.uart_0_external_connection_txd        (<connected-to-uart_0_external_connection_txd>),        //                            .txd
		.avmwrapper_sv_0_conduit_end_command   (<connected-to-avmwrapper_sv_0_conduit_end_command>),   // avmwrapper_sv_0_conduit_end.command
		.avmwrapper_sv_0_conduit_end_valid_out (<connected-to-avmwrapper_sv_0_conduit_end_valid_out>)  //                            .valid_out
	);

