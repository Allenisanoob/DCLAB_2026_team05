module Schroeder_Allpass #(
    parameter integer delay_sample = 2304,
    parameter signed [7:0] gain = 8'sd64 // Q1.7 (-1 ~ 1)
)(
    input clk,
    input rst,
    input in_valid,
    input signed [15:0] in,
    input signed [7:0] gain, // Q1.7
    output reg out_valid,
    output signed reg [15:0] out
);

logic [15:0] v_buffer [0:delay_sample - 1];
logic [$clog2(delay_sample) - 1:0] ptr;
logic is_loop;
logic signed [15:0] temp_0; // temp_0 = v_buffer[ptr] // Q15.0
logic signed [15:0] v_delay;
logic signed [23:0] temp_1; // temp_1 = gain * v_delay // Q17.7
logic signed [16:0] temp_2; // temp_2 = (temp_1 + 24'sd64) >>> 7 // Q16.0
logic signed [15:0] v_curr; // v_curr = in - temp_2 // Q15.0
logic signed [23:0] temp_3; // temp_3 = gain * v_curr // Q17.7
logic signed [15:0] temp_4; // temp_4 = (temp_3 + 24'sd64) >>> 7 // Q16.0
logic signed [15:0] out_curr; // out_curr = temp_4 + v_delay // Q15.0

assign v_delay = is_loop ? temp_0 : 16'sd0;
assign temp_1 = gain * v_delay;
assign temp_2 = (temp_1 + 24'sd64) >>> 7;
assign v_curr = in - temp_2;
assign temp_3 = gain * v_curr;
assign temp_4 = (temp_3 + 24'sd64) >>> 7;
assign out_curr = temp_4 + v_delay;

always_ff @(posedge clk or negedge rst) begin
    if (!rst) begin
        ptr <= 0;
        is_loop <= 0;
    end else if (in_valid) begin
        if (ptr == delay_sample - 1) begin
            ptr <= 0;
            is_loop <= 1;
        end else begin
            ptr <= ptr + 1;
        end
        v_buffer[ptr] <= v_curr;
        out <= out_curr;
        out_valid <= 1'b1;
    end else if (out_valid) begin
        out_valid <= 1'b0;
        temp_0 <= v_buffer[ptr];
    end
end

endmodule