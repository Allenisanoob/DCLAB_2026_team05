module Player (
    input         i_rst,
    input         i_BCLK,
    input         i_DAC_LRCK,
    input         i_en,
    input  [15:0] i_out_data,
    output        o_DAC_DAT,
    output        B2P_rq
);
    localparam IDLE = 2'd0;
    localparam SEND = 2'd1;
    localparam WAIT = 2'd2;

    logic [1:0]  state_r, state_w;
    logic [3:0]  counter_r, counter_w;
    logic [15:0]  o_DAC_DAT_r, o_DAC_DAT_w;
    //logic       o_DAC_DAT_r, o_DAC_DAT_w;
    //logic signed [15:0] i_out_data_r, i_out_data_w;

    assign o_DAC_DAT = o_DAC_DAT_r[15];
    //assign o_DAC_DAT = o_DAC_DAT_r;

    always_comb begin
        state_w        = state_r;
        counter_w      = counter_r;
        o_DAC_DAT_w = o_DAC_DAT_r;
        //i_out_data_w   = i_out_data_r;

        case(state_r)
            IDLE: begin
                if (i_en) begin
                    state_w = SEND;
                    o_DAC_DAT_w = i_out_data;
                end
                counter_w = 4'd0;
                //i_out_data_w = i_out_data;
            end
            SEND: begin
                if (counter_r == 15) state_w = WAIT;
                counter_w = counter_r + 1;
                o_DAC_DAT_w = o_DAC_DAT_r << 1;
                //o_DAC_DAT_w = i_out_data_r[15];
            end
            WAIT: begin
                if (i_DAC_LRCK) state_w = IDLE;
            end
        endcase
    end

    always_ff @(negedge i_BCLK or negedge i_rst) begin
        if (!i_rst) begin
            state_r        <= IDLE;
            counter_r      <= 4'd0;
            o_DAC_DAT_r <= 1'b0;
            //i_out_data_r   <= 16'd0;
        end else begin
            state_r        <= state_w;
            counter_r      <= counter_w;
            o_DAC_DAT_r <= o_DAC_DAT_w;
            //i_out_data_r   <= i_out_data_w;
        end
    end
endmodule