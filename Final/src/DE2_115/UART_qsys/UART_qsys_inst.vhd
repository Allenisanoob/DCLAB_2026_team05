	component UART_qsys is
		port (
			altpll_0_areset_conduit_export        : in  std_logic                      := 'X'; -- export
			altpll_0_locked_conduit_export        : out std_logic;                             -- export
			altpll_0_phasedone_conduit_export     : out std_logic;                             -- export
			clk_clk                               : in  std_logic                      := 'X'; -- clk
			reset_reset_n                         : in  std_logic                      := 'X'; -- reset_n
			uart_0_external_connection_rxd        : in  std_logic                      := 'X'; -- rxd
			uart_0_external_connection_txd        : out std_logic;                             -- txd
			avmwrapper_sv_0_conduit_end_command   : out std_logic_vector(255 downto 0);        -- command
			avmwrapper_sv_0_conduit_end_valid_out : out std_logic                              -- valid_out
		);
	end component UART_qsys;

	u0 : component UART_qsys
		port map (
			altpll_0_areset_conduit_export        => CONNECTED_TO_altpll_0_areset_conduit_export,        --     altpll_0_areset_conduit.export
			altpll_0_locked_conduit_export        => CONNECTED_TO_altpll_0_locked_conduit_export,        --     altpll_0_locked_conduit.export
			altpll_0_phasedone_conduit_export     => CONNECTED_TO_altpll_0_phasedone_conduit_export,     --  altpll_0_phasedone_conduit.export
			clk_clk                               => CONNECTED_TO_clk_clk,                               --                         clk.clk
			reset_reset_n                         => CONNECTED_TO_reset_reset_n,                         --                       reset.reset_n
			uart_0_external_connection_rxd        => CONNECTED_TO_uart_0_external_connection_rxd,        --  uart_0_external_connection.rxd
			uart_0_external_connection_txd        => CONNECTED_TO_uart_0_external_connection_txd,        --                            .txd
			avmwrapper_sv_0_conduit_end_command   => CONNECTED_TO_avmwrapper_sv_0_conduit_end_command,   -- avmwrapper_sv_0_conduit_end.command
			avmwrapper_sv_0_conduit_end_valid_out => CONNECTED_TO_avmwrapper_sv_0_conduit_end_valid_out  --                            .valid_out
		);

