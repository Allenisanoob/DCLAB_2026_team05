module Flanger #(
    parameter integer delay_upper_bound = 1152,
    parameter integer delay_lower_bound = 768
)(
    input clk,
    input rst,
    input in_valid,
    input signed [15:0] in,
    input [6:0] inc, // Q4.3
    input signed [7:0] gain, // Q1.7
    input signed [7:0] w_rate, // Q1.7
    output reg out_valid,
    output reg signed [15:0] out
);

localparam [$clog2(delay_upper_bound) - 1:0] delay_base = (delay_upper_bound + delay_lower_bound) / 2;
localparam [$clog2(delay_upper_bound) - 1:0] delay_amp  = (delay_upper_bound - delay_lower_bound) / 2;

logic out_valid_pipe;
logic signed [15:0] in_r;
logic        [6:0]  inc_r;
logic        [18:0] cos_input_temp; // Q16.3
logic signed [15:0] cos_output; // Q1.15
logic signed [7:0] gain_r; // Q1.7
logic signed [7:0] w_rate_r; // Q1.7
logic [15:0] data_buffer [0:delay_upper_bound - 1];
logic [$clog2(delay_upper_bound) - 1:0] w_ptr;
logic [$clog2(delay_upper_bound) - 1:0] r_ptr;
logic signed [$clog2(delay_upper_bound) + 15 : 0] delay_skew;
logic signed [$clog2(delay_upper_bound) + 1 : 0] delay_cnt_temp;
logic [$clog2(delay_upper_bound) - 1:0] delay_cnt;
logic is_loop;
logic is_write;
logic signed [15:0] temp_0;
logic signed [15:0] data_delay;
logic signed [23:0] temp_1; // temp_1 = gain_r * data_delay // Q17.7
logic signed [16:0] temp_2; // temp_2 = (temp_1 + 24'sd64) >>> 7 // Q17.0
logic signed [17:0] data_curr_temp; // data_curr_temp = in + temp_2 // Q18.0
logic signed [15:0] data_curr; // data_curr = saturate(data_curr_temp) // Q16.0
logic signed [15:0] data_curr_pipe;
logic signed [7:0]  d_rate; // d_rate = 8'sd127 - w_rate; // Q1.7
logic signed [23:0] temp_3; // temp_3 = d_rate * in // 17.7
logic signed [23:0] temp_4; // temp_4 = w_rate * data_curr_pipe // Q17.7
logic signed [24:0] temp_5; // temp_5 = temp_3 + temp_4 // Q18.7
logic signed [17:0] out_curr; // out_curr = (temp_5 + 25'sd64) >>> 7 // Q18.0

cosine cosine_0 (.f(cos_input_temp[18:3]), .cos_2pif(cos_output));
assign delay_skew = $signed({1'b0, delay_amp}) * cos_output;
assign delay_cnt_temp = $signed({1'b0, delay_base}) + (delay_skew >>> 15);
assign delay_cnt = delay_cnt_temp[$clog2(delay_upper_bound) - 1:0];
assign r_ptr = (w_ptr >= delay_cnt) ? (w_ptr - delay_cnt) : (w_ptr + delay_upper_bound - delay_cnt);
assign is_write = is_loop || (w_ptr >= delay_cnt);
assign data_delay = is_write ? temp_0 : 16'sd0;
assign temp_1 = gain_r * data_delay;
assign temp_2 = (temp_1 + 24'sd64) >>> 7;
assign data_curr_temp = in + temp_2;
assign data_curr = (data_curr_temp > 18'sd32767) ? 18'sd32767 :
                   (data_curr_temp < -18'sd32768) ? -18'sd32768 :
                   data_curr_temp[15:0];
assign d_rate = 8'sd127 - w_rate_r;
assign temp_3 = d_rate * in_r;
assign temp_4 = w_rate_r * data_curr_pipe;
assign temp_5 = temp_3 + temp_4;
assign out_curr = (temp_5 + 25'sd64) >>> 7;

always_ff @(posedge clk or negedge rst) begin
    if (!rst) begin
        w_ptr <= 0;
        inc_r <= 0;
        cos_input_temp <= 0;
        gain_r <= 0;
        w_rate_r <= 0;
        data_curr_pipe <= 0;
        out_valid_pipe <= 0;
        is_loop <= 0;
    end else begin
        inc_r <= inc;
        gain_r <= gain;
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
            data_buffer[w_ptr] <= data_curr;
            data_curr_pipe <= data_curr;
            out_valid_pipe <= 1'b1;
        end else if (out_valid_pipe) begin
            out <= out_curr[15:0];
            out_valid_pipe <= 1'b0;
            out_valid <= 1'b1;
        end else if (out_valid) begin
            out_valid <= 1'b0;
            temp_0 <= data_buffer[r_ptr];
        end
    end
end

endmodule