module Noise_Gate (
    input  i_clk,
    input  i_rst,

    input  i_prev_valid,
    input  signed [15:0] i_data,

    input  [7:0] i_rise_rate,      // in bits
    input  [7:0] i_decay_rate,     // in bits
    input  [15:0] i_hold,          // in samples
    input  [14:0] i_threshold_lo,  // unsigned Q0.15
    input  [14:0] i_threshold_hi,  // unsigned Q0.15

    output o_next_valid,
    output signed [15:0] o_data
);
    // Sample Rate Matching
    localparam S_IDLE    = 1'b0;
    localparam S_CALC    = 1'b1;

    // FSM States
    localparam S_NORMAL  = 2'b00;
    localparam S_HOLD    = 2'b01;
    localparam S_DECAY   = 2'b10;
    localparam S_RECOVER = 2'b11;

    // Input Data
    logic signed [15:0] i_data_w, i_data_r;

    // Output Data
    logic o_next_valid_w, o_next_valid_r;
    logic signed [15:0] o_data_w, o_data_r;

    assign o_data = o_data_r;
    assign o_next_valid = o_next_valid_r;

    // Misc. signals
    logic proc_state_w, proc_state_r;
    logic [1:0] state_w, state_r;
    logic [15:0] counter_w, counter_r;
    logic signed [15:0] current_gain_w, current_gain_r;    //Q1.15

    // Rate / target_gain control
    logic [7:0] rate;
    logic signed [15:0] target_gain;

    assign rate = (state_r == S_RECOVER) ? i_rise_rate :
                  (state_r == S_DECAY) ? i_decay_rate : '1;

    assign target_gain = (state_r == S_DECAY) ? 16'sd0 : 16'sd32767; // 1.0 in Q1.15 is 32767

    // Observed signals
    logic [14:0] current_volume;
    logic below_low, above_high;
    
    logic signed [15:0] abs_data;
    // Safely calculate absolute value using the registered data to prevent async glitches
    assign abs_data = i_data_r[15] ? -$signed(i_data_r) : i_data_r;
    // Cap to 32767 so -32768 doesn't overflow to 0
    assign current_volume = (abs_data[15]) ? 15'd32767 : abs_data[14:0];

    assign below_low  = (current_volume < i_threshold_lo);
    assign above_high = (current_volume > i_threshold_hi);

    // Output Data scaling
    logic signed [31:0] mult_result;
    assign mult_result = i_data_r * current_gain_r;

    // Use 32-bit math for gain difference to prevent 16-bit overflow during multiplication
    logic signed [31:0] diff_mult;
    assign diff_mult = (32'(target_gain) - 32'(current_gain_r)) * $signed({1'b0, rate});

    always_comb begin
        i_data_w = i_data_r;
        o_data_w = o_data_r;

        proc_state_w = proc_state_r;
        state_w = state_r;
        counter_w = counter_r;
        current_gain_w = current_gain_r;
        o_next_valid_w = 1'b0;

        case (proc_state_r)
            S_IDLE: begin
                if (i_prev_valid) begin
                    i_data_w = i_data;
                    proc_state_w = S_CALC;
                end
            end
            S_CALC: begin
                proc_state_w = S_IDLE;
                o_next_valid_w = 1'b1;
                o_data_w = mult_result >>> 15; // Shift right by 15 to adjust for Q1.15 gain format

                // Multiply difference by rate (0 ~ 255) first, then shift right arithmetically by 8 (devide by 256)
                current_gain_w = current_gain_r + (diff_mult >>> 8);
            
                case (state_r)
                    S_NORMAL: begin
                        if (below_low) begin
                            state_w = S_HOLD;
                            counter_w = '0;
                        end
                    end
                    S_HOLD: begin
                        counter_w = counter_r + 1;
                        if (above_high) begin
                            state_w = S_NORMAL;
                            counter_w = '0;
                        end
                        else if (counter_w >= i_hold) begin
                            state_w = S_DECAY;
                            counter_w = '0;
                        end
                    end
                    S_DECAY: begin
                        if (above_high) begin
                            state_w = S_RECOVER;
                        end
                    end
                    S_RECOVER: begin
                        counter_w = counter_r + 1;
                        if (counter_w >= i_hold) begin
                            state_w = S_NORMAL;
                            counter_w = '0;
                        end
                    end
                endcase
            end
        endcase
    end

    
    always_ff @(posedge i_clk or negedge i_rst) begin
        if (!i_rst) begin
            i_data_r       <= 16'sd0;
            o_data_r       <= 16'sd0;
            o_next_valid_r <= 1'b0;
            proc_state_r   <= S_IDLE;
            state_r        <= S_NORMAL;
            counter_r      <= 16'd0;
            current_gain_r <= 16'sd32767;
        end else begin
            i_data_r       <= i_data_w;
            o_data_r       <= o_data_w;
            o_next_valid_r <= o_next_valid_w;
            proc_state_r   <= proc_state_w;
            state_r        <= state_w;
            counter_r      <= counter_w;
            current_gain_r <= current_gain_w;
        end
    end

endmodule