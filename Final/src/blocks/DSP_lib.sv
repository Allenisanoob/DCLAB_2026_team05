module Volume (
    input  i_prev_valid,
    input  signed [15:0] i_data,
    input  [6:0] i_volume_control, // 0 - Muted, 127 - Full Volume
    output o_next_valid,
    output signed [15:0] o_data
);
    // out = in * (i_volume_control / 128)
    logic signed [23:0] mult_result;
    assign mult_result = i_data * $signed({1'b0, i_volume_control});

    assign o_next_valid = i_prev_valid;
    assign o_data = (i_volume_control == 7'b0000000) ? 16'b0 :
                    (i_volume_control == 7'b1111111) ? i_data :
                    (mult_result >>> 7);

endmodule

module Data_Catcher (
    input  i_clk,
    input  i_rst,
    input  i_raw_valid,
    input  signed [15:0] i_data,
    output o_next_valid,
    output signed [15:0] o_data
);
    reg now_valid, old_valid;
    reg signed [15:0] data_reg;

    assign o_next_valid = (i_raw_valid && !old_valid);
    assign o_data = data_reg;

    always @(posedge i_clk or negedge i_rst) begin
        if (i_rst) begin
            now_valid <= 1'b0;
            old_valid <= 1'b0;
            data_reg <= 16'b0;
        end else begin
            now_valid <= i_raw_valid;
            old_valid <= now_valid;
            if (i_raw_valid && !old_valid) begin
                data_reg <= i_data;
            end
        end
    end

endmodule