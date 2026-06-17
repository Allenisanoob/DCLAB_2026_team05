module Stager(
    input i_clk,
    input i_rst,

    input [31:0] i_staging_control,

    input signed [15:0] i_raw_data,
    input i_raw_valid,

    input signed [15:0] i_block1_out,
    input signed [15:0] i_block2_out,
    input signed [15:0] i_block3_out,
    input signed [15:0] i_block4_out,
    input signed [15:0] i_block5_out,  
    input signed [15:0] i_block6_out,
    input signed [15:0] i_block7_out,
    input signed [15:0] i_block8_out,
    input signed [15:0] i_block9_out,

    input i_block1_valid_out,
    input i_block2_valid_out,
    input i_block3_valid_out,
    input i_block4_valid_out,
    input i_block5_valid_out,
    input i_block6_valid_out,
    input i_block7_valid_out,
    input i_block8_valid_out,
    input i_block9_valid_out,

    output signed [15:0] o_block1_in,
    output signed [15:0] o_block2_in,
    output signed [15:0] o_block3_in,
    output signed [15:0] o_block4_in,
    output signed [15:0] o_block5_in,
    output signed [15:0] o_block6_in,
    output signed [15:0] o_block7_in,
    output signed [15:0] o_block8_in,
    output signed [15:0] o_block9_in,

    output o_block1_valid_in,
    output o_block2_valid_in,
    output o_block3_valid_in,
    output o_block4_valid_in,
    output o_block5_valid_in,
    output o_block6_valid_in,
    output o_block7_valid_in,
    output o_block8_valid_in,
    output o_block9_valid_in,

    output signed [15:0] o_end_data,
    output o_end_valid
);

    localparam ADDR_OD = 8'd1;
    localparam ADDR_FZ = 8'd2;
    localparam ADDR_DT = 8'd3;
    localparam ADDR_RV = 8'd4;
    localparam ADDR_NG = 8'd5;
    localparam ADDR_DE = 8'd6;
    localparam ADDR_FG = 8'd7;
    localparam ADDR_CH = 8'd8;
    localparam ADDR_AW = 8'd9;

    logic [7:0] pos1_addr, pos2_addr, pos3_addr, pos4_addr;
    assign pos1_addr = i_staging_control[31:24];
    assign pos2_addr = (i_staging_control[23:16] != pos1_addr) ? i_staging_control[23:16] : 8'b0;
    assign pos3_addr = ((i_staging_control[15:8] != pos2_addr) & (i_staging_control[15:8] != pos1_addr)) ? i_staging_control[15:8] : 8'b0;
    assign pos4_addr = ((i_staging_control[7:0] != pos3_addr) & (i_staging_control[7:0] != pos2_addr) & (i_staging_control[7:0] != pos1_addr)) ? i_staging_control[7:0] : 8'b0;

    logic signed [15:0] data_bus_1, data_bus_2, data_bus_3;
    logic valid_bus_1, valid_bus_2, valid_bus_3;

    assign {o_block1_valid_in, o_block1_in} = (pos1_addr == ADDR_OD) ? {i_raw_valid, i_raw_data}
                                            : (pos2_addr == ADDR_OD) ? {valid_bus_1, data_bus_1}
                                            : (pos3_addr == ADDR_OD) ? {valid_bus_2, data_bus_2}
                                            : (pos4_addr == ADDR_OD) ? {valid_bus_3, data_bus_3} : {1'b0, 16'b0};
    assign {o_block2_valid_in, o_block2_in} = (pos1_addr == ADDR_FZ) ? {i_raw_valid, i_raw_data}
                                            : (pos2_addr == ADDR_FZ) ? {valid_bus_1, data_bus_1}
                                            : (pos3_addr == ADDR_FZ) ? {valid_bus_2, data_bus_2}
                                            : (pos4_addr == ADDR_FZ) ? {valid_bus_3, data_bus_3} : {1'b0, 16'b0};
    assign {o_block3_valid_in, o_block3_in} = (pos1_addr == ADDR_DT) ? {i_raw_valid, i_raw_data}
                                            : (pos2_addr == ADDR_DT) ? {valid_bus_1, data_bus_1}
                                            : (pos3_addr == ADDR_DT) ? {valid_bus_2, data_bus_2}
                                            : (pos4_addr == ADDR_DT) ? {valid_bus_3, data_bus_3} : {1'b0, 16'b0};
    assign {o_block4_valid_in, o_block4_in} = (pos1_addr == ADDR_RV) ? {i_raw_valid, i_raw_data}
                                            : (pos2_addr == ADDR_RV) ? {valid_bus_1, data_bus_1}
                                            : (pos3_addr == ADDR_RV) ? {valid_bus_2, data_bus_2}
                                            : (pos4_addr == ADDR_RV) ? {valid_bus_3, data_bus_3} : {1'b0, 16'b0};
    assign {o_block5_valid_in, o_block5_in} = (pos1_addr == ADDR_NG) ? {i_raw_valid, i_raw_data}
                                            : (pos2_addr == ADDR_NG) ? {valid_bus_1, data_bus_1}
                                            : (pos3_addr == ADDR_NG) ? {valid_bus_2, data_bus_2}
                                            : (pos4_addr == ADDR_NG) ? {valid_bus_3, data_bus_3} : {1'b0, 16'b0};
    assign {o_block6_valid_in, o_block6_in} = (pos1_addr == ADDR_DE) ? {i_raw_valid, i_raw_data}
                                            : (pos2_addr == ADDR_DE) ? {valid_bus_1, data_bus_1}
                                            : (pos3_addr == ADDR_DE) ? {valid_bus_2, data_bus_2}
                                            : (pos4_addr == ADDR_DE) ? {valid_bus_3, data_bus_3} : {1'b0, 16'b0};
    assign {o_block7_valid_in, o_block7_in} = (pos1_addr == ADDR_FG) ? {i_raw_valid, i_raw_data}
                                            : (pos2_addr == ADDR_FG) ? {valid_bus_1, data_bus_1}
                                            : (pos3_addr == ADDR_FG) ? {valid_bus_2, data_bus_2}
                                            : (pos4_addr == ADDR_FG) ? {valid_bus_3, data_bus_3} : {1'b0, 16'b0};
    assign {o_block8_valid_in, o_block8_in} = (pos1_addr == ADDR_CH) ? {i_raw_valid, i_raw_data}
                                            : (pos2_addr == ADDR_CH) ? {valid_bus_1, data_bus_1}
                                            : (pos3_addr == ADDR_CH) ? {valid_bus_2, data_bus_2}
                                            : (pos4_addr == ADDR_CH) ? {valid_bus_3, data_bus_3} : {1'b0, 16'b0};
    assign {o_block9_valid_in, o_block9_in} = (pos1_addr == ADDR_AW) ? {i_raw_valid, i_raw_data}
                                            : (pos2_addr == ADDR_AW) ? {valid_bus_1, data_bus_1}
                                            : (pos3_addr == ADDR_AW) ? {valid_bus_2, data_bus_2}
                                            : (pos4_addr == ADDR_AW) ? {valid_bus_3, data_bus_3} : {1'b0, 16'b0};

    assign {valid_bus_1, data_bus_1} = (pos1_addr == ADDR_OD) ? {i_block1_valid_out, i_block1_out}
                                     : (pos1_addr == ADDR_FZ) ? {i_block2_valid_out, i_block2_out}
                                     : (pos1_addr == ADDR_DT) ? {i_block3_valid_out, i_block3_out}
                                     : (pos1_addr == ADDR_RV) ? {i_block4_valid_out, i_block4_out}
                                     : (pos1_addr == ADDR_NG) ? {i_block5_valid_out, i_block5_out}
                                     : (pos1_addr == ADDR_DE) ? {i_block6_valid_out, i_block6_out}
                                     : (pos1_addr == ADDR_FG) ? {i_block7_valid_out, i_block7_out}
                                     : (pos1_addr == ADDR_CH) ? {i_block8_valid_out, i_block8_out}
                                     : (pos1_addr == ADDR_AW) ? {i_block9_valid_out, i_block9_out} : {i_raw_valid, i_raw_data};
    assign {valid_bus_2, data_bus_2} = (pos2_addr == ADDR_OD) ? {i_block1_valid_out, i_block1_out}
                                     : (pos2_addr == ADDR_FZ) ? {i_block2_valid_out, i_block2_out}
                                     : (pos2_addr == ADDR_DT) ? {i_block3_valid_out, i_block3_out}
                                     : (pos2_addr == ADDR_RV) ? {i_block4_valid_out, i_block4_out}
                                     : (pos2_addr == ADDR_NG) ? {i_block5_valid_out, i_block5_out}
                                     : (pos2_addr == ADDR_DE) ? {i_block6_valid_out, i_block6_out}
                                     : (pos2_addr == ADDR_FG) ? {i_block7_valid_out, i_block7_out}
                                     : (pos2_addr == ADDR_CH) ? {i_block8_valid_out, i_block8_out}
                                     : (pos2_addr == ADDR_AW) ? {i_block9_valid_out, i_block9_out} : {valid_bus_1, data_bus_1};
    assign {valid_bus_3, data_bus_3} = (pos3_addr == ADDR_OD) ? {i_block1_valid_out, i_block1_out}
                                     : (pos3_addr == ADDR_FZ) ? {i_block2_valid_out, i_block2_out}
                                     : (pos3_addr == ADDR_DT) ? {i_block3_valid_out, i_block3_out}
                                     : (pos3_addr == ADDR_RV) ? {i_block4_valid_out, i_block4_out}
                                     : (pos3_addr == ADDR_NG) ? {i_block5_valid_out, i_block5_out}
                                     : (pos3_addr == ADDR_DE) ? {i_block6_valid_out, i_block6_out}
                                     : (pos3_addr == ADDR_FG) ? {i_block7_valid_out, i_block7_out}
                                     : (pos3_addr == ADDR_CH) ? {i_block8_valid_out, i_block8_out}
                                     : (pos3_addr == ADDR_AW) ? {i_block9_valid_out, i_block9_out} : {valid_bus_2, data_bus_2};
    assign {o_end_valid, o_end_data} = (pos4_addr == ADDR_OD) ? {i_block1_valid_out, i_block1_out}
                                     : (pos4_addr == ADDR_FZ) ? {i_block2_valid_out, i_block2_out}
                                     : (pos4_addr == ADDR_DT) ? {i_block3_valid_out, i_block3_out}
                                     : (pos4_addr == ADDR_RV) ? {i_block4_valid_out, i_block4_out}
                                     : (pos4_addr == ADDR_NG) ? {i_block5_valid_out, i_block5_out}
                                     : (pos4_addr == ADDR_DE) ? {i_block6_valid_out, i_block6_out}
                                     : (pos4_addr == ADDR_FG) ? {i_block7_valid_out, i_block7_out}
                                     : (pos4_addr == ADDR_CH) ? {i_block8_valid_out, i_block8_out}
                                     : (pos4_addr == ADDR_AW) ? {i_block9_valid_out, i_block9_out} : {valid_bus_3, data_bus_3};

endmodule