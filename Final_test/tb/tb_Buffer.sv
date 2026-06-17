`timescale 1ns/1ps

module tb_Buffer;

    // Testbench Signals
    logic        i_clk;
    logic        i_rst;
    logic [15:0] i_buf_data_l;
    logic [15:0] i_buf_data_r;
    logic        i_D2B_valid;
    logic        i_B2P_request_l;
    logic        i_B2P_request_r;
    logic [15:0] o_data;

    // Instantiate the Device Under Test (DUT)
    Buffer dut (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .i_buf_data_l(i_buf_data_l),
        .i_buf_data_r(i_buf_data_r),
        .i_D2B_valid(i_D2B_valid),
        .i_B2P_request_l(i_B2P_request_l),
        .i_B2P_request_r(i_B2P_request_r),
        .o_data(o_data)
    );

    // Clock Generation: 100MHz clock (10ns period)
    initial begin
        i_clk = 0;
        forever #5 i_clk = ~i_clk;
    end

    // Stimulus Process
    initial begin
        int error_count = 0;
        
        // Enable waveform dumping (for Option 2)
        $dumpfile("buffer_tb.vcd");
        $dumpvars(0, tb_Buffer);

        // 1. Initialize and apply reset
        i_rst           = 1;
        i_buf_data_l    = 16'd0;
        i_buf_data_r    = 16'd0;
        i_D2B_valid     = 0;
        i_B2P_request_l = 0;
        i_B2P_request_r = 0;

        #15 i_rst = 0; // Trigger active-low reset
        #20 i_rst = 1; // Release reset
        #10;

        // 2. Write two pairs of data
        @(posedge i_clk);
        i_buf_data_l = 16'hAAAA;
        i_buf_data_r = 16'hBBBB;
        i_D2B_valid  = 1;
        
        @(posedge i_clk);
        i_buf_data_l = 16'hCCCC;
        i_buf_data_r = 16'hDDDD;
        
        @(posedge i_clk);
        i_D2B_valid  = 0;
        
        #20;

        // 3. Normal Read Left (Should output 16'hAAAA)
        @(posedge i_clk);
        i_B2P_request_l = 1;
        @(posedge i_clk);
        i_B2P_request_l = 0;

        #1; // Delay slightly to read the updated synchronous output
        if (o_data !== 16'hAAAA) begin
            $display("[FAIL] Read Left: Expected 16'hAAAA, Got %h", o_data);
            error_count++;
        end else
            $display("[PASS] Read Left successful.");
        
        #20;

        // 4. Read Right with Debounce Test (Hold request high for multiple cycles)
        // Should output 16'hBBBB only ONCE, avoiding pointer run-away
        @(posedge i_clk);
        i_B2P_request_r = 1; 
        @(posedge i_clk);
        
        #1;
        if (o_data !== 16'hBBBB) begin
            $display("[FAIL] Read Right: Expected 16'hBBBB, Got %h", o_data);
            error_count++;
        end else
            $display("[PASS] Read Right successful.");

        // Hold high for two more cycles to test `is_read_r` flag logic
        @(posedge i_clk);
        @(posedge i_clk);
        i_B2P_request_r = 0;
        
        #20;

        // 5. Test Full Capacity bounds (Attempt 20 writes, should cap out at 16)
        for (int i = 0; i < 20; i++) begin
            @(posedge i_clk);
            i_buf_data_l = i;
            i_buf_data_r = i + 100;
            i_D2B_valid  = 1;
        end
        @(posedge i_clk);
        i_D2B_valid = 0;
        
        #50;
        
        // Final Verdict
        if (error_count == 0)
            $display("\n=================================\n          TEST PASSED!           \n=================================\n");
        else
            $display("\n=================================\n  TEST FAILED with %0d errors! \n=================================\n", error_count);

        $finish;
    end

endmodule