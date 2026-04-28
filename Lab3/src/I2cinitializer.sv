module I2cInitializer (
    input  i_rst_n,
    input  i_clk,
    input  i_start,
    output o_finished,
    output o_sclk,
    output o_sdat,
    output o_oen

    // output [3:0] dbg
);

localparam [26:0] RESET                          = 27'b0011_0100_0_000_1111_0_0_0000_0000_0;
localparam [26:0] LEFT_LINE_IN                   = 27'b0011_0100_0_000_0000_0_0_1001_0111_0;
localparam [26:0] RIGHT_LINE_IN                  = 27'b0011_0100_0_000_0001_0_0_1001_0111_0;
localparam [26:0] LEFT_HEADPHONE_OUT             = 27'b0011_0100_0_000_0010_0_0_0111_1001_0;
localparam [26:0] RIGHT_HEADPHONE_OUT            = 27'b0011_0100_0_000_0011_0_0_0111_1001_0;
localparam [26:0] ANALOGUE_AUDIO_PATH_CONTROL    = 27'b0011_0100_0_000_0100_0_0_0001_0101_0;
localparam [26:0] DIGITAL_AUDIO_PATH_CONTROL     = 27'b0011_0100_0_000_0101_0_0_0000_0000_0;
localparam [26:0] POWER_DOWN_CONTROL             = 27'b0011_0100_0_000_0110_0_0_0000_0000_0;
localparam [26:0] DIGITAL_AUDIO_INTERFACE_FORMAT = 27'b0011_0100_0_000_0111_0_0_0100_0010_0;
localparam [26:0] SAMPLING_CONTROL               = 27'b0011_0100_0_000_1000_0_0_0001_1001_0;
localparam [26:0] ACTIVE_CONTROL                 = 27'b0011_0100_0_000_1001_0_0_0000_0001_0;

localparam [2:0] IDLE      = 3'd0;
localparam [2:0] START_1st = 3'd1;
localparam [2:0] START_2nd = 3'd2;
localparam [2:0] DATA_1st  = 3'd3;
localparam [2:0] DATA_2nd  = 3'd4;
localparam [2:0] DATA_end  = 3'd5;
localparam [2:0] STOP_1st  = 3'd6;
localparam [2:0] STOP_2nd  = 3'd7;

logic [2:0]  state_w, state_r;
logic [3:0]  command_cnt_w, command_cnt_r;
logic [4:0]  bit_cnt_w, bit_cnt_r;
logic        o_finished_w, o_finished_r;
logic [26:0] data;

assign dbg = {1'b0, state_r};

assign o_finished = o_finished_r;
assign o_sclk = o_finished_r                                 ? 1'b1 : 
                (state_r == DATA_1st || state_r == DATA_end) ? 1'b0 :
                                                               1'b1;
assign o_sdat = o_finished_r                                                         ? 1'b1 :
                (state_r == IDLE || state_r == START_1st || state_r == STOP_2nd)     ? 1'b1 :
                (state_r == START_2nd || state_r == DATA_end || state_r == STOP_1st) ? 1'b0 :
                                                                                       data[26 - bit_cnt_r];
assign o_oen = !((state_r == DATA_1st || state_r == DATA_2nd) && (bit_cnt_r == 8 || bit_cnt_r == 17 || bit_cnt_r == 26));

always_comb begin
    state_w       = state_r;
    command_cnt_w = command_cnt_r;
    bit_cnt_w     = bit_cnt_r;
    o_finished_w  = o_finished_r;

    case (command_cnt_r)
        4'd0  : data = RESET;
        4'd1  : data = LEFT_LINE_IN;
        4'd2  : data = RIGHT_LINE_IN;
        4'd3  : data = LEFT_HEADPHONE_OUT;
        4'd4  : data = RIGHT_HEADPHONE_OUT;
        4'd5  : data = ANALOGUE_AUDIO_PATH_CONTROL;
        4'd6  : data = DIGITAL_AUDIO_PATH_CONTROL;
        4'd7  : data = POWER_DOWN_CONTROL;
        4'd8  : data = DIGITAL_AUDIO_INTERFACE_FORMAT;
        4'd9  : data = SAMPLING_CONTROL;
        4'd10 : data = ACTIVE_CONTROL;
        default : data = RESET;
    endcase

    case (state_r)
        IDLE : begin
            if (i_start) state_w = START_1st;
            command_cnt_w = 4'd0;
            bit_cnt_w     = 5'd0;
        end

        START_1st : begin
            state_w   = START_2nd;
            bit_cnt_w = 5'd0;
        end

        START_2nd : begin
            state_w = DATA_1st;
        end

        DATA_1st : begin
            state_w = DATA_2nd;
        end

        DATA_2nd : begin
            if (bit_cnt_r == 26) state_w = DATA_end;
            else begin
                state_w = DATA_1st;
                bit_cnt_w = bit_cnt_r + 1;
            end
        end

        DATA_end : begin
            state_w = STOP_1st;
        end

        STOP_1st : begin
            state_w = STOP_2nd;
        end

        STOP_2nd : begin
            if (command_cnt_r == 10) begin
                state_w      = IDLE;
                o_finished_w = 1'b1;
            end else begin
                state_w       = START_1st;
                command_cnt_w = command_cnt_r + 1;
            end
        end
    endcase
end

always_ff @ (posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
        state_r       <= IDLE;
        command_cnt_r <= 4'd0;
        bit_cnt_r     <= 5'd0;
        o_finished_r  <= 1'b0;
    end else begin
        state_r       <= state_w;
        command_cnt_r <= command_cnt_w;
        bit_cnt_r     <= bit_cnt_w;
        o_finished_r  <= o_finished_w;
    end
end

endmodule
