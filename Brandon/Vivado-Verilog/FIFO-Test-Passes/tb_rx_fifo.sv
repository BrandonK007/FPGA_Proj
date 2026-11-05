
`timescale 1ns / 1ps

module tb_rx_fifo;

    // Testbench inputs to FIFO
    logic clk = 0;
    logic rst_n = 0;
    logic wr_en = 0;
    logic rd_en = 0;
    logic [15:0] wr_data = 0;

    // Outputs from FIFO
    wire [15:0] rd_data;
    wire full;
    wire empty;
    wire [8:0] count;

    // Device Under Test (DUT)
    rx_fifo dut (
        .clk(clk),
        .rst_n(rst_n),
        .wr_en(wr_en),
        .rd_en(rd_en),
        .wr_data(wr_data),
        .rd_data(rd_data),
        .full(full),
        .empty(empty),
        .count(count)
    );

    // 50 MHz clock (20 ns period)
    always #10 clk = ~clk;

    // Write one 16-bit word
    task automatic fifo_write(input logic [15:0] data);
        begin
            @(negedge clk);
            wr_data = data;
            wr_en = 1;

            @(negedge clk);
            wr_en = 0;
        end
    endtask

    // Read and check one 16-bit word
    task automatic fifo_read(input logic [15:0] expected);
        begin
            @(negedge clk);
            rd_en = 1;

            @(negedge clk);
            rd_en = 0;

            if (rd_data !== expected)
                $fatal(1,
                    "FAIL: Expected %h, received %h",
                    expected, rd_data);

            $display("PASS: Read %h", rd_data);
        end
    endtask

    initial begin
        // Initialize/reset FIFO
        repeat (5) @(posedge clk);
        @(negedge clk);
        rst_n = 1;

        // Test 1: FIFO should start empty
        if (!empty || count !== 0)
            $fatal(1, "FAIL: FIFO not empty after reset");

        $display("PASS: Reset and empty test");

        // Test 2: Write three values
        fifo_write(16'hA55A);
        fifo_write(16'h1234);
        fifo_write(16'hFFFF);

        if (count !== 3)
            $fatal(1, "FAIL: FIFO count should be 3");

        $display("PASS: Three values written");

        // Test 3: Read values in FIFO order
        fifo_read(16'hA55A);
        fifo_read(16'h1234);
        fifo_read(16'hFFFF);

        // Test 4: FIFO should now be empty
        if (!empty || count !== 0)
            $fatal(1, "FAIL: FIFO should be empty");

        $display("PASS: FIFO empty after reads");

        // Test 5: Fill FIFO to full capacity
        for (int i = 0; i < 256; i++) begin
            fifo_write(i[15:0]);
        end

        if (!full || count !== 256)
            $fatal(1, "FAIL: FIFO should be full");

        $display("PASS: FIFO full at 256 words");

        // Test 6: Try to write when full
        fifo_write(16'hDEAD);

        if (count !== 256)
            $fatal(1, "FAIL: FIFO overflow occurred");

        $display("PASS: Overflow prevented");

        // Test 7: Read back all 256 values
        for (int i = 0; i < 256; i++) begin
            fifo_read(i[15:0]);
        end

        if (!empty || count !== 0)
            $fatal(1, "FAIL: FIFO not empty at end");

        $display("--------------------------------");
        $display("ALL FIFO TESTS PASSED");
        $display("--------------------------------");

        $finish;
    end

    // Timeout protection
    initial begin
        #500000;
        $fatal(1, "FAIL: Simulation timeout");
    end

endmodule
