module Delay_Effect #(
    parameter [19:0] BASE_ADDR = 20'h00000 // Starting address of the 64K ring buffer
)(
    input  i_clk,
    input  i_rst,

    input  i_prev_valid,
    input  signed [15:0] i_data,

    input  [15:0] i_time,    // Delay duration in samples
    input  [7:0] i_feedback, // Feedback ratio (0 to 255, where 256 is 100%)
    input  [7:0] i_mix,      // Mix ratio      (0 to 255, where 256 is 100%)

    output logic o_next_valid,
    output logic signed [15:0] o_data,

    // SRAM read
    output logic [19:0] o_SRAM_r_addr,
    input  signed [15:0] i_SRAM_r_data,
    output logic o_read_req,
    input  i_read_valid,
    
    // SRAM write
    output logic [19:0] o_SRAM_w_addr,
    output logic signed [15:0] o_SRAM_w_data,
    output logic o_write_req
);

    // FSM States
    localparam S_IDLE      = 3'd0;
    localparam S_READ_REQ  = 3'd1;
    localparam S_WAIT_READ = 3'd2;
    localparam S_CALC      = 3'd3;
    localparam S_WRITE     = 3'd4;

    logic [2:0] state_r, state_w;
    logic [15:0] ptr_r, ptr_w;
    logic signed [15:0] i_data_r, i_data_w;
    logic signed [15:0] delayed_data_r, delayed_data_w;
    logic signed [15:0] o_data_r, o_data_w;
    logic signed [15:0] fb_data_r, fb_data_w;
    logic next_valid_r, next_valid_w;
    logic first_pass_r, first_pass_w;
    
    // Moved out of always_comb to prevent inferred latches!
    logic signed [31:0] feedback_val;
    logic signed [31:0] mix_val;
    logic signed [31:0] fb_temp;
    logic signed [31:0] mix_temp; 

    assign feedback_val = (32'(delayed_data_r) * $signed({1'b0, i_feedback})) >>> 8;
    assign mix_val      = (32'(delayed_data_r) * $signed({1'b0, i_mix})) >>> 8;
    assign fb_temp      = 32'(i_data_r) + feedback_val;
    assign mix_temp     = 32'(i_data_r) + mix_val;

    assign o_next_valid = next_valid_r;
    assign o_data = o_data_r;

    // Circular buffer: read address is simply the current pointer minus the delay time, offset by BASE_ADDR
    assign o_SRAM_r_addr = BASE_ADDR + {4'h0, 16'(ptr_r - i_time)}; 
    assign o_SRAM_w_addr = BASE_ADDR + {4'h0, ptr_r};

    always_comb begin
        state_w        = state_r;
        ptr_w          = ptr_r;
        i_data_w       = i_data_r;
        delayed_data_w = delayed_data_r;
        o_data_w       = o_data_r;
        fb_data_w      = fb_data_r;
        next_valid_w   = 1'b0; // Default to 0 pulse
        first_pass_w   = first_pass_r;

        o_read_req  = 1'b0;
        o_write_req = 1'b0;
        o_SRAM_w_data = fb_data_r; // Write the feedback mix back into the loop

        case (state_r)
            S_IDLE: begin
                if (i_prev_valid) begin
                    i_data_w = i_data;
                    state_w = S_READ_REQ;
                end
            end
            S_READ_REQ: begin
                o_read_req = 1'b1;
                state_w = S_WAIT_READ;
            end
            S_WAIT_READ: begin
                if (i_read_valid) begin
                    // If i_time is 0, ignore the delay.
                    // If on the first pass and ptr hasn't reached the delay time yet, output 0 to prevent SRAM garbage.
                    if (i_time == 16'd0 || (first_pass_r && ptr_r < i_time)) begin
                        delayed_data_w = 16'sd0;
                    end else begin
                        delayed_data_w = i_SRAM_r_data;
                    end
                    state_w = S_CALC;
                end
            end
            S_CALC: begin
                // Saturation logic to prevent clipping/overflow pops for output
                if (mix_temp > 32'sd32767) begin
                    o_data_w = 16'sd32767;
                end else if (mix_temp < -32'sd32768) begin
                    o_data_w = -16'sd32768;
                end else begin
                    o_data_w = mix_temp[15:0];
                end

                // Saturation logic for SRAM buffer (feedback)
                if (fb_temp > 32'sd32767) begin
                    fb_data_w = 16'sd32767;
                end else if (fb_temp < -32'sd32768) begin
                    fb_data_w = -16'sd32768;
                end else begin
                    fb_data_w = fb_temp[15:0];
                end
                state_w = S_WRITE;
            end
            S_WRITE: begin
                o_write_req = 1'b1;
                next_valid_w = 1'b1;
                if (ptr_r == 16'hFFFF) begin
                    first_pass_w = 1'b0; // First full buffer write is complete
                end
                ptr_w = ptr_r + 1'b1; // Step the circular buffer forward
                state_w = S_IDLE;
            end
        endcase
    end

    always_ff @(posedge i_clk or negedge i_rst) begin
        if (!i_rst) begin
            state_r        <= S_IDLE;
            ptr_r          <= 16'd0;
            i_data_r       <= 16'd0;
            delayed_data_r <= 16'd0;
            o_data_r       <= 16'd0;
            fb_data_r      <= 16'd0;
            next_valid_r   <= 1'b0;
            first_pass_r   <= 1'b1;
        end else begin
            state_r        <= state_w;
            ptr_r          <= ptr_w;
            i_data_r       <= i_data_w;
            delayed_data_r <= delayed_data_w;
            o_data_r       <= o_data_w;
            fb_data_r      <= fb_data_w;
            next_valid_r   <= next_valid_w;
            first_pass_r   <= first_pass_w;
        end
    end

endmodule