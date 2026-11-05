
`timescale 1ns / 1ps

module tb_spi_master;

    logic clk = 0;
    logic rst_n = 0;
    logic start = 0;
    logic [15:0] tx_data = 0;
    logic [15:0] clk_div = 25;

    logic sclk;
    logic mosi;
    logic cs_n;
    logic [15:0] rx_data;
    logic busy;
    logic done;

    // Loopback: transmitted data returns to receiver
    wire miso = mosi;

    spi_master dut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .tx_data(tx_data),
        .clk_div(clk_div),
        .miso(miso),
        .sclk(sclk),
        .mosi(mosi),
        .cs_n(cs_n),
        .rx_data(rx_data),
        .busy(busy),
        .done(done)
    );

    // 50 MHz clock
    always #10 clk = ~clk;

    initial begin
        // Apply reset
        repeat (5) @(posedge clk);
        @(negedge clk);
        rst_n = 1;

        // Start transfer
        @(negedge clk);
        tx_data = 16'hFFFF;
        start = 1;

        @(negedge clk);
        start = 0;

        // Wait for transfer completion
        wait(done == 1);
        #1;

        if (rx_data == 16'hFFFF)
            $display("PASS: Received %h", rx_data);
        else
            $fatal(1, "FAIL: Received %h", rx_data);

        $finish;
    end

    // Simulation timeout
    initial begin
        #100000;
        $fatal(1, "Simulation timed out");
    end

endmodule
