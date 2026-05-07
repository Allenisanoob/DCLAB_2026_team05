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

    output        o_ready // scheduler is not full
);
    logic B0_rq, B1_rq, B2_rq, B3_rq;
    assign B0_rq = i_B0_read_req || i_B0_write_req;
    assign B1_rq = i_B1_read_req || i_B1_write_req;
    assign B2_rq = i_B2_read_req || i_B2_write_req;
    assign B3_rq = i_B3_read_req || i_B3_write_req;
    
    logic [2:0] req_cnt;
    assign req_cnt = B0_rq + B1_rq + B2_rq + B3_rq;

    // req_buffer : {block_idx[1:0], is_write, addr[19:0], w_data[15:0]}
    logic [38:0] req_buffer [0:31];
    logic [4:0]  buf_ptr_f, buf_ptr_i;
    logic [5:0]  fifo_cnt;
    assign o_ready = (fifo_cnt <= 28);

    logic [38:0] req_p1, req_p2, req_p3, req_p4;

    logic [5:0] ptr_p1 = buf_ptr_f + 1;
    logic [5:0] ptr_p2 = buf_ptr_f + 2;
    logic [5:0] ptr_p3 = buf_ptr_f + 3;
    logic [5:0] ptr_p4 = buf_ptr_f + 4;

    always_comb begin
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
    end

    always_ff @(posedge i_clk or posedge i_rst) begin
        if (i_rst) begin
            buf_ptr_f <= 0;
            buf_ptr_i <= 0;
            fifo_cnt  <= 0;
        end else begin
            case (req_cnt)
                3'd1 : begin
                    if (fifo_cnt < 32) begin
                        req_buffer[buf_ptr_f] <= req_p1;
                        buf_ptr_f             <= ptr_p1[4:0];
                        fifo_cnt              <= fifo_cnt + 1;
                    end
                end
                3'd2 : begin
                    if (fifo_cnt < 31) begin
                        req_buffer[buf_ptr_f]     <= req_p1;
                        req_buffer[ptr_p1[4:0]]   <= req_p2;
                        buf_ptr_f                 <= ptr_p2[4:0];
                        fifo_cnt                  <= fifo_cnt + 2;
                    end
                end
                3'd3 : begin
                    if (fifo_cnt < 30) begin
                        req_buffer[buf_ptr_f]     <= req_p1;
                        req_buffer[ptr_p1[4:0]]   <= req_p2;
                        req_buffer[ptr_p2[4:0]]   <= req_p3;
                        buf_ptr_f                 <= ptr_p3[4:0];
                        fifo_cnt                  <= fifo_cnt + 3;
                    end
                end
                3'd4 : begin
                    if (fifo_cnt < 29) begin
                        req_buffer[buf_ptr_f]     <= req_p1;
                        req_buffer[ptr_p1[4:0]]   <= req_p2;
                        req_buffer[ptr_p2[4:0]]   <= req_p3;
                        req_buffer[ptr_p3[4:0]]   <= req_p4;
                        buf_ptr_f                 <= ptr_p4[4:0];
                        fifo_cnt                  <= fifo_cnt + 4;
                    end
                end
                default : begin
                    // do nothing
                end
            endcase
        end
    end
endmodule