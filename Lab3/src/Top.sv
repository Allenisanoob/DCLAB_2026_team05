
module Top (
	input i_rst_n,
	input i_clk,
	input i_key_0,
	input i_key_1,
	input i_key_2,
	input [2:0] i_speed, // design how user can decide mode on your own
	input i_fast,
	input i_slow_mode,
	input i_backward_mode,
	
	// AudDSP and SRAM
	output [19:0] o_SRAM_ADDR,
	inout  [15:0] io_SRAM_DQ,
	output        o_SRAM_WE_N,
	output        o_SRAM_CE_N,
	output        o_SRAM_OE_N,
	output        o_SRAM_LB_N,
	output        o_SRAM_UB_N,
	
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
	// LED state display
	output [15:0] o_state_led,
	output [7:0] o_state_led_volume

	// SEVENDECODER (optional display)
	// output [5:0] o_record_time,
	// output [5:0] o_play_time,

	// LCD (optional display)
	// input        i_clk_800k,
	// inout  [7:0] o_LCD_DATA,
	// output       o_LCD_EN,
	// output       o_LCD_RS,
	// output       o_LCD_RW,
	// output       o_LCD_ON,
	// output       o_LCD_BLON,

	// LED
	// output  [8:0] o_ledg,
	// output [17:0] o_ledr
);

// design the FSM and states as you like
parameter S_IDLE       = 0;
parameter S_I2C        = 1;
parameter S_RECD       = 2;
parameter S_RECD_PAUSE = 3;
parameter S_PLAY       = 4;
parameter S_PLAY_PAUSE = 5;
parameter S_STOP	   = 6;
parameter S_WAIT_R	   = 7; // wait for record
parameter S_WAIT_P	   = 8; // wait for play

logic i2c_oen, i2c_sdat;
logic [19:0] addr_record, addr_play;
logic signed [15:0] data_record, data_play, dac_data;
logic [3:0] state_r, state_w;
logic i2c_finished; // o_finished by I2cInitializer 
logic sram_we_record;

logic signed [15:0] current_signal, current_volume;

assign io_I2C_SDAT = (i2c_oen) ? i2c_sdat : 1'bz;

assign o_SRAM_ADDR = (state_r == S_RECD) ? addr_record : addr_play[19:0];
assign io_SRAM_DQ  = (state_r == S_RECD) ? data_record : 16'dz; // sram_dq as output
assign data_play   = (state_r != S_RECD) ? io_SRAM_DQ : 16'd0; // sram_dq as input

assign o_SRAM_WE_N = (state_r == S_RECD) ? sram_we_record : 1'b1;
assign o_SRAM_CE_N = 1'b0;
assign o_SRAM_OE_N = 1'b0;
assign o_SRAM_LB_N = 1'b0;
assign o_SRAM_UB_N = 1'b0;

assign o_state_led[0] = (state_r == S_I2C);
assign o_state_led[1] = (state_r == S_IDLE);
assign o_state_led[2] = (state_r == S_RECD);
assign o_state_led[3] = (state_r == S_RECD_PAUSE);
assign o_state_led[4] = (state_r == S_PLAY);
assign o_state_led[5] = (state_r == S_PLAY_PAUSE);
assign o_state_led[6] = (state_r == S_STOP);
assign o_state_led[7] = (state_r == S_WAIT_P);
assign o_state_led[8] = (state_r == S_WAIT_R);

assign current_signal = (state_r == S_RECD)? data_record :
						(state_r == S_PLAY)? data_play : 15'd0;
assign current_volume = (current_signal > 0) ? current_signal : -current_signal;

