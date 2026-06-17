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
    parameter signed [7:0] ap_gain_0 = 8'sd96, // Q1.7
    parameter signed [7:0] ap_gain_1 = 8'sd96, // Q1.7
    parameter signed [7:0] ap_gain_2 = 8'sd96, // Q1.7
    parameter signed [7:0] ap_gain_3 = 8'sd96, // Q1.7
    parameter signed [7:0] ap_gain_4 = 8'sd96, // Q1.7
    parameter [7:0] fdn_gain = 8'd128 // Q0.9
)(
    input clk,
    input rst,
    input in_valid,
    input signed [15:0] in,
    output out_valid,
    output signed [15:0] out
);

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

Schroeder_Allpass #(
    .delay_sample(ap_delay_sample_0),
    .gain(ap_gain_0)
) allpass_0 (
    .clk(clk),
    .rst(rst),
    .in_valid(in_valid),
    .in(in),
    .out_valid(in_valid_0),
    .out(out_ap_0)
);

Schroeder_Allpass #(
    .delay_sample(ap_delay_sample_1),
    .gain(ap_gain_1)
) allpass_1 (
    .clk(clk),
    .rst(rst),
    .in_valid(in_valid_0),
    .in(out_ap_0),
    .out_valid(in_valid_1),
    .out(out_ap_1)
);

Schroeder_Allpass #(
    .delay_sample(ap_delay_sample_2),
    .gain(ap_gain_2)
) allpass_2 (
    .clk(clk),
    .rst(rst),
    .in_valid(in_valid_1),
    .in(out_ap_1),
    .out_valid(in_valid_2),
    .out(out_ap_2)
);

Schroeder_Allpass #(
    .delay_sample(ap_delay_sample_3),
    .gain(ap_gain_3)
) allpass_3 (
    .clk(clk),
    .rst(rst),
    .in_valid(in_valid_2),
    .in(out_ap_2),
    .out_valid(in_valid_3),
    .out(out_ap_3)
);

Schroeder_Allpass #(
    .delay_sample(ap_delay_sample_4),
    .gain(ap_gain_4)
) allpass_4 (
    .clk(clk),
    .rst(rst),
    .in_valid(in_valid_3),
    .in(out_ap_3),
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
    .in_0(out_ap_4),
    .in_1(out_ap_4),
    .in_2(out_ap_4),
    .in_3(out_ap_4),
    .out_valid(out_valid),
    .out(out)
);

endmodule