module DE2_115 (
	input CLOCK_50,
	input CLOCK2_50,
	input CLOCK3_50,
	input ENETCLK_25,
	input SMA_CLKIN,
	output SMA_CLKOUT,
	output [8:0] LEDG,
	output [17:0] LEDR,
	input [3:0] KEY,
	input [17:0] SW,
	output [6:0] HEX0,
	output [6:0] HEX1,
	output [6:0] HEX2,
	output [6:0] HEX3,
	output [6:0] HEX4,
	output [6:0] HEX5,
	output [6:0] HEX6,
	output [6:0] HEX7,
	output LCD_BLON,
	inout [7:0] LCD_DATA,
	output LCD_EN,
	output LCD_ON,
	output LCD_RS,
	output LCD_RW,
	output UART_CTS,
	input UART_RTS,
	input UART_RXD,
	output UART_TXD,
	inout PS2_CLK,
	inout PS2_DAT,
	inout PS2_CLK2,
	inout PS2_DAT2,
	output SD_CLK,
	inout SD_CMD,
	inout [3:0] SD_DAT,
	input SD_WP_N,
	output [7:0] VGA_B,
	output VGA_BLANK_N,
	output VGA_CLK,
	output [7:0] VGA_G,
	output VGA_HS,
	output [7:0] VGA_R,
	output VGA_SYNC_N,
	output VGA_VS,
	input AUD_ADCDAT,
	inout AUD_ADCLRCK,
	inout AUD_BCLK,
	output AUD_DACDAT,
	inout AUD_DACLRCK,
	output AUD_XCK,
	output EEP_I2C_SCLK,
	inout EEP_I2C_SDAT,
	output I2C_SCLK,
	inout I2C_SDAT,
	output ENET0_GTX_CLK,
	input ENET0_INT_N,
	output ENET0_MDC,
	input ENET0_MDIO,
	output ENET0_RST_N,
	input ENET0_RX_CLK,
	input ENET0_RX_COL,
	input ENET0_RX_CRS,
	input [3:0] ENET0_RX_DATA,
	input ENET0_RX_DV,
	input ENET0_RX_ER,
	input ENET0_TX_CLK,
	output [3:0] ENET0_TX_DATA,
	output ENET0_TX_EN,
	output ENET0_TX_ER,
	input ENET0_LINK100,
	output ENET1_GTX_CLK,
	input ENET1_INT_N,
	output ENET1_MDC,
	input ENET1_MDIO,
	output ENET1_RST_N,
	input ENET1_RX_CLK,
	input ENET1_RX_COL,
	input ENET1_RX_CRS,
	input [3:0] ENET1_RX_DATA,
	input ENET1_RX_DV,
	input ENET1_RX_ER,
	input ENET1_TX_CLK,
	output [3:0] ENET1_TX_DATA,
	output ENET1_TX_EN,
	output ENET1_TX_ER,
	input ENET1_LINK100,
	input TD_CLK27,
	input [7:0] TD_DATA,
	input TD_HS,
	output TD_RESET_N,
	input TD_VS,
	inout [15:0] OTG_DATA,
	output [1:0] OTG_ADDR,
	output OTG_CS_N,
	output OTG_WR_N,
	output OTG_RD_N,
	input OTG_INT,
	output OTG_RST_N,
	input IRDA_RXD,
	output [12:0] DRAM_ADDR,
	output [1:0] DRAM_BA,
	output DRAM_CAS_N,
	output DRAM_CKE,
	output DRAM_CLK,
	output DRAM_CS_N,
	inout [31:0] DRAM_DQ,
	output [3:0] DRAM_DQM,
	output DRAM_RAS_N,
	output DRAM_WE_N,
	output [19:0] SRAM_ADDR,
	output SRAM_CE_N,
	inout [15:0] SRAM_DQ,
	output SRAM_LB_N,
	output SRAM_OE_N,
	output SRAM_UB_N,
	output SRAM_WE_N,
	output [22:0] FL_ADDR,
	output FL_CE_N,
	inout [7:0] FL_DQ,
	output FL_OE_N,
	output FL_RST_N,
	input FL_RY,
	output FL_WE_N,
	output FL_WP_N,
	inout [35:0] GPIO,
	input HSMC_CLKIN_P1,
	input HSMC_CLKIN_P2,
	input HSMC_CLKIN0,
	output HSMC_CLKOUT_P1,
	output HSMC_CLKOUT_P2,
	output HSMC_CLKOUT0,
	inout [3:0] HSMC_D,
	input [16:0] HSMC_RX_D_P,
	output [16:0] HSMC_TX_D_P,
	inout [6:0] EX_IO
);

