module cs_amplifier_sim (
    input                      i_clk,
    input                      i_rst_n,
    input        signed [15:0] i_Vin,     // Q0.15 (Signed)
    input               [7:0]  i_gain,    // Q2.6 (Unsigned)
    input                      i_en,
    output logic signed [15:0] o_Vout,    // Q0.15 (Signed)
    output logic               o_en
);

    logic signed [23:0] mult_res;
    logic signed [23:0] inverted_res;

    //In Q2.21, 1.0 is equal to 2^21 = 2097152
    localparam signed [23:0] POS_LIMIT = 24'sd2097151; // 近似 1.0
    localparam signed [23:0] NEG_LIMIT = -24'sd2097152; // -1.0
    

    always_comb begin
        mult_res = i_Vin * $signed({1'b0, i_gain});
        inverted_res = -mult_res;
    end

    always_ff @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            o_Vout <= 16'd0;
            o_en   <= 1'b0;
        end else begin
            o_en  <= i_en;
            if (i_en) begin
                if (inverted_res > POS_LIMIT) begin
                    o_Vout <= 16'h7FFF;                 // 0.9999... (Q0.15 Max)
                end else if (inverted_res < NEG_LIMIT) begin
                    o_Vout <= 16'h8000;                 // -1.0 (Q0.15 Min)
                end else begin
                    o_Vout <= {inverted_res[23], inverted_res[20:6]};
                end
            end
        end
    end
endmodule