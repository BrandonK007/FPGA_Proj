
module axi_spi_regs (
    input  logic        s_axi_aclk,
    input  logic        s_axi_aresetn,

    // AXI write address
    input  logic [7:0]  s_axi_awaddr,
    input  logic [2:0]  s_axi_awprot,
    input  logic        s_axi_awvalid,
    output logic        s_axi_awready,

    // AXI write data
    input  logic [31:0] s_axi_wdata,
    input  logic [3:0]  s_axi_wstrb,
    input  logic        s_axi_wvalid,
    output logic        s_axi_wready,

    // AXI write response
    output logic [1:0]  s_axi_bresp,
    output logic        s_axi_bvalid,
    input  logic        s_axi_bready,

    // AXI read address
    input  logic [7:0]  s_axi_araddr,
    input  logic [2:0]  s_axi_arprot,
    input  logic        s_axi_arvalid,
    output logic        s_axi_arready,

    // AXI read response
    output logic [31:0] s_axi_rdata,
    output logic [1:0]  s_axi_rresp,
    output logic        s_axi_rvalid,
    input  logic        s_axi_rready,

    // SPI master interface
    output logic        spi_start,
    output logic [15:0] spi_tx_data,
    output logic [15:0] spi_clk_div,
    input  logic        spi_busy,
    input  logic        spi_done,

    // RX FIFO interface
    output logic        fifo_rd_en,
    output logic        fifo_flush,
    input  logic [15:0] fifo_rd_data,
    input  logic        fifo_empty,
    input  logic        fifo_full,
    input  logic [8:0]  fifo_count
);

    // -----------------------------------------
    // AXI response codes
    // -----------------------------------------
    localparam logic [1:0] AXI_OKAY   = 2'b00;
    localparam logic [1:0] AXI_SLVERR = 2'b10;

    // -----------------------------------------
    // Register map
    // -----------------------------------------
    localparam logic [7:0] ADDR_CONTROL    = 8'h00;
    localparam logic [7:0] ADDR_STATUS     = 8'h04;
    localparam logic [7:0] ADDR_CLK_DIV    = 8'h08;
    localparam logic [7:0] ADDR_TX_DATA    = 8'h0C;
    localparam logic [7:0] ADDR_RX_DATA    = 8'h10;
    localparam logic [7:0] ADDR_FIFO_COUNT = 8'h14;

    // -----------------------------------------
    // Write channel holding registers
    // -----------------------------------------
    logic [7:0]  awaddr_hold;
    logic [31:0] wdata_hold;
    logic [3:0]  wstrb_hold;

    logic aw_pending;
    logic w_pending;

    // Sticky status flags
    logic command_error;
    logic overflow_error;
    logic done_sticky;
    logic status_clear;

    // -----------------------------------------
    // AXI write READY signals
    // -----------------------------------------
    assign s_axi_awready =
        !aw_pending && !s_axi_bvalid;

    assign s_axi_wready =
        !w_pending && !s_axi_bvalid;

    // =========================================
    // AXI WRITE CHANNELS
    // =========================================
    always_ff @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            awaddr_hold <= 0;
            wdata_hold  <= 0;
            wstrb_hold  <= 0;

            aw_pending <= 0;
            w_pending  <= 0;

            s_axi_bvalid <= 0;
            s_axi_bresp  <= AXI_OKAY;

            spi_tx_data <= 0;
            spi_clk_div <= 16'd25;

            spi_start  <= 0;
            fifo_flush <= 0;
            status_clear <= 0;

            command_error  <= 0;
            overflow_error <= 0;

        end else begin
            // One-clock-cycle control pulses
            spi_start    <= 0;
            fifo_flush   <= 0;
            status_clear <= 0;

            // Capture write address
            if (s_axi_awvalid && s_axi_awready) begin
                awaddr_hold <= s_axi_awaddr;
                aw_pending <= 1;
            end

            // Capture write data independently
            if (s_axi_wvalid && s_axi_wready) begin
                wdata_hold <= s_axi_wdata;
                wstrb_hold <= s_axi_wstrb;
                w_pending <= 1;
            end

            // Execute a write after both channels arrive
            if (aw_pending && w_pending &&
                !s_axi_bvalid) begin

                s_axi_bresp <= AXI_OKAY;

                case (awaddr_hold)

                    // CONTROL register
                    ADDR_CONTROL: begin
                        if (wstrb_hold[0]) begin

                            // Bit 2: Clear sticky flags
                            if (wdata_hold[2]) begin
                                command_error <= 0;
                                overflow_error <= 0;
                                status_clear <= 1;
                            end

                            // Bit 1: Flush FIFO
                            if (wdata_hold[1])
                                fifo_flush <= 1;

                            // Bit 0: Start SPI transfer
                            if (wdata_hold[0]) begin
                                if (!spi_busy &&
                                    !fifo_full &&
                                    !wdata_hold[1]) begin
                                    spi_start <= 1;
                                end else begin
                                    command_error <= 1;

                                    if (fifo_full)
                                        overflow_error <= 1;
                                end
                            end
                        end
                    end

                    // SPI clock divider
                    ADDR_CLK_DIV: begin
                        if (wstrb_hold[0])
                            spi_clk_div[7:0]
                                <= wdata_hold[7:0];

                        if (wstrb_hold[1])
                            spi_clk_div[15:8]
                                <= wdata_hold[15:8];
                    end

                    // Transmit data
                    ADDR_TX_DATA: begin
                        if (wstrb_hold[0])
                            spi_tx_data[7:0]
                                <= wdata_hold[7:0];

                        if (wstrb_hold[1])
                            spi_tx_data[15:8]
                                <= wdata_hold[15:8];
                    end

                    // Invalid / read-only addresses
                    default: begin
                        s_axi_bresp <= AXI_SLVERR;
                    end

                endcase

                // Issue write response
                s_axi_bvalid <= 1;

                aw_pending <= 0;
                w_pending <= 0;
            end

            // Complete write response handshake
            if (s_axi_bvalid && s_axi_bready)
                s_axi_bvalid <= 0;
        end
    end

    // =========================================
    // SPI DONE STATUS FLAG
    // =========================================
    always_ff @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn)
            done_sticky <= 0;
        else if (spi_done)
            done_sticky <= 1;
        else if (status_clear)
            done_sticky <= 0;
    end

    // =========================================
    // AXI READ STATE MACHINE
    // =========================================
    typedef enum logic [1:0] {
        RD_IDLE,
        RD_FIFO_WAIT,
        RD_FIFO_CAPTURE,
        RD_RESP
    } read_state_t;

    read_state_t read_state;

    // Accept a read address only when idle
    assign s_axi_arready =
        (read_state == RD_IDLE);

    // =========================================
    // AXI READ CHANNELS
    // =========================================
    always_ff @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            read_state <= RD_IDLE;

            s_axi_rdata  <= 0;
            s_axi_rresp  <= AXI_OKAY;
            s_axi_rvalid <= 0;

            fifo_rd_en <= 0;

        end else begin
            // Default: do not pop FIFO
            fifo_rd_en <= 0;

            case (read_state)

                // -----------------------------
                // Wait for AXI read address
                // -----------------------------
                RD_IDLE: begin
                    if (s_axi_arvalid &&
                        s_axi_arready) begin

                        s_axi_rresp <= AXI_OKAY;

                        case (s_axi_araddr)

                            // CONTROL reads as zero
                            ADDR_CONTROL: begin
                                s_axi_rdata <= 0;
                                s_axi_rvalid <= 1;
                                read_state <= RD_RESP;
                            end

                            // STATUS register
                            ADDR_STATUS: begin
                                s_axi_rdata <= {
                                    26'b0,
                                    command_error,
                                    overflow_error,
                                    fifo_full,
                                    fifo_empty,
                                    done_sticky,
                                    spi_busy
                                };

                                s_axi_rvalid <= 1;
                                read_state <= RD_RESP;
                            end

                            // Divider register
                            ADDR_CLK_DIV: begin
                                s_axi_rdata <= {
                                    16'b0, spi_clk_div
                                };

                                s_axi_rvalid <= 1;
                                read_state <= RD_RESP;
                            end

                            // Transmit data register
                            ADDR_TX_DATA: begin
                                s_axi_rdata <= {
                                    16'b0, spi_tx_data
                                };

                                s_axi_rvalid <= 1;
                                read_state <= RD_RESP;
                            end

                            // FIFO count
                            ADDR_FIFO_COUNT: begin
                                s_axi_rdata <= {
                                    23'b0, fifo_count
                                };

                                s_axi_rvalid <= 1;
                                read_state <= RD_RESP;
                            end

                            // FIFO receive data
                            ADDR_RX_DATA: begin
                                if (fifo_empty) begin
                                    s_axi_rdata <= 0;
                                    s_axi_rresp <= AXI_SLVERR;
                                    s_axi_rvalid <= 1;
                                    read_state <= RD_RESP;
                                end else begin
                                    fifo_rd_en <= 1;
                                    read_state <= RD_FIFO_WAIT;
                                end
                            end

                            // Unmapped address
                            default: begin
                                s_axi_rdata <= 0;
                                s_axi_rresp <= AXI_SLVERR;
                                s_axi_rvalid <= 1;
                                read_state <= RD_RESP;
                            end

                        endcase
                    end
                end

                // FIFO sees rd_en at this clock edge
                RD_FIFO_WAIT: begin
                    read_state <= RD_FIFO_CAPTURE;
                end

                // Capture FIFO registered output
                RD_FIFO_CAPTURE: begin
                    s_axi_rdata <= {
                        16'b0, fifo_rd_data
                    };

                    s_axi_rresp <= AXI_OKAY;
                    s_axi_rvalid <= 1;
                    read_state <= RD_RESP;
                end

                // Hold read response until accepted
                RD_RESP: begin
                    if (s_axi_rvalid &&
                        s_axi_rready) begin
                        s_axi_rvalid <= 0;
                        read_state <= RD_IDLE;
                    end
                end

                default: begin
                    read_state <= RD_IDLE;
                end

            endcase
        end
    end

endmodule
