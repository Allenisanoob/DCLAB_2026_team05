module Stager(
    input i_clk,
    input i_rst,

    input [] i_staging_control,

    input signed [15:0] i_raw_data,
    input i_raw_valid,

    input signed [15:0] i_block0_out,
    input signed [15:0] i_block1_out,
    input signed [15:0] i_block2_out,
    input signed [15:0] i_block3_out,
    input signed [15:0] i_block4_out,
    input signed [15:0] i_block5_out,  
    input signed [15:0] i_block6_out,
    input signed [15:0] i_block7_out,
    input signed [15:0] i_block8_out,

    input i_block0_valid_out,
    input i_block1_valid_out,
    input i_block2_valid_out,
    input i_block3_valid_out,
    input i_block4_valid_out,
    input i_block5_valid_out,
    input i_block6_valid_out,
    input i_block7_valid_out,
    input i_block8_valid_out,

    output signed [15:0] o_block0_in,
    output signed [15:0] o_block1_in,
    output signed [15:0] o_block2_in,
    output signed [15:0] o_block3_in,
    output signed [15:0] o_block4_in,
    output signed [15:0] o_block5_in,
    output signed [15:0] o_block6_in,
    output signed [15:0] o_block7_in,
    output signed [15:0] o_block8_in,

    output o_block0_valid_in,
    output o_block1_valid_in,
    output o_block2_valid_in,
    output o_block3_valid_in,
    output o_block4_valid_in,
    output o_block5_valid_in,
    output o_block6_valid_in,
    output o_block7_valid_in,
    output o_block8_valid_in,

    output signed [15:0] o_processed_data,
    output o_processed_valid
);


endmodule