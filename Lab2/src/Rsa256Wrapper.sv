module Rsa256Wrapper (
    input         avm_rst,
    input         avm_clk,
    output  [4:0] avm_address,
    output        avm_read,
    input  [31:0] avm_readdata,
    output        avm_write,
    output [31:0] avm_writedata,
    input         avm_waitrequest
);

localparam RX_BASE     = 0*4;
localparam TX_BASE     = 1*4;
localparam STATUS_BASE = 2*4;
localparam TX_OK_BIT   = 6;
localparam RX_OK_BIT   = 7;

// Feel free to design your own FSM!
localparam S_GET_KEY = 0;
localparam S_GET_DATA = 1;
localparam S_WAIT_CALCULATE = 2;
localparam S_SEND_DATA = 3;

logic [255:0] n_r, n_w, d_r, d_w, enc_r, enc_w, dec_r, dec_w;
logic [1:0] state_r, state_w;
logic [6:0] bytes_counter_r, bytes_counter_w;
logic [4:0] avm_address_r, avm_address_w;
logic avm_read_r, avm_read_w, avm_write_r, avm_write_w;

logic rsa_start_r, rsa_start_w;
logic rsa_finished;
logic [255:0] rsa_dec;

assign avm_address = avm_address_r;
assign avm_read = avm_read_r;
assign avm_write = avm_write_r;
assign avm_writedata = dec_r[247-:8];

Rsa256Core rsa256_core(
    .i_clk(avm_clk),
    .i_rst(avm_rst),
    .i_start(rsa_start_r),
    .i_a(enc_r),
    .i_d(d_r),
    .i_n(n_r),
    .o_a_pow_d(rsa_dec),
    .o_finished(rsa_finished)
);

task StartRead;
    input [4:0] addr;
    begin
        avm_read_w = 1;
        avm_write_w = 0;
        avm_address_w = addr;
    end
endtask
task StartWrite;
    input [4:0] addr;
    begin
        avm_read_w = 0;
        avm_write_w = 1;
        avm_address_w = addr;
    end
endtask

always_comb begin
    n_w = n_r;
    d_w = d_r;
    enc_w = enc_r;
    dec_w = dec_r;
    avm_address_w = avm_address_r;
    avm_read_w = avm_read_r;
    avm_write_w = avm_write_r;
    state_w = state_r;
    bytes_counter_w = bytes_counter_r;
    rsa_start_w = rsa_start_r;

    case(state_r)
        S_GET_KEY: begin
            if (!avm_waitrequest) begin
                case(avm_address)
                    RX_BASE: begin
                        if (bytes_counter_w < 32) begin
                            // if it's the last byte, switch state to get the data
                            if (bytes_counter_r == 0) begin
                                state_w = S_GET_DATA;
                            end
                            // shift and write 8 bits of data to d_r
                            d_w[255:8] = d_r[247:0];
                            d_w[7:0] = avm_readdata[7:0];
                        end else begin
                            // shift and write 8 bits of data to n_r
                            n_w[255:8] = n_r[247:0];
                            n_w[7:0] = avm_readdata[7:0];
                        end
                        bytes_counter_w = bytes_counter_r - 1;      // update bytes_counter_r
                        StartRead(STATUS_BASE);                     // go back to checking rrdy
                    end
                    STATUS_BASE: begin
                        // if (rrdy == 1), read 8 bits on the next cycle
                        if (avm_readdata[7]) begin
                            StartRead(RX_BASE);
                        end
                        // if its the first cycle in this state, prepare to recieve 64 bytes or data
                        if (bytes_counter_r < 0) begin  
                            bytes_counter_w = 63;
                        end
                    end
                endcase
            end
        end

        S_GET_DATA: begin
            if (!avm_waitrequest) begin
                case(avm_address)
                    RX_BASE: begin
                        // if it's the last 8 bits, switch state and start calculating
                        if (bytes_counter_r == 0) begin
                            state_w = S_WAIT_CALCULATE;
                            rsa_start_w = 1;
                        end
                        // shift and write 8 bits of data to enc_r
                        enc_w[255:8] = enc_r[247:0];
                        enc_w[7:0] = avm_readdata[7:0];
                        bytes_counter_w = bytes_counter_r - 1;      // update bytes_counter_r
                        StartRead(STATUS_BASE);                     // go back to checking rrdy
                    end
                    STATUS_BASE: begin
                        // if (rrdy == 1), read 8 bits on the next cycle
                        if (avm_readdata[7]) begin
                            StartRead(RX_BASE);
                        end
                        // if its the first cycle in this state, prepare to recieve 32 bytes or data
                        if (bytes_counter_r < 0) begin  
                            bytes_counter_w = 31;
                        end
                    end
                endcase
            end
        end

        S_WAIT_CALCULATE: begin
            // wait until the calculation is done
            if (rsa_finished) begin
                // copy the data into dec_r
                dec_w = rsa_dec;
                // switch state to send the data
                state_w = S_SEND_DATA;
            end
        end

        S_SEND_DATA: begin
            if (!avm_waitrequest) begin
                case(avm_address)
                    TX_BASE: begin
                        // if it's the last 8 bits, switch state to key the next key
                        if (bytes_counter_r == 0) begin
                            state_w = S_GET_KEY;
                        end
                        dec_w[247:8] = dec_r[239:0];                // shift and send 8 bits of data in dec_r
                        bytes_counter_w = bytes_counter_r - 1;      // update bytes_counter_r                     
                        StartRead(STATUS_BASE);                     // go back to checking rrdy 
                    end
                    STATUS_BASE: begin
                        // if (trdy == 1), send 8 bits on the next cycle
                        if (avm_readdata[6]) begin
                            StartWrite(TX_BASE);
                        end
                        // if its the first cycle in this state, prepare to send 32 bytes or data
                        if (bytes_counter_r < 0) begin  
                            bytes_counter_w = 31;
                        end
                    end
                endcase
            end
        end
    endcase
end

always_ff @(posedge avm_clk or posedge avm_rst) begin
    if (avm_rst) begin
        n_r <= 0;
        d_r <= 0;
        enc_r <= 0;
        dec_r <= 0;
        avm_address_r <= STATUS_BASE;
        avm_read_r <= 1;
        avm_write_r <= 0;
        state_r <= S_GET_KEY;
        bytes_counter_r <= 63;
        rsa_start_r <= 0;
    end else begin
        n_r <= n_w;
        d_r <= d_w;
        enc_r <= enc_w;
        dec_r <= dec_w;
        avm_address_r <= avm_address_w;
        avm_read_r <= avm_read_w;
        avm_write_r <= avm_write_w;
        state_r <= state_w;
        bytes_counter_r <= bytes_counter_w;
        rsa_start_r <= rsa_start_w;
    end
end

endmodule
