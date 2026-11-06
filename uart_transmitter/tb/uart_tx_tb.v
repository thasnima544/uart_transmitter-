
`timescale 1ns/1ps

module uart_tx_tb;

    reg clk;
    reg rst;
    reg tx_start;
    reg [7:0] tx_data;

    wire tx;
    wire busy;
    wire tx_done;

    integer i;
    reg [7:0] test_data;

    uart_tx #(
        .CLKS_PER_BIT(4)
    ) DUT (
        .clk(clk),
        .rst(rst),
        .tx_start(tx_start),
        .tx_data(tx_data),
        .tx(tx),
        .busy(busy),
        .tx_done(tx_done)
    );

    // 10 ns clock period
    always #5 clk = ~clk;

    initial begin

        $dumpfile("sim/uart_waveform.vcd");
        $dumpvars(0, uart_tx_tb);

        clk = 0;
        rst = 1;
        tx_start = 0;
        tx_data = 0;
        test_data = 8'hA5;

        // Reset
        repeat (2) @(posedge clk);
        #1;
        rst = 0;

        $display("RESET TEST PASSED");

        // Start transmission
        @(negedge clk);
        tx_data = test_data;
        tx_start = 1;

        @(negedge clk);
        tx_start = 0;

        // Check start bit
        @(negedge clk);
        if (tx !== 1'b0)
            $fatal(1, "START BIT TEST FAILED");

        $display("START BIT TEST PASSED");

        // Check 8 data bits, LSB first
        for (i = 0; i < 8; i = i + 1) begin

            repeat (4) @(negedge clk);

            if (tx !== test_data[i]) begin
                $display("ERROR: Bit %0d expected %b got %b",
                         i, test_data[i], tx);
                $fatal(1, "DATA BIT TEST FAILED");
            end

            $display("DATA BIT %0d PASS: %b", i, tx);
        end

        // Check stop bit
        repeat (4) @(negedge clk);

        if (tx !== 1'b1)
            $fatal(1, "STOP BIT TEST FAILED");

        $display("STOP BIT TEST PASSED");

        // Wait for transmission completion
        wait (tx_done == 1'b1);
        #1;

        if (busy !== 1'b0)
            $fatal(1, "BUSY SIGNAL TEST FAILED");

        $display("TX DONE TEST PASSED");
        $display("------------------------------");
        $display("ALL UART TESTS PASSED!");
        $display("------------------------------");

        $finish;
    end

endmodule
