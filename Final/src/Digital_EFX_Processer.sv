module Top (
	input i_rst_n,
	input i_clk,
	input i_key_0,
	input i_key_1,
	input i_key_2,
	input [17:0] i_sw,

	input  [255:0] i_uart_command,
    input          i_uart_valid,

	
	// // SRAM
	// output [19:0] o_SRAM_ADDR,
	// inout  [15:0] io_SRAM_DQ,
	// output        o_SRAM_WE_N,
	// output        o_SRAM_CE_N,
	// output        o_SRAM_OE_N,
	// output        o_SRAM_LB_N,
	// output        o_SRAM_UB_N,
	
	// I2C
	input  i_clk_100k,
	output o_I2C_SCLK,
	inout  io_I2C_SDAT,
	
	// AudPlayer
	input  i_AUD_ADCDAT,
	inout  i_AUD_ADCLRCK,
	inout  i_AUD_BCLK,
	inout  i_AUD_DACLRCK,
	output o_AUD_DACDAT,

	// LED
	output [8:0]  o_ledg,
	output [17:0] o_ledr,

	// For Debugging
	output [3:0] o_l_cnt,
	output [3:0] o_r_cnt,
	output [3:0] o_simul_cnt


	// LCD (optional display)
	// input        i_clk_800k,
	// inout  [7:0] o_LCD_DATA,
	// output       o_LCD_EN,
	// output       o_LCD_RS,
	// output       o_LCD_RW,
	// output       o_LCD_ON,
	// output       o_LCD_BLON,
);

	// FSM States
	localparam S_SETUP = 2'b00;
	localparam S_MENU  = 2'b01; // To be implemented

	// Misc. signals
	logic [1:0] state_r, state_w;
	logic [15:0] current_volume; // For LED display

	// Main chain connections
	logic R2D_valid, D2B_valid, B2P_request_l, B2P_request_r;
	logic signed [15:0] raw_data, buf_data_l, buf_data_r, out_data;

	// // SRAM connections
	// logic [19:0] sram_addr;
	// logic signed [15:0] sram_r_data, sram_w_data;
	// logic sram_we_n;

	// assign o_SRAM_ADDR = sram_addr;
	// assign io_SRAM_DQ  = (!sram_we_n) ? sram_w_data : 16'bz;
	// assign sram_r_data = (!sram_we_n) ? 16'b0 : io_SRAM_DQ;

	// assign o_SRAM_WE_N = sram_we_n;
	// assign o_SRAM_CE_N = 1'b0;
	// assign o_SRAM_OE_N = 1'b0;
	// assign o_SRAM_LB_N = 1'b0;
	// assign o_SRAM_UB_N = 1'b0;

	// Show volume in log scale on LEDG
	// assign current_volume = (raw_data[15]) ? -raw_data : raw_data;
	// assign current_volume = (buf_data_l[15]) ? -buf_data_l : buf_data_l;
	// assign current_volume = (buf_data_r[15]) ? -buf_data_r : buf_data_r;
	assign current_volume = (out_data[15]) ? -out_data : out_data;

	assign o_ledg[0] = (current_volume > 16'h0080);
	assign o_ledg[1] = (current_volume > 16'h0100);
	assign o_ledg[2] = (current_volume > 16'h0200);
	assign o_ledg[3] = (current_volume > 16'h0400);
	assign o_ledg[4] = (current_volume > 16'h0800);
	assign o_ledg[5] = (current_volume > 16'h1000);
	assign o_ledg[6] = (current_volume > 16'h2000);
	assign o_ledg[7] = (current_volume > 16'h4000);
	assign o_ledg[8] = 1'b0;

	// Show the current state on LEDR
	assign o_ledr[17] = (state_r == S_SETUP);
	assign o_ledr[16] = (state_r == S_MENU);

	logic [15:0] dsp_ledr;
	assign o_ledr[15:0] = dsp_ledr;



	// WM8731 Initializer
	// TODO: configure mic/line input on flight
	logic wm_start, wm_finished;
	logic i2c_oen, i2c_sdat;
	assign io_I2C_SDAT = (i2c_oen) ? i2c_sdat : 1'bz;
	assign wm_start = (state_r == S_SETUP);

	WM8731_init wm8731_init (
		.i_rst_n(i_rst_n),
		.i_clk(i_clk_100k),
		.i_start(wm_start),
		.o_finished(wm_finished),
		.o_sclk(o_I2C_SCLK),
		.o_sdat(i2c_sdat),
		.o_oen(i2c_oen)
	);

	// Recorder
	Recorder recorder (
		.i_rst(i_rst_n),
		.i_BCLK(i_AUD_BCLK),
		.i_ADC_LRCK(i_AUD_ADCLRCK),
		.i_ADC_DAT(i_AUD_ADCDAT),
		.o_raw_data(raw_data),
		.o_R2D_valid(R2D_valid)
	);

	// // SRAM Connections
	// logic [19:0] B0_r_addr, B0_w_addr, B1_r_addr, B1_w_addr, B2_r_addr, B2_w_addr, B3_r_addr, B3_w_addr;
	// logic signed [15:0] B0_r_data, B0_w_data, B1_r_data, B1_w_data, B2_r_data, B2_w_data, B3_r_data, B3_w_data;
	// logic B0_read_req, B0_write_req, B1_read_req, B1_write_req, B2_read_req, B2_write_req, B3_read_req, B3_write_req;
	// logic B0_read_valid, B1_read_valid, B2_read_valid, B3_read_valid;

	// DSP Chain
	DSP dsp (
		// Main chain I/O
		.i_rst(i_rst_n),
		.i_clk(i_clk),
		.i_R2D_valid(R2D_valid),
		.i_raw_data(raw_data),
		.o_D2B_valid(D2B_valid),
		.o_buf_data_l(buf_data_l),
		.o_buf_data_r(buf_data_r),
		.i_fx_sw(i_sw),

		// UART
		.i_uart_command(i_uart_command),
		.i_uart_valid(i_uart_valid),


		// // SRAM I/O for 4 blocks (B0-B3)
		// .o_B0_r_addr(B0_r_addr),
		// .i_B0_r_data(B0_r_data),
		// .o_B0_read_req(B0_read_req),
		// .i_B0_read_valid(B0_read_valid),
		// .o_B0_w_addr(B0_w_addr),
		// .o_B0_w_data(B0_w_data),
		// .o_B0_write_req(B0_write_req),

		// .o_B1_r_addr(B1_r_addr),
		// .i_B1_r_data(B1_r_data),
		// .o_B1_read_req(B1_read_req),
		// .i_B1_read_valid(B1_read_valid),
		// .o_B1_w_addr(B1_w_addr),
		// .o_B1_w_data(B1_w_data),
		// .o_B1_write_req(B1_write_req),

		// .o_B2_r_addr(B2_r_addr),
		// .i_B2_r_data(B2_r_data),
		// .o_B2_read_req(B2_read_req),
		// .i_B2_read_valid(B2_read_valid),
		// .o_B2_w_addr(B2_w_addr),
		// .o_B2_w_data(B2_w_data),
		// .o_B2_write_req(B2_write_req),

		// .o_B3_r_addr(B3_r_addr),
		// .i_B3_r_data(B3_r_data),
		// .o_B3_read_req(B3_read_req),
		// .i_B3_read_valid(B3_read_valid),
		// .o_B3_w_addr(B3_w_addr),
		// .o_B3_w_data(B3_w_data),
		// .o_B3_write_req(B3_write_req),

		// .i_sram_ready(sram_ready),
		.o_dsp_ledr(dsp_ledr)
	);

	// Buffer
	Buffer buffer (
		.i_clk(i_clk),
		.i_rst(i_rst_n),
		.i_buf_data_l(buf_data_l),
		.i_buf_data_r(buf_data_r),
		.i_D2B_valid(D2B_valid),
		.i_B2P_request_l(B2P_request_l),
		.i_B2P_request_r(B2P_request_r),
		.o_data(out_data),

		.o_l_cnt(o_l_cnt),
		.o_r_cnt(o_r_cnt),
		.o_simul_cnt(o_simul_cnt)
	);

	// Player
	Player player (
		.i_rst(i_rst_n),
		.i_BCLK(i_AUD_BCLK),
		.i_DAC_LRCK(i_AUD_DACLRCK),
		.i_out_data(out_data),
		.o_DAC_DAT(o_AUD_DACDAT),
		.o_B2P_request_l(B2P_request_l),
		.o_B2P_request_r(B2P_request_r)
	);

	// // SRAM Scheduler
	// logic sram_ready;
	// SRAM_Scheduler sram_scheduler (
	// 	.i_clk(i_clk),
	// 	.i_rst(i_rst_n),

	// 	.i_B0_r_addr(B0_r_addr),
	// 	.o_B0_r_data(B0_r_data),
	// 	.i_B0_read_req(B0_read_req),
	// 	.o_B0_read_valid(B0_read_valid),
	// 	.i_B0_w_addr(B0_w_addr),
	// 	.i_B0_w_data(B0_w_data),
	// 	.i_B0_write_req(B0_write_req),

	//  	.i_B1_r_addr(B1_r_addr),
	//  	.o_B1_r_data(B1_r_data),
	//  	.i_B1_read_req(B1_read_req),
	//  	.o_B1_read_valid(B1_read_valid),
	//  	.i_B1_w_addr(B1_w_addr),
	//  	.i_B1_w_data(B1_w_data),
	//  	.i_B1_write_req(B1_write_req),

	//  	.i_B2_r_addr(B2_r_addr),
	//  	.o_B2_r_data(B2_r_data),
	//  	.i_B2_read_req(B2_read_req),
	//  	.o_B2_read_valid(B2_read_valid),
	//  	.i_B2_w_addr(B2_w_addr),
	//  	.i_B2_w_data(B2_w_data),
	//  	.i_B2_write_req(B2_write_req),

	//  	.i_B3_r_addr(B3_r_addr),
	//  	.o_B3_r_data(B3_r_data),
	//  	.i_B3_read_req(B3_read_req),
	//  	.o_B3_read_valid(B3_read_valid),
	//  	.i_B3_w_addr(B3_w_addr),
	//  	.i_B3_w_data(B3_w_data),
	//  	.i_B3_write_req(B3_write_req),

	//  	.i_sram_data(sram_r_data),
	//  	.o_sram_addr(sram_addr),
	//  	.o_sram_data(sram_w_data),
	//  	.o_sram_we_n(sram_we_n),

	//  	.o_ready(sram_ready) // scheduler is not full
	// );

	// Combinational logic
	always_comb begin
		state_w = state_r;
		case (state_r)
			S_SETUP: begin
				if (wm_finished) state_w = S_MENU; // To be implemented
			end
			S_MENU: begin
				if (i_key_0) state_w = S_SETUP; // Reset to setup
			end
			default: state_w = S_SETUP;
		endcase
	end

	// Sequential logic
	always_ff @(posedge i_clk or negedge i_rst_n) begin
		if (!i_rst_n) begin
			state_r <= S_SETUP;
		end else begin
			state_r <= state_w;
		end
	end

	// // Switch Debugging
	// logic [3:0] sw_count_w, sw_count_r;
	// logic sw_on;
	// assign o_sw_count = sw_count_r;
	// assign sw_on = (i_sw[0] || i_sw[1] || i_sw[2] || i_sw[3] || i_sw[4] || i_sw[5]);

	// always_comb begin
	// 	if (sw_on) begin
	// 		sw_count_w = sw_count_r + 1;
	// 	end else begin
	// 		sw_count_w = 0;
	// 	end
	// end

	// always_ff @(posedge i_clk or negedge i_rst_n) begin
	// 	if (!i_rst_n) begin
	// 		sw_count_r <= 0;
	// 	end else begin
	// 		sw_count_r <= sw_count_w;
	// 	end
	// end

endmodule