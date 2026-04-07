module Rsa256Core (
	input          i_clk,
	input          i_rst,
	input          i_start,
	input  [255:0] i_a, // cipher text y
	input  [255:0] i_d, // private key
	input  [255:0] i_n,
	output [255:0] o_a_pow_d, // plain text x
	output         o_finished
	// DEBUG PORT 
	//output [7:0]   o_progress 			
);

// operations for RSA256 decryption
// namely, the Montgomery algorithm

localparam IDLE      = 2'd0;
localparam WAIT_MP   = 2'd1;
localparam WAIT_MA   = 2'd2;
localparam INC_COUNT = 2'd3;

logic [255:0] o_mp1, o_ma1, o_ma2;
logic         done_mp1, done_ma1, done_ma2;
logic [1:0]   state_w, state_r;
logic [7:0]   counter_w, counter_r;
logic         start_ma_w, start_ma_r;
logic [255:0] temp_m_w, temp_m_r;
logic [255:0] temp_t_w, temp_t_r;
logic [255:0] o_a_pow_d_w, o_a_pow_d_r;
logic         o_finished_w, o_finished_r;
// DEBUG PORT 
//logic [7:0]   o_progress_r, o_progress_w; 		

logic         start_ma;
logic [255:0] temp_m, temp_t;

assign start_ma   = start_ma_r;
assign temp_m     = temp_m_r;
assign temp_t     = temp_t_r;
assign o_a_pow_d  = o_a_pow_d_r;
assign o_finished = o_finished_r;
// assign o_progress = counter_r;

ModuloProduct mp1(
	.i_clk(i_clk),
	.i_rst(i_rst),
	.i_start(i_start),
	.i_a(i_a),
	.i_n(i_n),
	.o_result(o_mp1),
	.o_done(done_mp1)
);

MontgomeryAlgorithm ma1(
	.clk(i_clk),
	.rst(i_rst),
	.start(start_ma),
	.A(temp_m),
	.B(temp_t),
	.N(i_n),
	.C(o_ma1),
	.done(done_ma1)
);

MontgomeryAlgorithm ma2(
	.clk(i_clk),
	.rst(i_rst),
	.start(start_ma),
	.A(temp_t),
	.B(temp_t),
	.N(i_n),
	.C(o_ma2),
	.done(done_ma2)
);

always_comb begin
	state_w      = state_r;
	counter_w    = counter_r;
	start_ma_w   = start_ma_r;
	temp_m_w     = temp_m_r;
	temp_t_w     = temp_t_r;
	o_a_pow_d_w  = o_a_pow_d_r;
	o_finished_w = o_finished_r;
	// DEBUG PORT 
