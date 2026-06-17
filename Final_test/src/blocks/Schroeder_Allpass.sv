module Schroeder_Allpass #(
    parameter integer delay_sample = 2304
)(
    input clk,
    input rst,
    input in_valid,
    input signed [15:0] in,
    input signed [7:0] gain, // Q1.7
    output reg out_valid,
    output reg signed [15:0] out
);

logic signed [7:0] gain_r;
logic out_valid_pipe;

logic [15:0] v_buffer [0:delay_sample - 1];
logic [$clog2(delay_sample) - 1:0] ptr;
logic is_loop;
logic signed [15:0] temp_0; // temp_0 = v_buffer[ptr] // Q16.0
logic signed [15:0] v_delay; // Q16.0
logic signed [23:0] temp_1; // temp_1 = gain * v_delay // Q17.7
logic signed [16:0] temp_2; // temp_2 = (temp_1 + 24'sd64) >>> 7 // Q17.0
logic signed [17:0] v_curr_temp; // v_curr_temp = in - temp_2 // Q18.0
logic signed [15:0] v_curr; // v_curr = saturate(v_curr_temp) // Q16.0
logic signed [15:0] v_curr_pipe;
logic signed [23:0] temp_3; // temp_3 = gain * v_curr // Q17.7
logic signed [16:0] temp_4; // temp_4 = (temp_3 + 24'sd64) >>> 7 // Q17.0
logic signed [17:0] out_curr_temp; // out_curr_temp = temp_4 + v_delay // Q18.0
logic signed [15:0] out_curr; // out_curr = saturate(out_curr_temp) // Q16.0

assign v_delay = is_loop ? temp_0 : 16'sd0;
assign temp_1 = gain_r * v_delay;
assign temp_2 = (temp_1 + 24'sd64) >>> 7;
assign v_curr_temp = in - temp_2;
assign v_curr = (v_curr_temp > 18'sd32767) ? 18'sd32767 :
                (v_curr_temp < -18'sd32768) ? -18'sd32768 :
                v_curr_temp[15:0];
assign temp_3 = gain_r * v_curr_pipe;
assign temp_4 = (temp_3 + 24'sd64) >>> 7;
assign out_curr_temp = temp_4 + v_delay;
assign out_curr = (out_curr_temp > 18'sd32767) ? 18'sd32767 :
                  (out_curr_temp < -18'sd32768) ? -18'sd32768 :
                  out_curr_temp[15:0];

always_ff @(posedge clk or negedge rst) begin
    if (!rst) begin
        ptr <= 0;
        is_loop <= 0;
        gain_r <= 0;
        out_valid_pipe <= 1'b0;
        v_curr_pipe <= 16'sd0;
    end else if (in_valid) begin
        gain_r <= gain;
        if (ptr == delay_sample - 1) begin
            ptr <= 0;
            is_loop <= 1;
        end else begin
            ptr <= ptr + 1;
        end
        v_buffer[ptr] <= v_curr;
        v_curr_pipe <= v_curr;
        out_valid_pipe <= 1'b1;
    end else if (out_valid_pipe) begin
        out <= out_curr;
        out_valid <= 1'b1;
        out_valid_pipe <= 1'b0;
    end else if (out_valid) begin
        gain_r <= gain;
        out_valid <= 1'b0;
        temp_0 <= v_buffer[ptr];
    end else begin
        gain_r <= gain;
    end
end

endmodule