module AudPlayer (
    input         i_rst_n,
    input         i_bclk,
    input         i_daclrck,
    input         i_en,
    input  [15:0] i_dac_data,
    output        o_aud_dacdat
);
    localparam IDLE = 1'd0;
    localparam SEND = 1'd1;

    logic        state_r, state_w;
    logic [3:0]  counter_r, counter_w;
    logic [15:0] o_aud_dacdat_r, o_aud_dacdat_w;
    logic        daclrck_prev_r;
    logic        lrc_edge;

    assign o_aud_dacdat = o_aud_dacdat_r[15];
    assign lrc_edge     = (i_daclrck != daclrck_prev_r);

    always_comb begin
        state_w        = state_r;
        counter_w      = counter_r;
        o_aud_dacdat_w = o_aud_dacdat_r;

        case(state_r)
            IDLE: begin
                if (i_en && lrc_edge) begin
                    state_w = SEND;
                    o_aud_dacdat_w = i_dac_data;
                end
                counter_w = 4'd0;
            end
            SEND: begin
                if (counter_r == 15) state_w = IDLE;
                counter_w = counter_r + 1;
                o_aud_dacdat_w = o_aud_dacdat_r << 1;
            end
        endcase
    end

    always_ff @(negedge i_bclk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            state_r        <= IDLE;
            counter_r      <= 4'd0;
            o_aud_dacdat_r <= 16'd0;
            daclrck_prev_r <= i_daclrck;
        end else begin
            state_r        <= state_w;
            counter_r      <= counter_w;
            o_aud_dacdat_r <= o_aud_dacdat_w;
            daclrck_prev_r <= i_daclrck;
        end
    end
endmodule