// Show volume in log scale on LED
assign o_state_led_volume[0] = (current_volume > 16'h0080);
assign o_state_led_volume[1] = (current_volume > 16'h0100);
assign o_state_led_volume[2] = (current_volume > 16'h0200);
assign o_state_led_volume[3] = (current_volume > 16'h0400);
assign o_state_led_volume[4] = (current_volume > 16'h0800);
assign o_state_led_volume[5] = (current_volume > 16'h1000);
assign o_state_led_volume[6] = (current_volume > 16'h2000);
assign o_state_led_volume[7] = (current_volume > 16'h4000);


// === I2cInitializer ===
// sequentially sent out settings to initialize WM8731 with I2C protocal
I2cInitializer init0(
	.i_rst_n(i_rst_n),
	.i_clk(i_clk_100k),
	.i_start(state_r == S_I2C), 
	.o_finished(i2c_finished),
	.o_sclk(o_I2C_SCLK),
	.o_sdat(i2c_sdat),
	.o_oen(i2c_oen) // you are outputing (you are not outputing only when you are "ack"ing.)

	// .dbg(dbg) // for debug, you can check which setting is being sent out
);

// === AudDSP ===
// responsible for DSP operations including fast play and slow play at different speed
// in other words, determine which data addr to be fetch for player 
AudDSP dsp0(
	.i_rst_n(i_rst_n),
	.i_clk(i_AUD_BCLK),
	.i_start(state_r == S_WAIT_P),
	.i_pause(i_key_1),
	.i_stop(state_r == S_STOP), 
	.i_speed(i_speed),
	.i_fast(i_fast),
	.i_slow_mode(i_slow_mode), // constant interpolation = 0, linear interpolation	= 1
	.i_backward_mode(i_backward_mode), // normal play = 0, backward play = 1
	.i_daclrck(i_AUD_DACLRCK),
	.i_sram_data(data_play),
	.i_stop_addr(addr_record),
	.o_dac_data(dac_data),
	.o_sram_addr(addr_play),
	.o_is_pause() // optional, you can use LED to indicate current state
);

// === AudPlayer ===
// receive data address from DSP and fetch data to sent to WM8731 with I2S protocal
AudPlayer player0(
	.i_rst_n(i_rst_n),
	.i_bclk(i_AUD_BCLK),
	.i_daclrck(i_AUD_DACLRCK),
	.i_en(!i_AUD_DACLRCK && state_r == S_PLAY), // enable AudPlayer only when playing audio, work with AudDSP
	.i_dac_data(dac_data), //dac_data
	.o_aud_dacdat(o_AUD_DACDAT)
);

// === AudRecorder ===
// receive data from WM8731 with I2S protocal and save to SRAM
AudRecorder recorder0(
	.i_rst_n(i_rst_n), 
	.i_clk(i_AUD_BCLK),
	.i_lrc(i_AUD_ADCLRCK),
	.i_start(state_r == S_WAIT_R),
	.i_pause(i_key_0),
	.i_stop((state_r == S_RECD || state_r == S_RECD_PAUSE) && i_key_2), 
	.i_data(i_AUD_ADCDAT),
	.o_address(addr_record),
	.o_data(data_record),
	.o_sram_we_n(sram_we_record)
);

always_comb begin
	// design your control here
	state_w = state_r;
	case (state_r)
        S_I2C: begin
            if(i2c_finished) state_w = S_IDLE;
        end
        S_IDLE: begin
            if(i_key_1) state_w = S_WAIT_P;  // Key1 Play
			if(i_key_0) state_w = S_WAIT_R;  // Key1 Play
        end
        S_RECD: begin
            if(i_key_0) state_w = S_RECD_PAUSE; // Key0 Pause recording
            if(i_key_1) state_w = S_WAIT_P;       // Key2 Stop Recording & transit to S_PLAY
			if(i_key_2) state_w = S_STOP;       // Key2 STOP and return to addr 0 
            if(!i_rst_n) state_w = S_IDLE;
        end
        S_RECD_PAUSE: begin
            if(i_key_0) state_w = S_RECD;       // Key0 Continue recording
            if(i_key_1) state_w = S_WAIT_P;       // Key2 transit to S_PLAY
			if(i_key_2) state_w = S_STOP;       // Key2 STOP and return to addr 0
            if(!i_rst_n) state_w = S_IDLE;
        end
		S_WAIT_R: begin
			if(i_key_0) state_w = S_RECD; 	   // Key0 Record
		end
		S_WAIT_P: begin
			if(i_key_1) state_w = S_PLAY;	   // Key1 Pause and resume play
		end
        S_PLAY: begin
            if(i_key_1) state_w = S_PLAY_PAUSE; // Key1 Pause
            if(i_key_2) state_w = S_STOP;       // Key2 STOP and return to addr 0 
            if(!i_rst_n) state_w = S_IDLE;
        end
        S_PLAY_PAUSE: begin
            if(i_key_1) state_w = S_PLAY;       // Key1 Resume
            if(i_key_2) state_w = S_STOP;       // Key2 STOP and return to addr 0 
            if(!i_rst_n) state_w = S_IDLE;
        end
        S_STOP: begin
            state_w = S_IDLE;                   // Return to IDLE, ready to Record or Play
        end
        default: state_w = S_IDLE;
    endcase
end


always_ff @(posedge i_clk or negedge i_rst_n) begin
	if (!i_rst_n) begin
        state_r <= S_I2C;  
    end
    else begin
        state_r <= state_w; 
    end
end

endmodule
