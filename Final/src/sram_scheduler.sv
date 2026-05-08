module sram_scheduler(
    input i_clk,
    input i_rst,

    input  [19:0] i_B0_r_addr,
    output [15:0] o_B0_r_data,
    input         i_B0_read_req,
    output        o_B0_read_valid,
    input  [19:0] i_B0_w_addr,
    input  [15:0] i_B0_w_data,
    input         i_B0_write_req,

    input  [19:0] i_B1_r_addr,
    output [15:0] o_B1_r_data,
    input         i_B1_read_req,
    output        o_B1_read_valid,
    input  [19:0] i_B1_w_addr,
    input  [15:0] i_B1_w_data,
    input         i_B1_write_req,

    input  [19:0] i_B2_r_addr,
    output [15:0] o_B2_r_data,
    input         i_B2_read_req,
    output        o_B2_read_valid,
    input  [19:0] i_B2_w_addr,
    input  [15:0] i_B2_w_data,
    input         i_B2_write_req,

    input  [19:0] i_B3_r_addr,
    output [15:0] o_B3_r_data,
    input         i_B3_read_req,
    output        o_B3_read_valid,
    input  [19:0] i_B3_w_addr,
    input  [15:0] i_B3_w_data,
    input         i_B3_write_req,

    input  [15:0] i_sram_data,
    output [19:0] o_sram_addr,
    output [15:0] o_sram_data,
    output        o_sram_we_n,

    output        o_ready // scheduler is not full
);
    logic B0_rq, B1_rq, B2_rq, B3_rq;
    assign B0_rq = i_B0_read_req || i_B0_write_req;
    assign B1_rq = i_B1_read_req || i_B1_write_req;
    assign B2_rq = i_B2_read_req || i_B2_write_req;
    assign B3_rq = i_B3_read_req || i_B3_write_req;
    
    logic [2:0] req_cnt;
    assign req_cnt = B0_rq + B1_rq + B2_rq + B3_rq;

    localparam IDLE = 0;
    localparam PROC_W = 1;
    localparam PROC_R = 2;
    logic [1:0] state_r, state_w;
    logic [2:0] counter_r, counter_w;

    // req_buffer : {block_idx[1:0], is_write, addr[19:0], w_data[15:0]}
    logic [38:0] req_buffer [0:15];
    logic [3:0]  buf_ptr_f, buf_ptr_i;
    logic [4:0]  fifo_cnt;
    assign o_ready = (fifo_cnt <= 8 && state_w == IDLE);

    logic [38:0] req_p1, req_p2, req_p3, req_p4;

    logic [4:0] ptr_p1 = buf_ptr_f + 1;
    logic [4:0] ptr_p2 = buf_ptr_f + 2;
    logic [4:0] ptr_p3 = buf_ptr_f + 3;
    logic [4:0] ptr_p4 = buf_ptr_f + 4;

    assign o_sram_addr = (state_r == IDLE) ? 20'd0 : req_buffer[buf_ptr_i][35:16];
    assign o_sram_data = (state_r == IDLE) ? 16'd0 : req_buffer[buf_ptr_i][15:0];
    assign o_sram_we_n = (state_r == PROC_W) ? 1'b0 : 1'b1;

    logic o_B0_read_valid_w, o_B1_read_valid_w, o_B2_read_valid_w, o_B3_read_valid_w;
    logic [15:0] o_B0_r_data_w, o_B1_r_data_w, o_B2_r_data_w, o_B3_r_data_w;
    logic o_B0_read_valid_r, o_B1_read_valid_r, o_B2_read_valid_r, o_B3_read_valid_r;
    logic [15:0] o_B0_r_data_r, o_B1_r_data_r, o_B2_r_data_r, o_B3_r_data_r;

    assign o_B0_read_valid = o_B0_read_valid_r;
    assign o_B0_r_data     = o_B0_r_data_r;
    assign o_B1_read_valid = o_B1_read_valid_r;
    assign o_B1_r_data     = o_B1_r_data_r;
    assign o_B2_read_valid = o_B2_read_valid_r;
    assign o_B2_r_data     = o_B2_r_data_r;
    assign o_B3_read_valid = o_B3_read_valid_r;
    assign o_B3_r_data     = o_B3_r_data_r;

    always_comb begin
        state_w = state_r;
        counter_w = counter_r;
        o_B0_read_valid_w = o_B0_read_valid_r;
        o_B1_read_valid_w = o_B1_read_valid_r;
        o_B2_read_valid_w = o_B2_read_valid_r;
        o_B3_read_valid_w = o_B3_read_valid_r;
        o_B0_r_data_w = o_B0_r_data_r;
        o_B1_r_data_w = o_B1_r_data_r;
        o_B2_r_data_w = o_B2_r_data_r;
        o_B3_r_data_w = o_B3_r_data_r;
        case (req_cnt)
            3'd0 : begin
                req_p1 = 39'd0;
                req_p2 = 39'd0;
                req_p3 = 39'd0;
                req_p4 = 39'd0;
            end
            3'd1 : begin
                if (i_B0_read_req)  req_p1 = {00, 0, i_B0_r_addr, 16'd0};
                if (i_B0_write_req) req_p1 = {00, 1, i_B0_w_addr, i_B0_w_data};
                if (i_B1_read_req)  req_p1 = {01, 0, i_B1_r_addr, 16'd0};
                if (i_B1_write_req) req_p1 = {01, 1, i_B1_w_addr, i_B1_w_data};
                if (i_B2_read_req)  req_p1 = {10, 0, i_B2_r_addr, 16'd0};
                if (i_B2_write_req) req_p1 = {10, 1, i_B2_w_addr, i_B2_w_data};
                if (i_B3_read_req)  req_p1 = {11, 0, i_B3_r_addr, 16'd0};
                if (i_B3_write_req) req_p1 = {11, 1, i_B3_w_addr, i_B3_w_data};
                req_p2 = 39'd0;
                req_p3 = 39'd0;
                req_p4 = 39'd0;
            end
            3'd2 : begin
                if (B0_rq && B1_rq) begin
                    if (i_B0_read_req)  req_p1 = {00, 0, i_B0_r_addr, 16'd0};
                    if (i_B0_write_req) req_p1 = {00, 1, i_B0_w_addr, i_B0_w_data};
                    if (i_B1_read_req)  req_p2 = {01, 0, i_B1_r_addr, 16'd0};
                    if (i_B1_write_req) req_p2 = {01, 1, i_B1_w_addr, i_B1_w_data};
                end
                if (B0_rq && B2_rq) begin
                    if (i_B0_read_req)  req_p1 = {00, 0, i_B0_r_addr, 16'd0};
                    if (i_B0_write_req) req_p1 = {00, 1, i_B0_w_addr, i_B0_w_data};
                    if (i_B2_read_req)  req_p2 = {10, 0, i_B2_r_addr, 16'd0};
                    if (i_B2_write_req) req_p2 = {10, 1, i_B2_w_addr, i_B2_w_data};
                end
                if (B0_rq && B3_rq) begin
                    if (i_B0_read_req)  req_p1 = {00, 0, i_B0_r_addr, 16'd0};
                    if (i_B0_write_req) req_p1 = {00, 1, i_B0_w_addr, i_B0_w_data};
                    if (i_B3_read_req)  req_p2 = {11, 0, i_B3_r_addr, 16'd0};
                    if (i_B3_write_req) req_p2 = {11, 1, i_B3_w_addr, i_B3_w_data};
                end
                if (B1_rq && B2_rq) begin
                    if (i_B1_read_req)  req_p1 = {01, 0, i_B1_r_addr, 16'd0};
                    if (i_B1_write_req) req_p1 = {01, 1, i_B1_w_addr, i_B1_w_data};
                    if (i_B2_read_req)  req_p2 = {10, 0, i_B2_r_addr, 16'd0};
                    if (i_B2_write_req) req_p2 = {10, 1, i_B2_w_addr, i_B2_w_data};
                end
                if (B1_rq && B3_rq) begin
                    if (i_B1_read_req)  req_p1 = {01, 0, i_B1_r_addr, 16'd0};
                    if (i_B1_write_req) req_p1 = {01, 1, i_B1_w_addr, i_B1_w_data};
                    if (i_B3_read_req)  req_p2 = {11, 0, i_B3_r_addr, 16'd0};
                    if (i_B3_write_req) req_p2 = {11, 1, i_B3_w_addr, i_B3_w_data};
                end
                if (B2_rq && B3_rq) begin
                    if (i_B2_read_req)  req_p1 = {10, 0, i_B2_r_addr, 16'd0};
                    if (i_B2_write_req) req_p1 = {10, 1, i_B2_w_addr, i_B2_w_data};
                    if (i_B3_read_req)  req_p2 = {11, 0, i_B3_r_addr, 16'd0};
                    if (i_B3_write_req) req_p2 = {11, 1, i_B3_w_addr, i_B3_w_data};
                end
                req_p3 = 39'd0;
                req_p4 = 39'd0;
            end
            3'd3 : begin
                if (!B0_rq) begin
                    if (i_B1_read_req)  req_p1 = {01, 0, i_B1_r_addr, 16'd0};
                    if (i_B1_write_req) req_p1 = {01, 1, i_B1_w_addr, i_B1_w_data};
                    if (i_B2_read_req)  req_p2 = {10, 0, i_B2_r_addr, 16'd0};
                    if (i_B2_write_req) req_p2 = {10, 1, i_B2_w_addr, i_B2_w_data};
                    if (i_B3_read_req)  req_p3 = {11, 0, i_B3_r_addr, 16'd0};
                    if (i_B3_write_req) req_p3 = {11, 1, i_B3_w_addr, i_B3_w_data};
                end
                if (!B1_rq) begin
                    if (i_B0_read_req)  req_p1 = {00, 0, i_B0_r_addr, 16'd0};
                    if (i_B0_write_req) req_p1 = {00, 1, i_B0_w_addr, i_B0_w_data};
                    if (i_B2_read_req)  req_p2 = {10, 0, i_B2_r_addr, 16'd0};
                    if (i_B2_write_req) req_p2 = {10, 1, i_B2_w_addr, i_B2_w_data};
                    if (i_B3_read_req)  req_p3 = {11, 0, i_B3_r_addr, 16'd0};
                    if (i_B3_write_req) req_p3 = {11, 1, i_B3_w_addr, i_B3_w_data};
                end
                if (!B2_rq) begin
                    if (i_B0_read_req)  req_p1 = {00, 0, i_B0_r_addr, 16'd0};
                    if (i_B0_write_req) req_p1 = {00, 1, i_B0_w_addr, i_B0_w_data};
                    if (i_B1_read_req)  req_p2 = {01, 0, i_B1_r_addr, 16'd0};
                    if (i_B1_write_req) req_p2 = {01, 1, i_B1_w_addr, i_B1_w_data};
                    if (i_B3_read_req)  req_p3 = {11, 0, i_B3_r_addr, 16'd0};
                    if (i_B3_write_req) req_p3 = {11, 1, i_B3_w_addr, i_B3_w_data};
                end
                if (!B3_rq) begin
                    if (i_B0_read_req)  req_p1 = {00, 0, i_B0_r_addr, 16'd0};
                    if (i_B0_write_req) req_p1 = {00, 1, i_B0_w_addr, i_B0_w_data};
                    if (i_B1_read_req)  req_p2 = {01, 0, i_B1_r_addr, 16'd0};
                    if (i_B1_write_req) req_p2 = {01, 1, i_B1_w_addr, i_B1_w_data};
                    if (i_B2_read_req)  req_p3 = {10, 0, i_B2_r_addr, 16'd0};
                    if (i_B2_write_req) req_p3 = {10, 1, i_B2_w_addr, i_B2_w_data};
                end
                req_p4 = 39'd0;
            end
            3'd4 : begin
                if (i_B0_read_req)  req_p1 = {00, 0, i_B0_r_addr, 16'd0};
                if (i_B0_write_req) req_p1 = {00, 1, i_B0_w_addr, i_B0_w_data};
                if (i_B1_read_req)  req_p2 = {01, 0, i_B1_r_addr, 16'd0};
                if (i_B1_write_req) req_p2 = {01, 1, i_B1_w_addr, i_B1_w_data};
                if (i_B2_read_req)  req_p3 = {10, 0, i_B2_r_addr, 16'd0};
                if (i_B2_write_req) req_p3 = {10, 1, i_B2_w_addr, i_B2_w_data};
                if (i_B3_read_req)  req_p4 = {11, 0, i_B3_r_addr, 16'd0};
                if (i_B3_write_req) req_p4 = {11, 1, i_B3_w_addr, i_B3_w_data};
            end
            default : begin
                req_p1 = 39'd0;
                req_p2 = 39'd0;
                req_p3 = 39'd0;
                req_p4 = 39'd0;
            end
        endcase
        case (state_r)
            IDLE : begin
                if (fifo_cnt > 0 && req_cnt == 0) begin
                    counter_w = 0;
                    if (req_buffer[buf_ptr_i][36]) state_w = PROC_W;
                    else state_w = PROC_R;
                end
            end
            PROC_W : begin
                if (counter_r == 6) begin
                    state_w = IDLE;
                end
                counter_w = counter_r + 1;
            end
            PROC_R : begin
                if (counter_r == 5) begin
                    case (req_buffer[buf_ptr_i][38:37])
                        2'b00 : begin
                            o_B0_read_valid_w = 1;
                            o_B0_r_data_w     = i_sram_data;
                        end
                        2'b01 : begin
                            o_B1_read_valid_w = 1;
                            o_B1_r_data_w     = i_sram_data;
                        end
                        2'b10 : begin
                            o_B2_read_valid_w = 1;
                            o_B2_r_data_w     = i_sram_data;
                        end
                        2'b11 : begin
                            o_B3_read_valid_w = 1;
                            o_B3_r_data_w     = i_sram_data;
                        end
                    endcase
                end else if (counter_r == 6) begin
                    state_w = IDLE;
                end
                counter_w = counter_r + 1;
            end
            default : begin
                state_w = IDLE;
                counter_w = 0;
            end
        endcase
    end
    
    always_ff @(posedge i_clk or posedge i_rst) begin
        if (i_rst) begin
            buf_ptr_f <= 0;
            buf_ptr_i <= 0;
            fifo_cnt  <= 0;
            state_r   <= IDLE;
            counter_r <= 0;
            o_B0_read_valid_r <= 0;
            o_B1_read_valid_r <= 0;
            o_B2_read_valid_r <= 0;
            o_B3_read_valid_r <= 0;
            o_B0_r_data_r <= 16'd0;
            o_B1_r_data_r <= 16'd0;
            o_B2_r_data_r <= 16'd0;
            o_B3_r_data_r <= 16'd0;
        end else begin
            state_r   <= state_w;
            counter_r <= counter_w; 
            o_B0_read_valid_r <= o_B0_read_valid_w;
            o_B1_read_valid_r <= o_B1_read_valid_w;
            o_B2_read_valid_r <= o_B2_read_valid_w;
            o_B3_read_valid_r <= o_B3_read_valid_w;
            o_B0_r_data_r <= o_B0_r_data_w;
            o_B1_r_data_r <= o_B1_r_data_w;
            o_B2_r_data_r <= o_B2_r_data_w;
            o_B3_r_data_r <= o_B3_r_data_w;
            case (req_cnt)
                3'd1 : begin
                    if (fifo_cnt < 16) begin
                        req_buffer[buf_ptr_f] <= req_p1;
                        buf_ptr_f             <= ptr_p1[3:0];
                        fifo_cnt              <= fifo_cnt + 1;
                    end
                end
                3'd2 : begin
                    if (fifo_cnt < 15) begin
                        req_buffer[buf_ptr_f]     <= req_p1;
                        req_buffer[ptr_p1[3:0]]   <= req_p2;
                        buf_ptr_f                 <= ptr_p2[3:0];
                        fifo_cnt                  <= fifo_cnt + 2;
                    end
                end
                3'd3 : begin
                    if (fifo_cnt < 14) begin
                        req_buffer[buf_ptr_f]     <= req_p1;
                        req_buffer[ptr_p1[3:0]]   <= req_p2;
                        req_buffer[ptr_p2[3:0]]   <= req_p3;
                        buf_ptr_f                 <= ptr_p3[3:0];
                        fifo_cnt                  <= fifo_cnt + 3;
                    end
                end
                3'd4 : begin
                    if (fifo_cnt < 13) begin
                        req_buffer[buf_ptr_f]     <= req_p1;
                        req_buffer[ptr_p1[3:0]]   <= req_p2;
                        req_buffer[ptr_p2[3:0]]   <= req_p3;
                        req_buffer[ptr_p3[3:0]]   <= req_p4;
                        buf_ptr_f                 <= ptr_p4[3:0];
                        fifo_cnt                  <= fifo_cnt + 4;
                    end
                end
                default : begin
                    // do nothing
                end
            endcase
        end
        if ((state_r == PROC_R || state_r == PROC_W) && counter_r == 6) begin
            buf_ptr_i <= buf_ptr_i + 1;
            fifo_cnt  <= fifo_cnt - 1;
        end
    end
endmodule