logic key0down, key1down, key2down, key3down;
logic CLK_12M, CLK_100K;
// logic CLK_800K;

// -----------------------------------------------------------------------------
// FFT audio analysis debug wires
// These two signals must be driven from Top.sv.
// Recommended source inside Top.sv:
//   o_fft_audio_sample = Recorder/DSP input sample, signed 16-bit audio
//   o_fft_audio_valid  = one-cycle valid pulse for that sample
// -----------------------------------------------------------------------------
(* keep = "true" *) logic signed [15:0] fft_audio_sample_w;
(* keep = "true" *) logic                 fft_audio_valid_w;


// FFT input-side debug wires
(* keep = "true" *) logic                 fft_sink_valid_w;
(* keep = "true" *) logic                 fft_sink_ready_w;
(* keep = "true" *) logic                 fft_sink_sop_w;
(* keep = "true" *) logic                 fft_sink_eop_w;
(* keep = "true" *) logic signed [15:0]   fft_sink_real_w;
(* keep = "true" *) logic signed [15:0]   fft_sink_imag_w;
(* keep = "true" *) logic [11:0]          fft_in_cnt_w;
(* keep = "true" *) logic                 fft_input_drop_w;

// -----------------------------------------------------------------------------
// FFT wrapper output wires
// -----------------------------------------------------------------------------

(* keep = "true" *) logic                 fft_bin_valid_w;
(* keep = "true" *) logic                 fft_bin_sop_w;
(* keep = "true" *) logic                 fft_bin_eop_w;
(* keep = "true" *) logic [11:0]          fft_bin_idx_w;
(* keep = "true" *) logic signed [15:0]   fft_real_w;
(* keep = "true" *) logic signed [15:0]   fft_imag_w;
(* keep = "true" *) logic [5:0]           fft_exp_w;
(* keep = "true" *) logic [1:0]           fft_source_error_w;

// -----------------------------------------------------------------------------
// FFT top4 detector output wires
// -----------------------------------------------------------------------------

logic                 peak_valid_w;

logic [11:0]          peak_bin_1_w;
logic [11:0]          peak_bin_2_w;
logic [11:0]          peak_bin_3_w;
logic [11:0]          peak_bin_4_w;

logic [16:0]          peak_freq_1_w;
logic [16:0]          peak_freq_2_w;
logic [16:0]          peak_freq_3_w;
logic [16:0]          peak_freq_4_w;


assign AUD_XCK = CLK_12M;

final_qsys pll0( // generate with qsys, please follow lab2 tutorials
	.clk_clk(CLOCK_50),
	.reset_reset_n(KEY[3]),
	.altpll_12m_clk(CLK_12M),
	.altpll_100k_clk(CLK_100K)
	//.altpll_800k_clk(CLK_800K)
);

// you can decide key down settings on your own, below is just an example
Debounce deb0(
	.i_in(KEY[0]), // Record/Pause
	.i_rst_n(KEY[3]),
	.i_clk(CLK_12M),
	.o_neg(key0down) 
);

Debounce deb1(
	.i_in(KEY[1]), // Play/Pause
	.i_rst_n(KEY[3]),
	.i_clk(CLK_12M),
	.o_neg(key1down) 
);

Debounce deb2(
	.i_in(KEY[2]), // Stop
	.i_rst_n(KEY[3]),
	.i_clk(CLK_12M),
	.o_neg(key2down) 
);

