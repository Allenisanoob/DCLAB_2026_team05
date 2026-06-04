`timescale 1ns/1ps

module Player_tb;

    // DUT inputs
    logic        i_rst;        // active-low reset in Player.sv
    logic        i_BCLK;
    logic        i_DAC_LRCK;
    logic [15:0] i_out_data;

    // DUT outputs
    wire         o_DAC_DAT;
    wire         o_B2P_request_l;
    wire         o_B2P_request_r;

    // Instantiate DUT
    Player dut (
        .i_rst           (i_rst),
        .i_BCLK          (i_BCLK),
        .i_DAC_LRCK      (i_DAC_LRCK),
        .i_out_data      (i_out_data),
        .o_DAC_DAT       (o_DAC_DAT),
        .o_B2P_request_l (o_B2P_request_l),
        .o_B2P_request_r (o_B2P_request_r)
    );

    // BCLK: 100 MHz for simulation convenience
    initial i_BCLK = 1'b0;
    always #5 i_BCLK = ~i_BCLK;

    // Print important signals
    initial begin
        $display("time\trst\tBCLK\tLRCK\tdata\tDAC_DAT\treq_l\treq_r\tstate\tcnt\tshift_reg");
        $monitor("%0t\t%b\t%b\t%b\t%h\t%b\t%b\t%b\t%0d\t%0d\t%h",
                 $time, i_rst, i_BCLK, i_DAC_LRCK, i_out_data, o_DAC_DAT,
                 o_B2P_request_l, o_B2P_request_r,
                 dut.state_r, dut.counter_r, dut.o_DAC_DAT_r);
    end

    // Waveform dump for Verdi / Novas FSDB
    // Compile and run with a simulator that supports FSDB system tasks, e.g. VCS + Verdi.
    initial begin
        $fsdbDumpfile("Player_tb.fsdb");
        $fsdbDumpvars(0, Player_tb);
        $fsdbDumpMDA();
    end

    // Reset task
    task automatic reset_dut;
        begin
            i_rst       = 1'b0;
            i_DAC_LRCK  = 1'b0;
            i_out_data  = 16'h0000;
            repeat (3) @(negedge i_BCLK);
            i_rst       = 1'b1;
            repeat (2) @(negedge i_BCLK);
        end
    endtask

    // Send one 16-bit word by creating one LRCK edge.
    // Player loads i_out_data on LRCK edge, then shifts MSB first.
    task automatic send_word(input logic [15:0] data, input logic next_lrck);
        integer k;
        logic [15:0] sampled_bits;
        begin
            i_out_data = data;

            // Create LRCK edge before a BCLK negedge, so DUT detects lrc_edge.
            #2;
            i_DAC_LRCK = next_lrck;

            // First negedge after LRCK edge: DUT loads data, output becomes data[15].
            @(negedge i_BCLK);
            #1;
            sampled_bits[15] = o_DAC_DAT;

            // Next 15 negedges shift out data[14:0].
            for (k = 14; k >= 0; k = k - 1) begin
                @(negedge i_BCLK);
                #1;
                sampled_bits[k] = o_DAC_DAT;
            end

            if (sampled_bits !== data) begin
                $error("Serial output mismatch: expected %h, got %h", data, sampled_bits);
            end else begin
                $display("PASS: shifted out %h correctly at time %0t", data, $time);
            end

            // Let state return to IDLE cleanly.
            @(negedge i_BCLK);
            #1;
        end
    endtask

    initial begin
        reset_dut();

        // Initial request should pulse once after reset depending on current LRCK.
        // LRCK=0 => left request during initial IDLE.
        repeat (2) @(negedge i_BCLK);

        // Test several patterns. LRCK toggles every word.
        send_word(16'hA5A5, 1'b1);
        send_word(16'h3C3C, 1'b0);
        send_word(16'h8001, 1'b1);
        send_word(16'h7FFE, 1'b0);

        repeat (5) @(negedge i_BCLK);
        $display("Simulation finished.");
        $finish;
    end

endmodule
