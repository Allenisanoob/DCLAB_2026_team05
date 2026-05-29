`timescale 1ns/1ps

module tb_Noise_Gate;

    // Inputs
    logic i_clk;
    logic i_rst;
    logic i_prev_valid;
    logic signed [15:0] i_data;
    logic [7:0] i_rise_rate;
    logic [7:0] i_decay_rate;
    logic [15:0] i_hold;
    logic [14:0] i_threshold_lo;
    logic [14:0] i_threshold_hi;

    // Outputs
    logic o_next_valid;
    logic signed [15:0] o_data;

    // Instantiate the Unit Under Test (UUT)
    Noise_Gate uut (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .i_prev_valid(i_prev_valid),
        .i_data(i_data),
        .i_rise_rate(i_rise_rate),
        .i_decay_rate(i_decay_rate),
        .i_hold(i_hold),
        .i_threshold_lo(i_threshold_lo),
        .i_threshold_hi(i_threshold_hi),
        .o_next_valid(o_next_valid),
        .o_data(o_data)
    );

    // Clock generation (100MHz)
    always #5 i_clk = ~i_clk; 

    // Helper task to mimic an audio sample arriving
    task send_sample(input signed [15:0] val);
        @(posedge i_clk);
        i_prev_valid = 1'b1;
        i_data = val;
        
        @(posedge i_clk);
        i_prev_valid = 1'b0;
        
        // Wait for the Noise Gate FSM to finish calculating
        wait(o_next_valid == 1'b1);
        
        // Print out what just happened internally
        $display("Time: %0t | In: %6d | Out: %6d | Gain: %5d | State: %0d", 
                 $time, i_data, o_data, uut.current_gain_r, uut.state_r);
                 
        // Wait a few cycles to simulate audio sample rate delay (e.g. 48kHz)
        repeat(10) @(posedge i_clk);
    endtask

    initial begin
        // Initialize Inputs
        i_clk = 0;
        i_rst = 0;
        i_prev_valid = 0;
        i_data = 0;
        
        // Setup noise gate parameters
        i_rise_rate = 8'd128;      // Fast rise
        i_decay_rate = 8'd32;      // Slower decay
        i_hold = 16'd3;            // Short hold of 3 samples for testing
        i_threshold_lo = 15'd2000; // Drop below 2000 to close gate
        i_threshold_hi = 15'd8000; // Rise above 8000 to open gate

        // Reset the system
        #20 i_rst = 1;
        $display("--- System Reset ---");
        
        // 1. Send Loud Signal -> Stays in S_NORMAL (State 0)
        $display("\n--- Sending LOUD audio (Above High Threshold) ---");
        repeat(3) send_sample(16'sd15000);
        
        // 2. Send Quiet Signal -> Drops to S_HOLD (State 1) -> S_DECAY (State 2)
        $display("\n--- Sending QUIET audio (Below Low Threshold) ---");
        repeat(20) send_sample(16'sd1000);
        
        // 3. Send Loud Signal Again -> Jumps to S_RECOVER (State 3) -> S_NORMAL (State 0)
        $display("\n--- Sending LOUD audio again to test Recovery ---");
        repeat(20) send_sample(-16'sd20000); // Test negative absolute value logic too!
        
        $display("\n--- Testbench Complete ---");
        $finish;
    end

endmodule