Top top0(
	.i_rst_n(KEY[3]),
	.i_clk(CLOCK_50),
	.i_key_0(key0down),
	.i_key_1(key1down),
	.i_key_2(key2down),
	.i_sw(SW[17:0]),

	// SRAM
	.o_SRAM_ADDR(SRAM_ADDR), // [19:0]
	.io_SRAM_DQ(SRAM_DQ), // [15:0]
	.o_SRAM_WE_N(SRAM_WE_N),
	.o_SRAM_CE_N(SRAM_CE_N),
	.o_SRAM_OE_N(SRAM_OE_N),
	.o_SRAM_LB_N(SRAM_LB_N),
	.o_SRAM_UB_N(SRAM_UB_N),
	
	// I2C
	.i_clk_100k(CLK_100K),
	.o_I2C_SCLK(I2C_SCLK),
	.io_I2C_SDAT(I2C_SDAT),

	// AudPlayer
	.i_AUD_ADCDAT(AUD_ADCDAT),
	.i_AUD_ADCLRCK(AUD_ADCLRCK),
	.i_AUD_BCLK(AUD_BCLK),
	.i_AUD_DACLRCK(AUD_DACLRCK),
	.o_AUD_DACDAT(AUD_DACDAT),

	// LED
	.o_ledg(LEDG), // [8:0]
	.o_ledr(LEDR), // [17:0]

	// For Debugging
	.o_l_cnt(l_cnt_10000),
	.o_r_cnt(r_cnt_10000),

	// FFT audio tap for SignalTap / analyzer debug.
	// You must add these two output ports in Top.sv and drive them from
	// your 16-bit audio sample stream and its valid signal.
	.o_fft_audio_sample(fft_audio_sample_w),
	.o_fft_audio_valid(fft_audio_valid_w)

	// LCD (optional display)
	// .i_clk_800k(CLK_800K),
	// .o_LCD_DATA(LCD_DATA), // [7:0]
	// .o_LCD_EN(LCD_EN),
	// .o_LCD_RS(LCD_RS),
	// .o_LCD_RW(LCD_RW),
	// .o_LCD_ON(LCD_ON),
	// .o_LCD_BLON(LCD_BLON),
);

// -----------------------------------------------------------------------------
// FFT wrapper for audio analysis debug
// Clock choice: use CLOCK_50 because Top currently receives CLOCK_50 as i_clk.
// If the exported sample/valid from Top.sv are in another clock domain, move this
// wrapper to that same clock domain or add a proper CDC bridge.
// -----------------------------------------------------------------------------
FFT_audio_wrapper #(.FFT_N(4096), .CNT_W(12)) u_fft_audio_wrapper (
	.i_clk          (CLOCK_50),
	.i_rst_n        (KEY[3]),

	.i_audio_sample (fft_audio_sample_w),
	.i_audio_valid  (fft_audio_valid_w),

	.o_sink_valid   (fft_sink_valid_w),
	.o_sink_ready   (fft_sink_ready_w),
	.o_sink_sop     (fft_sink_sop_w),
	.o_sink_eop     (fft_sink_eop_w),
	.o_sink_real    (fft_sink_real_w),
	.o_sink_imag    (fft_sink_imag_w),
	.o_in_cnt       (fft_in_cnt_w),
	.o_input_drop   (fft_input_drop_w),

	.o_bin_valid    (fft_bin_valid_w),
	.o_bin_sop      (fft_bin_sop_w),
	.o_bin_eop      (fft_bin_eop_w),
	.o_bin_idx      (fft_bin_idx_w),
	.o_fft_real     (fft_real_w),
	.o_fft_imag     (fft_imag_w),
	.o_fft_exp      (fft_exp_w),
	.o_source_error (fft_source_error_w)
);

fft_top4_detector #(
    .FFT_N       (4096),
    .SAMPLE_RATE (48000),
    .BIN_W       (12),
    .DATA_W      (16),
    .FREQ_W      (17)
) u_fft_top4_detector (
    .i_clk        (CLOCK_50),
    .i_rst_n      (KEY[3]),

    .i_bin_valid  (fft_bin_valid_w),
    .i_bin_sop    (fft_bin_sop_w),
    .i_bin_eop    (fft_bin_eop_w),
    .i_bin_idx    (fft_bin_idx_w),
    .i_fft_real   (fft_real_w),
    .i_fft_imag   (fft_imag_w),

    .o_peak_valid (peak_valid_w),

    .o_bin_1      (peak_bin_1_w),
    .o_bin_2      (peak_bin_2_w),
    .o_bin_3      (peak_bin_3_w),
    .o_bin_4      (peak_bin_4_w),

    .o_freq_1     (peak_freq_1_w),
    .o_freq_2     (peak_freq_2_w),
    .o_freq_3     (peak_freq_3_w),
    .o_freq_4     (peak_freq_4_w)
);

