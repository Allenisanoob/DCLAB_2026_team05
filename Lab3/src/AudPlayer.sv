module AudPlayer (
    input         i_rst_n,
    input         i_bclk,
    input         i_daclrck,
    input         i_en,
    input  [15:0] i_dac_data,
    output        o_aud_dacdat
);
    localparam IDLE = 2'd0;
    localparam SEND = 2'd1;
    localparam WAIT = 2'd2;

    logic [1:0]  state_r, state_w;
    logic [3:0]  counter_r, counter_w;
    logic        o_aud_dacdat_r, o_aud_dacdat_w;
    logic [15:0] i_dac_data_r, i_dac_data_w;

    assign o_aud_dacdat = o_aud_dacdat_r;

    always_comb begin
        state_w        = state_r;
        counter_w      = counter_r;
        o_aud_dacdat_w = o_aud_dacdat_r;
        i_dac_data_w   = i_dac_data_r;

        case(state_r)
            IDLE: begin
                if (i_en) state_w = SEND;
                counter_w = 4'd0;
                i_dac_data_w = i_dac_data;
            end
            SEND: begin
                if (counter_r == 15) state_w = WAIT;
                counter_w = counter_r + 1;
                o_aud_dacdat_w = i_dac_data_r[15 - counter_r];
            end
            WAIT: begin
                if (i_daclrck) state_w = IDLE;
            end
        endcase
    end

    always_ff @(negedge i_bclk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            state_r        <= IDLE;
            counter_r      <= 4'd0;
            o_aud_dacdat_r <= 1'b0;
            i_dac_data_r   <= 16'd0;
        end else begin
            state_r        <= state_w;
            counter_r      <= counter_w;
            o_aud_dacdat_r <= o_aud_dacdat_w;
            i_dac_data_r   <= i_dac_data_w;
        end
    end
endmodule