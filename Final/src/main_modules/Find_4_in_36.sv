module Find_4_in_36(
    input i_clk,
    input i_rst,
    input i_valid,
    
    input [31:0] amp_sq_E2,
    input [31:0] amp_sq_F2,
    input [31:0] amp_sq_Fs2,
    input [31:0] amp_sq_G2,
    input [31:0] amp_sq_Gs2,
    input [31:0] amp_sq_A2,
    input [31:0] amp_sq_As2,
    input [31:0] amp_sq_B2,
    input [31:0] amp_sq_C3,
    input [31:0] amp_sq_Cs3,
    input [31:0] amp_sq_D3,
    input [31:0] amp_sq_Ds3,
    input [31:0] amp_sq_E3,
    input [31:0] amp_sq_F3,
    input [31:0] amp_sq_Fs3,
    input [31:0] amp_sq_G3,
    input [31:0] amp_sq_Gs3,
    input [31:0] amp_sq_A3,
    input [31:0] amp_sq_As3,
    input [31:0] amp_sq_B3,
    input [31:0] amp_sq_C4,
    input [31:0] amp_sq_Cs4,
    input [31:0] amp_sq_D4,
    input [31:0] amp_sq_Ds4,
    input [31:0] amp_sq_E4,
    input [31:0] amp_sq_F4,
    input [31:0] amp_sq_Fs4,
    input [31:0] amp_sq_G4,
    input [31:0] amp_sq_Gs4,
    input [31:0] amp_sq_A4,
    input [31:0] amp_sq_As4,
    input [31:0] amp_sq_B4,
    input [31:0] amp_sq_C5,
    input [31:0] amp_sq_Cs5,
    input [31:0] amp_sq_D5,
    input [31:0] amp_sq_Ds5,

    output reg    o_valid,
    output [35:0] notes
);

logic [31:0] amp_sq_r [0:35];
logic [31:0] top_1_amp, top_2_amp, top_3_amp, top_4_amp;
logic [5:0]  top_1_id, top_2_id, top_3_id, top_4_id;
logic [5:0]  cnt;
logic [35:0] notes_r;

assign notes = notes_r;

always_ff @(posedge i_clk or negedge i_rst) begin
    if (!i_rst) begin
        top_1_amp <= 32'd0;
        top_2_amp <= 32'd0;
        top_3_amp <= 32'd0;
        top_4_amp <= 32'd0;
        top_1_id  <= 6'd0;
        top_2_id  <= 6'd0;
        top_3_id  <= 6'd0;
        top_4_id  <= 6'd0;
        cnt       <= 6'd0;
        o_valid   <= 1'b0;
        notes_r   <= 36'd0;
    end else begin
        if (cnt == 0) begin
            top_1_amp <= 32'd0;
            top_2_amp <= 32'd0;
            top_3_amp <= 32'd0;
            top_4_amp <= 32'd0;
            top_1_id  <= 6'd0;
            top_2_id  <= 6'd0;
            top_3_id  <= 6'd0;
            top_4_id  <= 6'd0;
            o_valid   <= 1'b0;
            notes_r   <= 36'd0;
            if (i_valid) begin
                cnt <= 1;
                amp_sq_r[0]  <= amp_sq_E2;
                amp_sq_r[1]  <= amp_sq_F2;
                amp_sq_r[2]  <= amp_sq_Fs2;
                amp_sq_r[3]  <= amp_sq_G2;
                amp_sq_r[4]  <= amp_sq_Gs2;
                amp_sq_r[5]  <= amp_sq_A2;
                amp_sq_r[6]  <= amp_sq_As2;
                amp_sq_r[7]  <= amp_sq_B2;
                amp_sq_r[8]  <= amp_sq_C3;
                amp_sq_r[9]  <= amp_sq_Cs3;
                amp_sq_r[10] <= amp_sq_D3;
                amp_sq_r[11] <= amp_sq_Ds3;
                amp_sq_r[12] <= amp_sq_E3;
                amp_sq_r[13] <= amp_sq_F3;
                amp_sq_r[14] <= amp_sq_Fs3;
                amp_sq_r[15] <= amp_sq_G3;
                amp_sq_r[16] <= amp_sq_Gs3;
                amp_sq_r[17] <= amp_sq_A3;
                amp_sq_r[18] <= amp_sq_As3;
                amp_sq_r[19] <= amp_sq_B3;
                amp_sq_r[20] <= amp_sq_C4;
                amp_sq_r[21] <= amp_sq_Cs4;
                amp_sq_r[22] <= amp_sq_D4;
                amp_sq_r[23] <= amp_sq_Ds4;
                amp_sq_r[24] <= amp_sq_E4;
                amp_sq_r[25] <= amp_sq_F4;
                amp_sq_r[26] <= amp_sq_Fs4;
                amp_sq_r[27] <= amp_sq_G4;
                amp_sq_r[28] <= amp_sq_Gs4;
                amp_sq_r[29] <= amp_sq_A4;
                amp_sq_r[30] <= amp_sq_As4;
                amp_sq_r[31] <= amp_sq_B4;
                amp_sq_r[32] <= amp_sq_C5;
                amp_sq_r[33] <= amp_sq_Cs5;
                amp_sq_r[34] <= amp_sq_D5;
                amp_sq_r[35] <= amp_sq_Ds5;
            end
        end else if (cnt >= 1 && cnt <= 36) begin
            cnt <= cnt + 1;
            if (amp_sq_r[cnt - 1] >= top_1_amp) begin
                top_1_amp <= amp_sq_r[cnt - 1];
                top_1_id  <= cnt;
                top_2_amp <= top_1_amp;
                top_2_id  <= top_1_id;
                top_3_amp <= top_2_amp;
                top_3_id  <= top_2_id;
                top_4_amp <= top_3_amp;
                top_4_id  <= top_3_id;
            end else if (amp_sq_r[cnt - 1] >= top_2_amp) begin
                top_2_amp <= amp_sq_r[cnt - 1];
                top_2_id  <= cnt;
                top_3_amp <= top_2_amp;
                top_3_id  <= top_2_id;
                top_4_amp <= top_3_amp;
                top_4_id  <= top_3_id;
            end else if (amp_sq_r[cnt - 1] >= top_3_amp) begin
                top_3_amp <= amp_sq_r[cnt - 1];
                top_3_id  <= cnt;
                top_4_amp <= top_3_amp;
                top_4_id  <= top_3_id;
            end else if (amp_sq_r[cnt - 1] >= top_4_amp) begin
                top_4_amp <= amp_sq_r[cnt - 1];
                top_4_id  <= cnt;
            end
        end else if (cnt == 37) begin
            cnt <= cnt + 1;
            if (top_1_id != 0) notes_r[36 - top_1_id] <= 1;
        end else if (cnt == 38) begin
            cnt <= cnt + 1;
            if (top_2_id != 0) notes_r[36 - top_2_id] <= 1;
        end else if (cnt == 39) begin
            cnt <= cnt + 1;
            if (top_3_id != 0) notes_r[36 - top_3_id] <= 1;
        end else if (cnt == 40) begin
            cnt <= cnt + 1;
            if (top_4_id != 0) notes_r[36 - top_4_id] <= 1;
        end else if (cnt == 41) begin
            cnt <= 0;
            o_valid <= 1'b1;
        end
    end
end

endmodule