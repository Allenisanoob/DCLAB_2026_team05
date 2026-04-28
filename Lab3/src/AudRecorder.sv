module AudRecorder (
    input         i_rst_n,
    input         i_clk,
    input         i_lrc,
    input         i_start,
    input         i_pause,
    input         i_stop,
    input         i_data,
    output [19:0] o_address,
    output signed [15:0] o_data,
    output        o_sram_we_n
);
    localparam IDLE  = 3'd0;
    localparam PAUSE = 3'd1;
    localparam LEFT  = 3'd2;
    localparam RIGHT = 3'd3;
    localparam STOP  = 3'd4;

    logic [2:0]  state_r, state_w;
    logic        is_pause_r, is_pause_w;
    logic        is_stop_r, is_stop_w;
    logic [4:0]  counter_r, counter_w;
    logic [19:0] addr_r, addr_w;
    logic signed [15:0] data_r, data_w;
    
    assign o_address   = addr_r;
    assign o_data      = data_r;
    assign o_sram_we_n = (state_r == RIGHT && counter_r == 16) ? 1'b0 : 1'b1;

    always_comb begin
        state_w    = state_r;
        is_pause_w = is_pause_r;
        is_stop_w  = is_stop_r;
        counter_w  = counter_r;
        addr_w     = addr_r;
        data_w     = data_r;

        case (state_r)
            IDLE: begin
                if (i_start) state_w = PAUSE;
                is_pause_w = 1'b1;
                is_stop_w = 1'b0;
                counter_w = 5'd0;
                addr_w = 20'd0;
                data_w = 16'd0;
            end
            PAUSE: begin
                if (is_stop_r) state_w = STOP;
                else if (!is_pause_r && !i_lrc) state_w = LEFT;
                if (i_pause) is_pause_w = 1'b0;
                if (i_stop) is_stop_w = 1'b1;
                counter_w = 5'd0;
                data_w = 16'd0;
            end
            LEFT: begin
                if (is_stop_r) state_w = STOP;
                else if (is_pause_r) state_w = PAUSE;
                else if (i_lrc) state_w = RIGHT;
                if (i_pause) is_pause_w = 1'b1;
                if (i_stop) is_stop_w = 1'b1;
                counter_w = 5'd0;
                data_w = 16'd0;
            end
            RIGHT: begin
                if (!i_lrc) state_w = LEFT;
                if (i_pause) is_pause_w = 1'b1;
                if (i_stop || addr_r == 20'd1048575) is_stop_w = 1'b1;
                if (counter_r < 16) counter_w = counter_r + 1;
                if (state_w == LEFT && counter_r >= 15) addr_w = addr_r + 1;
                if (counter_r < 16) data_w[15 - counter_r] = i_data;
            end
            STOP: begin
                is_stop_w = 1'b1;
            end
        endcase
    end

    always_ff @(negedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            state_r    <= IDLE;
            is_pause_r <= 1'b1;
            is_stop_r  <= 1'b0;
            counter_r  <= 5'b0;
            addr_r     <= 20'd0;
            data_r     <= 16'd0;
        end else begin
            state_r    <= state_w;
            is_pause_r <= is_pause_w;
            is_stop_r  <= is_stop_w;
            counter_r  <= counter_w;
            addr_r     <= addr_w;
            data_r     <= data_w;
        end
    end
endmodule