FFTPeakSevenDisplay u_fft_peak_seven_display (
    .i_sel_rank  (SW[1:0]),
    .i_show_freq (SW[2]),

    .i_bin_1     (peak_bin_1_w),
    .i_bin_2     (peak_bin_2_w),
    .i_bin_3     (peak_bin_3_w),
    .i_bin_4     (peak_bin_4_w),

    .i_freq_1    (peak_freq_1_w),
    .i_freq_2    (peak_freq_2_w),
    .i_freq_3    (peak_freq_3_w),
    .i_freq_4    (peak_freq_4_w),

    .o_HEX0      (HEX0),
    .o_HEX1      (HEX1),
    .o_HEX2      (HEX2),
    .o_HEX3      (HEX3),
    .o_HEX4      (HEX4),
    .o_HEX5      (HEX5),
    .o_HEX6      (HEX6),
    .o_HEX7      (HEX7)
);

// logic [3:0] sw_count;
// SevenHexDecoder seven_dec(
// 	.i_hex(sw_count),	// [3:0]
// 	.o_seven(HEX0) 		// [6:0]
// );

logic [3:0] l_cnt_10000, r_cnt_10000;
logic [3:0] l_cnt_0, l_cnt_1, r_cnt_0, r_cnt_1;

// assign l_cnt_0 = l_cnt_10000 % 10;
// assign l_cnt_1 = (l_cnt_10000 > 9) ? 3'd1 : 3'd0;
// assign r_cnt_0 = r_cnt_10000 % 10;
// assign r_cnt_1 = (r_cnt_10000 > 9) ? 3'd1 : 3'd0;

// SevenHexDecoder seven_dec4(
// 	.i_hex(l_cnt_0),	// [3:0]
// 	.o_seven(HEX4) 		// [6:0]
// );

// SevenHexDecoder seven_dec5(
// 	.i_hex(l_cnt_1),	// [3:0]
// 	.o_seven(HEX5) 
// );

// SevenHexDecoder seven_dec6(
// 	.i_hex(r_cnt_0),	// [3:0]
// 	.o_seven(HEX6) 
// );

// SevenHexDecoder seven_dec7(
// 	.i_hex(r_cnt_1),	// [3:0]
// 	.o_seven(HEX7) 
// );

// logic [11:0] display_bin_w;
// logic [16:0] display_freq_w;
// logic [16:0] display_value_w;

// always_comb begin
//     case (SW[1:0])
//         2'd0: begin
//             display_bin_w  = peak_bin_1_w;
//             display_freq_w = peak_freq_1_w;
//         end

//         2'd1: begin
//             display_bin_w  = peak_bin_2_w;
//             display_freq_w = peak_freq_2_w;
//         end

//         2'd2: begin
//             display_bin_w  = peak_bin_3_w;
//             display_freq_w = peak_freq_3_w;
//         end

//         2'd3: begin
//             display_bin_w  = peak_bin_4_w;
//             display_freq_w = peak_freq_4_w;
//         end

//         default: begin
//             display_bin_w  = peak_bin_1_w;
//             display_freq_w = peak_freq_1_w;
//         end
//     endcase
// end

// always_comb begin
//     if (SW[2])
//         display_value_w = display_freq_w;          // Hz
//     else
//         display_value_w = {5'd0, display_bin_w};   // bin number
// end


// comment those are use for display
// assign HEX0 = '1;
// assign HEX1 = '1;
// assign HEX2 = '1;
// assign HEX3 = '1;
// assign HEX4 = '1;
// assign HEX5 = '1;
// assign HEX6 = '1;
// assign HEX7 = '1;

endmodule
