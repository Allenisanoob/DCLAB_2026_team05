module Reverb #(
    parameter integer ap_delay_sample_0 = 1423,
    parameter integer ap_delay_sample_1 = 1787,
    parameter integer ap_delay_sample_2 = 2131,
    parameter integer ap_delay_sample_3 = 2531,
    parameter integer ap_delay_sample_4 = 2663,
    parameter integer fdn_delay_sample_0 = 1423,
    parameter integer fdn_delay_sample_1 = 1787,
    parameter integer fdn_delay_sample_2 = 2131,
    parameter integer fdn_delay_sample_3 = 2531,
    parameter signed [7:0] fdn_gain = 8'sd80 // Q1.7
)(
    input clk,
    input rst,
    input in_valid,
    input signed [15:0] in,
    input signed [7:0] w_rate, // Q1.7
    input signed [7:0] ap_gain_0,
    input signed [7:0] ap_gain_1,
    input signed [7:0] ap_gain_2,
    input signed [7:0] ap_gain_3,
    input signed [7:0] ap_gain_4,
    output reg out_valid,
    output reg signed [15:0] out
);

logic signed [15:0] in_r;
logic signed [7:0] w_rate_r;
logic signed [7:0] d_rate;
logic in_valid_0;
logic in_valid_1;
logic in_valid_2;
logic in_valid_3;
logic in_valid_4;
logic signed [15:0] out_ap_0;
logic signed [15:0] out_ap_1;
logic signed [15:0] out_ap_2;
logic signed [15:0] out_ap_3;
logic signed [15:0] out_ap_4;
logic fdn_out_valid;
logic signed [15:0] fdn_out;
logic signed [24:0] out_temp_0;
logic signed [17:0] out_temp_1;

assign d_rate = 8'sd127 - w_rate_r;
assign out_temp_0 = w_rate_r * fdn_out + d_rate * in_r;
assign out_temp_1 = (out_temp_0 + 25'sd64) >>> 7;

always_ff @(posedge clk or negedge rst) begin
    if (!rst) begin
        in_r <= 16'sd0;
        w_rate_r <= 8'sd0;
    end else begin
        w_rate_r <= w_rate;
        if (in_valid) in_r <= in;
        if (fdn_out_valid) begin
            out_valid <= 1'b1;
            out <= out_temp_1[15:0];
        end else begin
            out_valid <= 1'b0;
        end
    end
end

Schroeder_Allpass #(
    .delay_sample(ap_delay_sample_0)
) allpass_0 (
    .clk(clk),
    .rst(rst),
    .in_valid(in_valid),
    .in(in),
    .gain(ap_gain_0),
    .out_valid(in_valid_0),
    .out(out_ap_0)
);

Schroeder_Allpass #(
    .delay_sample(ap_delay_sample_1)
) allpass_1 (
    .clk(clk),
    .rst(rst),
    .in_valid(in_valid_0),
    .in(out_ap_0),
    .gain(ap_gain_1),
    .out_valid(in_valid_1),
    .out(out_ap_1)
);

Schroeder_Allpass #(
    .delay_sample(ap_delay_sample_2)
) allpass_2 (
    .clk(clk),
    .rst(rst),
    .in_valid(in_valid_1),
    .in(out_ap_1),
    .gain(ap_gain_2),
    .out_valid(in_valid_2),
    .out(out_ap_2)
);

Schroeder_Allpass #(
    .delay_sample(ap_delay_sample_3)
) allpass_3 (
    .clk(clk),
    .rst(rst),
    .in_valid(in_valid_2),
    .in(out_ap_2),
    .gain(ap_gain_3),
    .out_valid(in_valid_3),
    .out(out_ap_3)
);

Schroeder_Allpass #(
    .delay_sample(ap_delay_sample_4)
) allpass_4 (
    .clk(clk),
    .rst(rst),
    .in_valid(in_valid_3),
    .in(out_ap_3),
    .gain(ap_gain_4),
    .out_valid(in_valid_4),
    .out(out_ap_4)
);

FDN_4ch #(
    .delay_sample_0(fdn_delay_sample_0),
    .delay_sample_1(fdn_delay_sample_1),
    .delay_sample_2(fdn_delay_sample_2),
    .delay_sample_3(fdn_delay_sample_3),
    .gain(fdn_gain)
) fdn (
    .clk(clk),
    .rst(rst),
    .in_valid(in_valid_4),
    .in(out_ap_4),
    .out_valid(fdn_out_valid),
    .out(fdn_out)
);



endmodule