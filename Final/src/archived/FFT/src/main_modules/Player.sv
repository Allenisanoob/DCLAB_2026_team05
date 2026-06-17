module Player (
    input         i_rst,
    input         i_BCLK,
    input         i_DAC_LRCK,
    input  [15:0] i_out_data,
    output        o_DAC_DAT,
    output        o_B2P_request_l,
    output        o_B2P_request_r
);
    localparam IDLE = 1'd0;
    localparam SEND = 1'd1;

    logic        state_r, state_w;
    logic        is_init_r, is_init_w;
    logic [3:0]  counter_r, counter_w;
    logic [15:0] o_DAC_DAT_r, o_DAC_DAT_w;
    logic        daclrck_prev_r;
    logic        lrc_edge;

    logic        o_B2P_request_l_, o_B2P_request_r_;

    assign o_DAC_DAT   = o_DAC_DAT_r[15];
    assign lrc_edge    = (i_DAC_LRCK != daclrck_prev_r);
    assign o_B2P_request_l = o_B2P_request_l_;
    assign o_B2P_request_r = o_B2P_request_r_;

    always_comb begin
        state_w         = state_r;
        counter_w       = counter_r;
        o_DAC_DAT_w     = o_DAC_DAT_r;
        is_init_w       = is_init_r;
        o_B2P_request_l_ = 1'b0; 
        o_B2P_request_r_ = 1'b0; 

        case(state_r)
            IDLE: begin
                if (is_init_r && !i_DAC_LRCK) o_B2P_request_l_ = 1'b1;
                else if(is_init_r && i_DAC_LRCK) o_B2P_request_r_ = 1'b1;
                is_init_w       = 1'b0;
                if (lrc_edge) begin
                    state_w = SEND;
                    o_DAC_DAT_w = i_out_data;
                end
                counter_w = 4'd0;
            end
            SEND: begin
                if (counter_r == 15) begin 
                    state_w = IDLE;
                    if (i_DAC_LRCK) o_B2P_request_l_ = 1'b1;
                    else o_B2P_request_r_ = 1'b1;
                end
                counter_w = counter_r + 1;
                o_DAC_DAT_w = o_DAC_DAT_r << 1;
            end
        endcase
    end

    always_ff @(negedge i_BCLK or negedge i_rst) begin
        if (!i_rst) begin
            state_r        <= IDLE;
            is_init_r      <= 1'b1;
            counter_r      <= 4'd0;
            o_DAC_DAT_r    <= 16'd0;
            daclrck_prev_r <= i_DAC_LRCK;
        end else begin
            state_r        <= state_w;
            is_init_r      <= is_init_w;
            counter_r      <= counter_w;
            o_DAC_DAT_r    <= o_DAC_DAT_w;
            daclrck_prev_r <= i_DAC_LRCK;
        end
    end
endmodule