`timescale 1ns / 1ps

module tb_spi_independent;
    logic clk = 0;
    logic rst_n = 0;
    logic start = 0;
    logic [15:0] tx_data = 0;
    logic [15:0] clk_div = 0;
    logic miso = 0;
    wire sclk, mosi, cs_n, busy, done;
    wire [15:0] rx_data;
    string waveform_path;

    spi_master dut (
        .clk(clk), .rst_n(rst_n), .start(start), .tx_data(tx_data),
        .clk_div(clk_div), .miso(miso), .sclk(sclk), .mosi(mosi),
        .cs_n(cs_n), .rx_data(rx_data), .busy(busy), .done(done)
    );

    always #10 clk = ~clk; // 50 MHz

    // Optional trace for studying the same transactions in GTKWave.
    initial begin
        if ($value$plusargs("waveform=%s", waveform_path)) begin
            $dumpfile(waveform_path);
            $dumpvars(0, tb_spi_independent);
        end
    end

    task automatic check_frame(
        input logic [15:0] tx_word,
        input logic [15:0] reply_word,
        input logic [15:0] divider,
        input time half_period
    );
        time last_edge;
        @(negedge clk);
        tx_data = tx_word;
        clk_div = divider;
        miso = reply_word[15]; // Peripheral presents its first bit before SCLK rises.
        start = 1;

        @(negedge cs_n);
        last_edge = $time;
        #1;
        if ({sclk, busy, done} !== 3'b010)
            $fatal(1, "Expected mode-0 idle clock and busy on selection");

        @(negedge clk);
        start = 0;

        for (int bit_index = 15; bit_index >= 0; bit_index--) begin
            @(posedge sclk);
            if ($time - last_edge != half_period)
                $fatal(1, "Unexpected time to rising edge at bit %0d", bit_index);
            last_edge = $time;
            if ({cs_n, busy, done} !== 3'b010 || mosi !== tx_word[bit_index])
                $fatal(1, "TX %h bit %0d: MOSI=%b, expected %b",
                       tx_word, bit_index, mosi, tx_word[bit_index]);

            @(negedge sclk);
            if ($time - last_edge != half_period)
                $fatal(1, "Unexpected time to falling edge at bit %0d", bit_index);
            last_edge = $time;
            #1;
            if (bit_index > 0) begin
                if ({cs_n, busy, done} !== 3'b010)
                    $fatal(1, "Transfer ended early at bit %0d", bit_index);
                miso = reply_word[bit_index - 1];
            end
        end

        if ({sclk, cs_n, busy, done} !== 4'b0101 || rx_data !== reply_word)
            $fatal(1, "Frame completion: RX=%h, expected %h, CS=%b busy=%b done=%b",
                   rx_data, reply_word, cs_n, busy, done);

        // The completion pulse clears after one clock, and RX holds until
        // the next completed transfer. Check three idle system clocks.
        repeat (3) begin
            @(posedge clk);
            #1;
            if ({sclk, cs_n, busy, done} !== 4'b0100 || rx_data !== reply_word)
                $fatal(1, "Expected idle state and stable RX after completion");
        end
        $display("PASS: TX=%h RX=%h divider=%0d", tx_word, rx_data, divider);
    endtask

    initial begin
        repeat (3) @(negedge clk);
        if ({sclk, cs_n, busy, done} !== 4'b0100 || mosi !== 0 || rx_data !== 0)
            $fatal(1, "Unexpected reset state");
        rst_n = 1;

        check_frame(16'h96E1, 16'h4B2D, 16'd25, 500);
        check_frame(16'hAAAA, 16'h5555, 16'd2, 40);
        // Opposite constant words expose data stuck high or low.
        check_frame(16'h0000, 16'hFFFF, 16'd25, 500);
        check_frame(16'hFFFF, 16'h0000, 16'd25, 500);
        // Isolate the first and last bits at the minimum nonzero divider.
        check_frame(16'h8000, 16'h0001, 16'd1, 20);
        check_frame(16'h0001, 16'h8000, 16'd1, 20);
        // Doubling the divider doubles the expected half-period.
        check_frame(16'h1A2B, 16'hC3D4, 16'd50, 1000);
        $display("ALL 7 SPI FRAME TESTS PASSED");
        $finish;
    end

    initial begin
        #200000;
        $fatal(1, "Timed out waiting for SPI edges");
    end
endmodule
