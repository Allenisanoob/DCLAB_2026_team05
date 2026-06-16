module Buffer(
    input         i_clk,
    input         i_rst,
    input  [15:0] i_buf_data_l,
    input  [15:0] i_buf_data_r,
    input         i_D2B_valid,
    input         i_B2P_request_l,
    input         i_B2P_request_r,
    output [15:0] o_data,

    output [3:0]  o_l_cnt,
    output [3:0]  o_r_cnt
);
    logic [15:0] buf_data_l [0:15];
    logic [15:0] buf_data_r [0:15];
    logic [3:0]  buf_ptr_w, buf_ptr_r_l, buf_ptr_r_r;
    logic [4:0]  fifo_cnt_l, fifo_cnt_r;
    logic [15:0] out_data;
    
    logic [2:0]  req_l_sync;
    logic [2:0]  req_r_sync;
    logic        req_l_pulse, req_r_pulse;
    
    logic write_en, read_l_en, read_r_en;
    
    logic [15:0] req_l_cnt, req_r_cnt;
    logic [3:0]  req_l_tick_cnt, req_r_tick_cnt;

    assign o_data = out_data;
    assign o_l_cnt = req_l_tick_cnt;
    assign o_r_cnt = req_r_tick_cnt;
    
    always_ff @(posedge i_clk or negedge i_rst) begin
        if (!i_rst) begin
            req_l_sync <= 3'b0;
            req_r_sync <= 3'b0;
        end else begin
            req_l_sync <= {req_l_sync[1:0], i_B2P_request_l};
            req_r_sync <= {req_r_sync[1:0], i_B2P_request_r};
        end
    end

    assign req_l_pulse = req_l_sync[1] && !req_l_sync[2];
    assign req_r_pulse = req_r_sync[1] && !req_r_sync[2];
    
    assign write_en  = i_D2B_valid && (fifo_cnt_l < 16) && (fifo_cnt_r < 16);
    assign read_l_en = req_l_pulse && (fifo_cnt_l > 0);
    assign read_r_en = req_r_pulse && (fifo_cnt_r > 0);

    always_ff @(posedge i_clk or negedge i_rst) begin
        if (!i_rst) begin
            buf_ptr_w   <= 0;
            buf_ptr_r_l <= 0;
            buf_ptr_r_r <= 0;
            fifo_cnt_l  <= 0;
            fifo_cnt_r  <= 0;
            out_data    <= 0;
            req_l_cnt   <= 0;
            req_r_cnt   <= 0;
            req_l_tick_cnt <= 0;
            req_r_tick_cnt <= 0;
        end else begin
            if (write_en) begin
                buf_data_l[buf_ptr_w] <= i_buf_data_l;
                buf_data_r[buf_ptr_w] <= i_buf_data_r;
                buf_ptr_w             <= buf_ptr_w + 1;
            end
            
            if (read_l_en) begin
                out_data    <= buf_data_l[buf_ptr_r_l];
                buf_ptr_r_l <= buf_ptr_r_l + 1;
                if (req_l_cnt == 16'd47999) begin
                    req_l_cnt <= 0;
                    req_l_tick_cnt <= req_l_tick_cnt + 1;
                end else begin
                    req_l_cnt <= req_l_cnt + 1;
                end
            end
            
            else if (read_r_en) begin
                out_data    <= buf_data_r[buf_ptr_r_r];
                buf_ptr_r_r <= buf_ptr_r_r + 1;
                if (req_r_cnt == 16'd47999) begin
                    req_r_cnt <= 0;
                    req_r_tick_cnt <= req_r_tick_cnt + 1;
                end else begin
                    req_r_cnt <= req_r_cnt + 1;
                end
            end
            
            fifo_cnt_l <= fifo_cnt_l + write_en - read_l_en;
            fifo_cnt_r <= fifo_cnt_r + write_en - read_r_en;
        end
    end
endmodule

// module Buffer2(
//     input         i_clk,
//     input         i_rst,
//     input  [15:0] i_buf_data_l,
//     input  [15:0] i_buf_data_r,
//     input         i_D2B_valid,
//     input         i_B2P_request_l,
//     input         i_B2P_request_r,
//     output [15:0] o_data
// );
//     logic [15:0] buf_data_l [0:15];
//     logic [15:0] buf_data_r [0:15];
//     logic [3:0]  buf_ptr_w, buf_ptr_r_l, buf_ptr_r_r;
//     logic [4:0]  fifo_cnt_l, fifo_cnt_r;
//     logic [15:0] out_data;
    
//     logic [2:0]  req_l_sync;
//     logic [2:0]  req_r_sync;
//     logic        req_l_pulse, req_r_pulse;
    
//     logic write_en, read_l_en, read_r_en;

//     assign o_data = out_data;
    
//     always_ff @(posedge i_clk or negedge i_rst) begin
//         if (!i_rst) begin
//             req_l_sync <= 3'b0;
//             req_r_sync <= 3'b0;
//         end else begin
//             req_l_sync <= {req_l_sync[1:0], i_B2P_request_l};
//             req_r_sync <= {req_r_sync[1:0], i_B2P_request_r};
//         end
//     end

//     assign req_l_pulse = req_l_sync[1] && !req_l_sync[2];
//     assign req_r_pulse = req_r_sync[1] && !req_r_sync[2];
    
//     assign write_en  = i_D2B_valid && (fifo_cnt_l < 16) && (fifo_cnt_r < 16);

//     assign read_l_en = req_l_pulse && (fifo_cnt_l > 0);
//     assign read_r_en = req_r_pulse && (fifo_cnt_r > 0);

//     always_ff @(posedge i_clk or negedge i_rst) begin
//         if (!i_rst) begin
//             buf_ptr_w   <= 0;
//             buf_ptr_r_l <= 0;
//             buf_ptr_r_r <= 0;
//             fifo_cnt_l  <= 0;
//             fifo_cnt_r  <= 0;
//             out_data    <= 0;
//         end else begin
//             if (write_en) begin
//                 buf_data_l[buf_ptr_w] <= i_buf_data_l;
//                 buf_data_r[buf_ptr_w] <= i_buf_data_r;
//                 buf_ptr_w             <= buf_ptr_w + 1;
//             end
            
//             if (read_l_en) begin
//                 out_data    <= buf_data_l[buf_ptr_r_l];
//                 buf_ptr_r_l <= buf_ptr_r_l + 1;
//             end else if (read_r_en) begin
//                 out_data    <= buf_data_r[buf_ptr_r_r];
//                 buf_ptr_r_r <= buf_ptr_r_r + 1;
//             end
            
//             fifo_cnt_l <= fifo_cnt_l + write_en - read_l_en;
//             fifo_cnt_r <= fifo_cnt_r + write_en - read_r_en;
//         end
//     end
// endmodule

// module Buffer(
//     input         i_clk,
//     input         i_rst,
//     input  [15:0] i_buf_data_l,
//     input  [15:0] i_buf_data_r,
//     input         i_D2B_valid,
//     input         i_B2P_request_l,
//     input         i_B2P_request_r,
//     output [15:0] o_data,
//     output [3:0]  o_l_cnt,
//     output [3:0]  o_r_cnt
// );
//     logic [15:0] buf_data_l [0:15];
//     logic [15:0] buf_data_r [0:15];
//     logic [3:0]  buf_ptr_w, buf_ptr_r_l, buf_ptr_r_r;
//     logic [4:0]  fifo_cnt_l, fifo_cnt_r;
//     logic [15:0] out_data;
//     logic        is_read_l, is_read_r;
    
//     logic write_en, read_l_en, read_r_en;
    
//     logic [15:0] req_l_cnt, req_r_cnt;
//     logic [3:0]  req_l_tick_cnt, req_r_tick_cnt;

//     assign o_data = out_data;
//     assign o_l_cnt = req_l_tick_cnt;
//     assign o_r_cnt = req_r_tick_cnt;
    
//     assign write_en  = i_D2B_valid && (fifo_cnt_l < 16) && (fifo_cnt_r < 16);
//     assign read_l_en = i_B2P_request_l && (fifo_cnt_l > 0) && !is_read_l;
//     assign read_r_en = i_B2P_request_r && (fifo_cnt_r > 0) && !is_read_r;

//     always_ff @(posedge i_clk or negedge i_rst) begin
//         if (!i_rst) begin
//             buf_ptr_w   <= 0;
//             buf_ptr_r_l <= 0;
//             buf_ptr_r_r <= 0;
//             fifo_cnt_l  <= 0;
//             fifo_cnt_r  <= 0;
//             out_data    <= 0;
//             is_read_l   <= 0;
//             is_read_r   <= 0;
//             req_l_cnt   <= 0;
//             req_r_cnt   <= 0;
//             req_l_tick_cnt <= 0;
//             req_r_tick_cnt <= 0;
//         end else begin
//             if (!i_B2P_request_l) is_read_l <= 0;
//             if (!i_B2P_request_r) is_read_r <= 0;

//             if (write_en) begin
//                 buf_data_l[buf_ptr_w] <= i_buf_data_l;
//                 buf_data_r[buf_ptr_w] <= i_buf_data_r;
//                 buf_ptr_w             <= buf_ptr_w + 1;
//             end
            
//             if (read_l_en) begin
//                 out_data    <= buf_data_l[buf_ptr_r_l];
//                 buf_ptr_r_l <= buf_ptr_r_l + 1;
//                 is_read_l   <= 1;
//                 if (req_l_cnt == 16'd47999) begin
//                     req_l_cnt <= 0;
//                     req_l_tick_cnt <= req_l_tick_cnt + 1;
//                 end else begin
//                     req_l_cnt <= req_l_cnt + 1;
//                 end
//             end else if (read_r_en) begin
//                 out_data    <= buf_data_r[buf_ptr_r_r];
//                 buf_ptr_r_r <= buf_ptr_r_r + 1;
//                 is_read_r   <= 1;
//                 if (req_r_cnt == 16'd47999) begin
//                     req_r_cnt <= 0;
//                     req_r_tick_cnt <= req_r_tick_cnt + 1;
//                 end else begin
//                     req_r_cnt <= req_r_cnt + 1;
//                 end
//             end
            
//             fifo_cnt_l <= fifo_cnt_l + write_en - read_l_en;
//             fifo_cnt_r <= fifo_cnt_r + write_en - read_r_en;
//         end
//     end
// endmodule