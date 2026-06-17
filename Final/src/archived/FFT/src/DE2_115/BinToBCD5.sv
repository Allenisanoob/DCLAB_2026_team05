module BinToBCD5 #(
    parameter int BIN_W = 17
)(
    input  logic [BIN_W-1:0] i_bin,

    output logic [3:0] o_digit0, // ones
    output logic [3:0] o_digit1, // tens
    output logic [3:0] o_digit2, // hundreds
    output logic [3:0] o_digit3, // thousands
    output logic [3:0] o_digit4  // ten-thousands
);

    logic [BIN_W+20-1:0] shift_reg;

    always_comb begin
        shift_reg = '0;
        shift_reg[BIN_W-1:0] = i_bin;

        for (int i = 0; i < BIN_W; i++) begin
            for (int d = 0; d < 5; d++) begin
                if (shift_reg[BIN_W + d*4 +: 4] >= 4'd5)
                    shift_reg[BIN_W + d*4 +: 4] =
                        shift_reg[BIN_W + d*4 +: 4] + 4'd3;
            end

            shift_reg = shift_reg << 1;
        end

        o_digit0 = shift_reg[BIN_W + 0*4 +: 4];
        o_digit1 = shift_reg[BIN_W + 1*4 +: 4];
        o_digit2 = shift_reg[BIN_W + 2*4 +: 4];
        o_digit3 = shift_reg[BIN_W + 3*4 +: 4];
        o_digit4 = shift_reg[BIN_W + 4*4 +: 4];
    end

endmodule