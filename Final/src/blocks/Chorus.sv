module Chorus #(
    parameter integer delay_upper_bound = 2160,
    parameter integer delay_lower_bound = 720
)(
    input clk,
    input rst,
    input in_valid,
    input signed [15:0] in,
    input [6:0] inc, // Q4.3
//    input signed [7:0] gain, // Q1.7
    input signed [7:0] w_rate, // Q1.7
    output reg out_valid,
    output reg signed [15:0] out
);

localparam [$clog2(delay_upper_bound) - 1:0] delay_base = (delay_upper_bound + delay_lower_bound) / 2;
localparam [$clog2(delay_upper_bound) - 1:0] delay_amp  = (delay_upper_bound - delay_lower_bound) / 2;

logic out_valid_mae_pipe;
logic out_valid_ato_pipe;
logic signed [15:0] in_r;
logic        [6:0]  inc_r;
logic        [18:0] cos_input_temp; // Q16.3
logic signed [15:0] cos_output; // Q1.15
// logic signed [7:0] gain_r; // Q1.7
logic signed [7:0] w_rate_r; // Q1.7
logic [15:0] data_buffer [0:delay_upper_bound - 1];
logic [$clog2(delay_upper_bound) - 1:0] w_ptr;
logic [$clog2(delay_upper_bound) - 1:0] r_ptr;
logic signed [$clog2(delay_upper_bound) + 15 : 0] delay_skew;
logic signed [$clog2(delay_upper_bound) : 0] delay_skew_I;
logic [14:0] delay_skew_F, delay_skew_F_pipe;
logic [15:0] delay_skew_F_neg, delay_skew_F_neg_pipe;
logic signed [$clog2(delay_upper_bound) + 1: 0] delay_cnt_I;
logic is_loop;
logic is_write_1, is_write_2;
logic signed [15:0] data_temp_1, data_temp_2;
logic signed [15:0] data_delay_temp_1, data_delay_temp_2;
logic signed [31:0] data_delay_temp_3, data_delay_temp_4;
logic signed [32:0] data_delay_temp_5;
logic signed [17:0] data_delay_temp_6;
logic signed [15:0] data_delay, data_delay_pipe;
// logic signed [23:0] temp_1; // temp_1 = gain_r * data_delay // Q17.7
// logic signed [16:0] temp_2; // temp_2 = (temp_1 + 24'sd64) >>> 7 // Q17.0
// logic signed [17:0] data_curr_temp; // data_curr_temp = in + temp_2 // Q18.0
// logic signed [15:0] data_curr; // data_curr = saturate(data_curr_temp) // Q16.0
logic signed [7:0]  d_rate; // d_rate = 8'sd127 - w_rate; // Q1.7
logic signed [23:0] temp_3; // temp_3 = d_rate * in // 17.7
logic signed [23:0] temp_4; // temp_4 = w_rate * data_delay_pipe // Q17.7
logic signed [24:0] temp_5; // temp_5 = temp_3 + temp_4 // Q18.7
logic signed [17:0] out_curr; // out_curr = (temp_5 + 25'sd64) >>> 7 // Q18.0

cosine cosine_0 (.f(cos_input_temp[18:3]), .cos_2pif(cos_output));
assign delay_skew = $signed({1'b0, delay_amp}) * cos_output;
assign delay_skew_I = delay_skew >>> 15;
assign delay_skew_F = delay_skew[14:0];
assign delay_skew_F_neg = 16'h8000 - delay_skew_F;
assign delay_cnt_I = $signed({1'b0, delay_base}) + delay_skew_I;
assign r_ptr = (w_ptr >= delay_cnt_I) ? (w_ptr - delay_cnt_I) : (w_ptr + delay_upper_bound - delay_cnt_I);
assign is_write_1 = is_loop || (w_ptr >= delay_cnt_I + 1);
assign is_write_2 = is_loop || (w_ptr >= delay_cnt_I);
assign data_delay_temp_1 = is_write_1 ? data_temp_1 : 16'sd0;
assign data_delay_temp_2 = is_write_2 ? data_temp_2 : 16'sd0;
assign data_delay_temp_3 = $signed({1'b0, delay_skew_F_pipe}) * data_delay_temp_1;
assign data_delay_temp_4 = $signed({1'b0, delay_skew_F_neg_pipe}) * data_delay_temp_2;
assign data_delay_temp_5 = data_delay_temp_3 + data_delay_temp_4;
assign data_delay_temp_6 = (data_delay_temp_5 + 33'sd16384) >>> 15;
assign data_delay = data_delay_temp_6[15:0];
// assign temp_1 = gain_r * data_delay_pipe;
// assign temp_2 = (temp_1 + 24'sd64) >>> 7;
// assign data_curr_temp = in + temp_2;
// assign data_curr = (data_curr_temp > 18'sd32767) ? 18'sd32767 :
//                    (data_curr_temp < -18'sd32768) ? -18'sd32768 :
//                    data_curr_temp[15:0];
assign d_rate = 8'sd127 - w_rate_r;
assign temp_3 = d_rate * in_r;
assign temp_4 = w_rate_r * data_delay_pipe;
assign temp_5 = temp_3 + temp_4;
assign out_curr = (temp_5 + 25'sd64) >>> 7;

always_ff @(posedge clk or negedge rst) begin
    if (!rst) begin
        w_ptr <= 0;
        inc_r <= 0;
        cos_input_temp <= 0;
//         gain_r <= 0;
        w_rate_r <= 0;
        out_valid_mae_pipe <= 0;
        out_valid_ato_pipe <= 0;
        is_loop <= 0;
        delay_skew_F_pipe <= 0;
        delay_skew_F_neg_pipe <= 0;
        data_delay_pipe <= 0;
    end else begin
        inc_r <= inc;
//         gain_r <= gain;
        w_rate_r <= w_rate;
        if (in_valid) begin
            cos_input_temp <= cos_input_temp + inc_r;
            if (w_ptr == delay_upper_bound - 1) begin
                w_ptr <= 0;
                is_loop <= 1;
            end else begin
                w_ptr <= w_ptr + 1;
            end
            in_r <= in;
            data_buffer[w_ptr] <= in;
            out_valid_mae_pipe <= 1'b1;
        end else if (out_valid_mae_pipe) begin
            out <= out_curr[15:0];
            out_valid_mae_pipe <= 1'b0;
            out_valid <= 1'b1;
        end else if (out_valid) begin
            out_valid <= 1'b0;
            if (r_ptr != 0) data_temp_1 <= data_buffer[r_ptr - 1];
            else data_temp_1 <= data_buffer[delay_upper_bound - 1];
            data_temp_2 <= data_buffer[r_ptr];
            delay_skew_F_pipe <= delay_skew_F;
            delay_skew_F_neg_pipe <= delay_skew_F_neg;
            out_valid_ato_pipe <= 1'b1;
        end else if (out_valid_ato_pipe) begin
            data_delay_pipe <= data_delay;
            out_valid_ato_pipe <= 1'b0;
        end
    end
end

endmodule