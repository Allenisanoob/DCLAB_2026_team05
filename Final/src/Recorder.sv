module Recorder (
    input         i_rst,
    input         i_BCLK,
    input         i_ADC_LRCK,
    input         i_ADC_DAT,
    output signed [15:0] o_raw_data,
    output        o_R2D_valid
);

    localparam IDLE  = 2'd0;
    localparam RIGHT = 2'd1;
    localparam LEFT  = 2'd2;

    logic [1:0]  state_r, state_w;
    logic [4:0]  counter_r, counter_w;
    logic signed [15:0] data_r, data_w;
    
    assign o_raw_data  = data_r;
    assign o_R2D_valid = (state_r == RIGHT && counter_r == 16) ? 1'b0 : 1'b1;

    always_comb begin
        state_w    = state_r;
        counter_w  = counter_r;
        data_w     = data_r;

        case (state_r)
            IDLE: begin
                if (!i_ADC_LRCK) state_w = LEFT;
                counter_w = 5'd0;
                data_w = 16'd0;
            end
            LEFT: begin
                if (i_ADC_LRCK) state_w = RIGHT;
                counter_w = 5'd0;
                //data_w = 16'd0;
            end
            RIGHT: begin
                if (!i_ADC_LRCK) state_w = LEFT;
                if (counter_r < 16) begin
                counter_w = counter_r + 1;
                data_w[15 - counter_r] = i_ADC_DAT;
                end
            end
            default: state_w = IDLE;
        endcase
    end

    always_ff @(negedge i_BCLK or negedge i_rst) begin
        if (!i_rst) begin
            state_r    <= IDLE;
            counter_r  <= 5'b0;
            data_r     <= 16'd0;
        end else begin
            state_r    <= state_w;
            counter_r  <= counter_w;
            data_r     <= data_w;
        end
    end
endmodule