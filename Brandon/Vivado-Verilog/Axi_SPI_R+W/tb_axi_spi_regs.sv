
`timescale 1ns / 1ps

module tb_axi_spi_regs;

    // =========================================
    // CLOCK AND RESET
    // =========================================
    logic s_axi_aclk = 0;
    logic s_axi_aresetn = 0;

    // 50 MHz clock
    always #10 s_axi_aclk = ~s_axi_aclk;

    // =========================================
    // AXI WRITE SIGNALS
    // =========================================
    logic [7:0]  s_axi_awaddr = 0;
    logic [2:0]  s_axi_awprot = 0;
    logic        s_axi_awvalid = 0;
    wire         s_axi_awready;

    logic [31:0] s_axi_wdata = 0;
    logic [3:0]  s_axi_wstrb = 0;
    logic        s_axi_wvalid = 0;
    wire         s_axi_wready;

    wire [1:0]   s_axi_bresp;
    wire         s_axi_bvalid;
    logic        s_axi_bready = 0;

    // =========================================
    // AXI READ SIGNALS
    // =========================================
    logic [7:0]  s_axi_araddr = 0;
    logic [2:0]  s_axi_arprot = 0;
    logic        s_axi_arvalid = 0;
    wire         s_axi_arready;

    wire [31:0]  s_axi_rdata;
    wire [1:0]   s_axi_rresp;
    wire         s_axi_rvalid;
    logic        s_axi_rready = 0;

    // =========================================
    // SPI INTERFACE
    // =========================================
    wire        spi_start;
    wire [15:0] spi_tx_data;
    wire [15:0] spi_clk_div;

    logic spi_busy = 0;
    logic spi_done = 0;

    // =========================================
    // FIFO INTERFACE
    // =========================================
    wire        fifo_rd_en;
    wire        fifo_flush;
    wire [15:0] fifo_rd_data;
    wire        fifo_empty;
    wire        fifo_full;
    wire [8:0]  fifo_count;

    // Testbench injects received SPI words
    logic        fifo_wr_en = 0;
    logic [15:0] fifo_wr_data = 0;

    // Synchronous reset/flush for the FIFO
    wire fifo_rst_n =
        s_axi_aresetn && !fifo_flush;

    // =========================================
    // AXI REGISTER MODULE
    // =========================================
    axi_spi_regs dut (
        .s_axi_aclk(s_axi_aclk),
        .s_axi_aresetn(s_axi_aresetn),

        .s_axi_awaddr(s_axi_awaddr),
        .s_axi_awprot(s_axi_awprot),
        .s_axi_awvalid(s_axi_awvalid),
        .s_axi_awready(s_axi_awready),

        .s_axi_wdata(s_axi_wdata),
        .s_axi_wstrb(s_axi_wstrb),
        .s_axi_wvalid(s_axi_wvalid),
        .s_axi_wready(s_axi_wready),

        .s_axi_bresp(s_axi_bresp),
        .s_axi_bvalid(s_axi_bvalid),
        .s_axi_bready(s_axi_bready),

        .s_axi_araddr(s_axi_araddr),
        .s_axi_arprot(s_axi_arprot),
        .s_axi_arvalid(s_axi_arvalid),
        .s_axi_arready(s_axi_arready),

        .s_axi_rdata(s_axi_rdata),
        .s_axi_rresp(s_axi_rresp),
        .s_axi_rvalid(s_axi_rvalid),
        .s_axi_rready(s_axi_rready),

        .spi_start(spi_start),
        .spi_tx_data(spi_tx_data),
        .spi_clk_div(spi_clk_div),
        .spi_busy(spi_busy),
        .spi_done(spi_done),

        .fifo_rd_en(fifo_rd_en),
        .fifo_flush(fifo_flush),
        .fifo_rd_data(fifo_rd_data),
        .fifo_empty(fifo_empty),
        .fifo_full(fifo_full),
        .fifo_count(fifo_count)
    );

    // =========================================
    // ACTUAL 256 x 16 RX FIFO
    // =========================================
    rx_fifo fifo_dut (
        .clk(s_axi_aclk),
        .rst_n(fifo_rst_n),

        .wr_en(fifo_wr_en),
        .rd_en(fifo_rd_en),
        .wr_data(fifo_wr_data),

        .rd_data(fifo_rd_data),
        .full(fifo_full),
        .empty(fifo_empty),
        .count(fifo_count)
    );

    // Count start pulses
    integer start_pulses = 0;

    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn)
            start_pulses <= 0;
        else if (spi_start)
            start_pulses <= start_pulses + 1;
    end

    // =========================================
    // AXI WRITE TASK
    // =========================================
    task automatic axi_write(
        input logic [7:0]  addr,
        input logic [31:0] data,
        input logic [3:0]  strb,
        input logic [1:0]  expected_resp,
        input integer      address_delay,
        input integer      data_delay
    );
        begin
            @(negedge s_axi_aclk);
            s_axi_bready = 0;

            // Send address and data independently
            fork
                begin
                    repeat (address_delay)
                        @(negedge s_axi_aclk);

                    s_axi_awaddr = addr;
                    s_axi_awvalid = 1;

                    do begin
                        @(posedge s_axi_aclk);
                    end while (!s_axi_awready);

                    @(negedge s_axi_aclk);
                    s_axi_awvalid = 0;
                end

                begin
                    repeat (data_delay)
                        @(negedge s_axi_aclk);

                    s_axi_wdata = data;
                    s_axi_wstrb = strb;
                    s_axi_wvalid = 1;

                    do begin
                        @(posedge s_axi_aclk);
                    end while (!s_axi_wready);

                    @(negedge s_axi_aclk);
                    s_axi_wvalid = 0;
                end
            join

            wait (s_axi_bvalid === 1'b1);

            if (s_axi_bresp !== expected_resp)
                $fatal(1,
                    "WRITE FAIL addr=%h expected=%b got=%b",
                    addr, expected_resp, s_axi_bresp);

            // Stall write response
            repeat (3) begin
                @(posedge s_axi_aclk);
                if (!s_axi_bvalid ||
                    s_axi_bresp !== expected_resp)
                    $fatal(1, "WRITE response unstable");
            end

            // Accept write response
            @(negedge s_axi_aclk);
            s_axi_bready = 1;

            @(negedge s_axi_aclk);
            s_axi_bready = 0;

            if (s_axi_bvalid !== 0)
                $fatal(1, "BVALID failed to clear");

            $display("PASS WRITE addr=%h data=%h",
                     addr, data);
        end
    endtask

    // =========================================
    // AXI READ TASK
    // =========================================
    task automatic axi_read(
        input logic [7:0]  addr,
        input logic [31:0] expected_data,
        input logic [1:0]  expected_resp
    );
        begin
            @(negedge s_axi_aclk);

            s_axi_araddr = addr;
            s_axi_arvalid = 1;
            s_axi_rready = 0;

            // Read address handshake
            do begin
                @(posedge s_axi_aclk);
            end while (!s_axi_arready);

            @(negedge s_axi_aclk);
            s_axi_arvalid = 0;

            // Wait for read response
            wait (s_axi_rvalid === 1'b1);

            if (s_axi_rdata !== expected_data)
                $fatal(1,
                    "READ FAIL addr=%h expected=%h got=%h",
                    addr, expected_data, s_axi_rdata);

            if (s_axi_rresp !== expected_resp)
                $fatal(1,
                    "READ RESP FAIL addr=%h expected=%b got=%b",
                    addr, expected_resp, s_axi_rresp);

            // Stall response and verify stability
            repeat (3) begin
                @(posedge s_axi_aclk);

                if (!s_axi_rvalid ||
                    s_axi_rdata !== expected_data ||
                    s_axi_rresp !== expected_resp)
                    $fatal(1, "READ response unstable");
            end

            // Accept response
            @(negedge s_axi_aclk);
            s_axi_rready = 1;

            @(negedge s_axi_aclk);
            s_axi_rready = 0;

            if (s_axi_rvalid !== 0)
                $fatal(1, "RVALID failed to clear");

            $display("PASS READ  addr=%h data=%h",
                     addr, expected_data);
        end
    endtask

    // =========================================
    // FIFO WRITE TASK
    // =========================================
    task automatic push_fifo(
        input logic [15:0] data
    );
        begin
            @(negedge s_axi_aclk);
            fifo_wr_data = data;
            fifo_wr_en = 1;

            @(negedge s_axi_aclk);
            fifo_wr_en = 0;
        end
    endtask

    // =========================================
    // MAIN TEST SEQUENCE
    // =========================================
    initial begin

        // Reset
        repeat (5) @(posedge s_axi_aclk);
        @(negedge s_axi_aclk);
        s_axi_aresetn = 1;

        if (spi_tx_data !== 0 ||
            spi_clk_div !== 25 ||
            !fifo_empty)
            $fatal(1, "RESET FAILED");

        $display("PASS: RESET");

        // -------------------------------------
        // WRITE TESTS
        // -------------------------------------

        // Write transmit data
        axi_write(8'h0C, 32'h0000A55A,
                  4'b0011, 2'b00, 0, 0);

        if (spi_tx_data !== 16'hA55A)
            $fatal(1, "TX_DATA write failed");

        // Change clock divider
        axi_write(8'h08, 32'd40,
                  4'b0011, 2'b00, 0, 2);

        if (spi_clk_div !== 16'd40)
            $fatal(1, "CLK_DIV write failed");

        // Data arrives before address
        axi_write(8'h0C, 32'h00001234,
                  4'b0011, 2'b00, 3, 0);

        // Partial write
        axi_write(8'h0C, 32'h000000AA,
                  4'b0001, 2'b00, 0, 0);

        if (spi_tx_data !== 16'h12AA)
            $fatal(1, "WSTRB failed");

        // Invalid write address
        axi_write(8'h40, 32'hDEADBEEF,
                  4'b1111, 2'b10, 0, 0);

        // -------------------------------------
        // READ TESTS
        // -------------------------------------

        axi_read(8'h0C, 32'h000012AA, 2'b00);
        axi_read(8'h08, 32'd40,       2'b00);
        axi_read(8'h04, 32'h00000004, 2'b00);
        axi_read(8'h14, 32'd0,        2'b00);
        axi_read(8'h00, 32'd0,        2'b00);

        // Invalid read
        axi_read(8'h40, 32'd0, 2'b10);

        // Empty FIFO read must fail
        axi_read(8'h10, 32'd0, 2'b10);

        $display("PASS: BASIC AXI READ/WRITE");

        // -------------------------------------
        // SPI START TEST
        // -------------------------------------

        axi_write(8'h00, 32'h1,
                  4'b0001, 2'b00, 0, 0);

        if (start_pulses !== 1)
            $fatal(1, "START pulse count failed");

        $display("PASS: SPI START PULSE");

        // Reject start when busy
        @(negedge s_axi_aclk);
        spi_busy = 1;

        axi_write(8'h00, 32'h1,
                  4'b0001, 2'b00, 0, 0);

        if (start_pulses !== 1)
            $fatal(1, "START accepted while busy");

        axi_read(8'h04, 32'h00000025, 2'b00);

        @(negedge s_axi_aclk);
        spi_busy = 0;

        // Clear sticky errors
        axi_write(8'h00, 32'h4,
                  4'b0001, 2'b00, 0, 0);

        axi_read(8'h04, 32'h00000004, 2'b00);

        $display("PASS: BUSY/ERROR HANDLING");

        // -------------------------------------
        // SPI DONE STICKY STATUS
        // -------------------------------------

        @(negedge s_axi_aclk);
        spi_done = 1;

        @(negedge s_axi_aclk);
        spi_done = 0;

        axi_read(8'h04, 32'h00000006, 2'b00);

        // Clear DONE
        axi_write(8'h00, 32'h4,
                  4'b0001, 2'b00, 0, 0);

        axi_read(8'h04, 32'h00000004, 2'b00);

        $display("PASS: SPI DONE STATUS");

        // -------------------------------------
        // REAL FIFO READ TEST
        // -------------------------------------

        push_fifo(16'hBEEF);
        push_fifo(16'h1234);

        axi_read(8'h14, 32'd2, 2'b00);

        // Read oldest word first
        axi_read(8'h10, 32'h0000BEEF, 2'b00);

        axi_read(8'h14, 32'd1, 2'b00);

        axi_read(8'h10, 32'h00001234, 2'b00);

        axi_read(8'h14, 32'd0, 2'b00);

        // Empty FIFO must reject another read
        axi_read(8'h10, 32'd0, 2'b10);

        $display("PASS: FIFO READ ORDERING");

        // -------------------------------------
        // FULL FIFO / OVERFLOW STATUS
        // -------------------------------------

        for (int i = 0; i < 256; i++)
            push_fifo(i[15:0]);

        axi_read(8'h14, 32'd256, 2'b00);

        // START rejected when FIFO full
        axi_write(8'h00, 32'h1,
                  4'b0001, 2'b00, 0, 0);

        if (start_pulses !== 1)
            $fatal(1, "START accepted with full FIFO");

        // Bits 5, 4, 3 set: ERROR, OVERFLOW, FULL
        axi_read(8'h04, 32'h00000038, 2'b00);

        $display("PASS: FIFO FULL / OVERFLOW");

        // -------------------------------------
        // CLEAR FLAGS AND FLUSH FIFO
        // -------------------------------------

        axi_write(8'h00, 32'h4,
                  4'b0001, 2'b00, 0, 0);

        // FULL remains set, sticky errors clear
        axi_read(8'h04, 32'h00000008, 2'b00);

        // CONTROL bit 1 flushes FIFO
        axi_write(8'h00, 32'h2,
                  4'b0001, 2'b00, 0, 0);

        axi_read(8'h14, 32'd0, 2'b00);
        axi_read(8'h04, 32'h00000004, 2'b00);

        $display("PASS: FIFO FLUSH");

        $display("--------------------------------");
        $display("ALL AXI READ/WRITE TESTS PASSED");
        $display("--------------------------------");

        $finish;
    end

    // Timeout protection
    initial begin
        #200000;
        $fatal(1, "SIMULATION TIMEOUT");
    end

endmodule