//	o_progress_w = o_progress_r;


	case(state_r)
		IDLE: begin
			if (i_start) begin
				state_w      = WAIT_MP;
				counter_w    = 8'd0;
				start_ma_w   = 1'b0;
				temp_m_w     = 256'd0;
				temp_t_w     = 256'd0;
				o_a_pow_d_w  = 256'd0;
				// DEBUG PORT 
			//	o_progress_w = 1'b0;
				
			end
			o_finished_w = 1'b0;
		end

		WAIT_MP: begin
			if (done_mp1) begin
				state_w = WAIT_MA;
				start_ma_w = 1'b1;
				temp_m_w = 256'd1;
				temp_t_w = o_mp1;
			end
		end

		WAIT_MA: begin
			if (done_ma1 && done_ma2) begin
				if (i_d[counter_r]) begin
					temp_m_w = o_ma1;
				end
				temp_t_w = o_ma2;
				if (counter_r == 8'd255) begin
					state_w = IDLE;
					o_a_pow_d_w = temp_m_w;
					o_finished_w = 1'b1;
				end else begin
					state_w = INC_COUNT;
				end
			end
			start_ma_w = 1'b0;
		end

		INC_COUNT: begin
			state_w = WAIT_MA;
			counter_w = counter_r + 1;
			start_ma_w = 1'b1;
		end
	endcase
end

always_ff @(posedge i_clk or posedge i_rst) begin
	if (i_rst) begin
		state_r      <= IDLE;
		counter_r    <= 8'd0;
		start_ma_r   <= 1'b0;
		temp_m_r     <= 256'd0;
		temp_t_r     <= 256'd0;
		o_a_pow_d_r  <= 256'd0;
		o_finished_r <= 1'b0;
		// DEBUG PORT 
	//	o_progress   <= 1'b0;
	end else begin
		state_r      <= state_w;
		counter_r    <= counter_w;
		start_ma_r   <= start_ma_w;
		temp_m_r     <= temp_m_w;
		temp_t_r     <= temp_t_w;
		o_a_pow_d_r  <= o_a_pow_d_w;
		o_finished_r <= o_finished_w;
	end
end

endmodule

module ModuloProduct( // o_result = i_a * 2^256 mod i_n
	input          i_clk,
	input          i_rst,
	input          i_start,
	input  [255:0] i_a,
	input  [255:0] i_n,
	output [255:0] o_result,
	output         o_done
);

localparam IDLE = 1'd0;
localparam CALC = 1'd1;

logic         state_w, state_r;
logic [7:0]   counter_w, counter_r;
logic [256:0] temp_w, temp_r;
logic [255:0] o_result_r;
logic         o_done_w, o_done_r;

assign o_result = o_result_r;
assign o_done   = o_done_r;

always_comb begin
	state_w   = state_r;
	counter_w = counter_r;
	temp_w    = temp_r;
	o_done_w  = o_done_r;

	case(state_r)
		IDLE: begin
			if (i_start) begin
				state_w   = CALC;
				counter_w = 8'd0;
				temp_w    = {1'b0, i_a};
			end
			o_done_w  = 1'b0;
		end

		CALC: begin
			if ({temp_r[255:0], 1'b0} >= {1'b0, i_n}) begin
				temp_w = {temp_r[255:0], 1'b0} - {1'b0, i_n};
			end else begin
				temp_w = {temp_r[255:0], 1'b0};
			end

			if (counter_r == 8'd255) begin
				state_w = IDLE;
				counter_w = 8'd0;
				o_done_w = 1'b1;
			end else begin
				counter_w = counter_r + 1;
			end
		end
	endcase
end

always_ff @(posedge i_clk or posedge i_rst) begin
	if (i_rst) begin
		state_r    <= IDLE;
		counter_r  <= 8'd0;
		temp_r     <= 257'd0;
		o_result_r <= 256'd0;
		o_done_r   <= 1'b0;
	end else begin
		state_r   <= state_w;
		counter_r <= counter_w;
		temp_r    <= temp_w;
		o_done_r  <= o_done_w;
		if (state_r == CALC && counter_r == 8'd255) begin
			o_result_r <= temp_w[255:0];
		end
	end
end

endmodule

module MontgomeryAlgorithm(
	input          clk,
	input          rst,
	input          start,
	input  [255:0] A,
	input  [255:0] B,
	input  [255:0] N,
	output [255:0] C,
	output         done
);

localparam IDLE   = 2'd0;
localparam CALC_1 = 2'd1;	// calculate temp_1
localparam CALC_2 = 2'd2;	// calculate temp_2

logic [1:0]   state_w, state_r;
logic [7:0]   counter_w, counter_r;
logic [257:0] temp_w, temp_r;
logic [255:0] C_r;
logic         done_w, done_r;
logic [257:0] temp_1_r, temp_1_w; // pipeline	
logic [257:0] temp_2;			  // pipeline	

assign C    = C_r;
assign done = done_r;

always_comb begin
	state_w   = state_r;
	counter_w = counter_r;
	temp_w    = temp_r;
	done_w    = done_r;
	temp_1_w  = temp_r + ({2'b00, B} & {258{A[counter_r]}});
	temp_2    = temp_1_r + ({2'b00, N} & {258{temp_1_r[0]}});

	case(state_r)
		IDLE: begin
			if (start) begin
				state_w   = CALC_1;
				counter_w = 8'd0;
				temp_w    = 258'd0;
			end
			done_w = 1'b0;
		end

		CALC_1: begin
		// calculate temp_1_r
			// temp_1_w = temp_r + ({2'b00, B} & {258{A[counter_r]}});
			state_w  = CALC_2; // Next cycle into CALC_2
		end

		CALC_2: begin
		// use temp_1_r to get temp_2
			temp_w = temp_2 >> 1;

			if (counter_r == 8'd255) begin
				state_w = IDLE;
				done_w  = 1'b1;
			end else begin
				counter_w = counter_r + 1;
				state_w   = CALC_1; // back to stage 1
			end
		end
		
		default: state_w = IDLE;
	endcase
end

always_ff @(posedge clk or posedge rst) begin
	if (rst) begin
		state_r   <= IDLE;
		counter_r <= 8'd0;
		temp_r    <= 258'd0;
		temp_1_r  <= 258'd0; // Pipeline Reset
		C_r       <= 256'd0;
		done_r    <= 1'b0;
	end else begin
		state_r   <= state_w;
		counter_r <= counter_w;
		temp_r    <= temp_w;
		temp_1_r  <= temp_1_w; //Pipeline Renew
		done_r    <= done_w;

		if (state_r == CALC_2 && counter_r == 8'd255) begin
			if (temp_w >= {2'b00, N}) begin
				C_r <= temp_w - {2'b00, N};
			end else begin
				C_r <= temp_w[255:0];
			end
		end
	end
end

endmodule