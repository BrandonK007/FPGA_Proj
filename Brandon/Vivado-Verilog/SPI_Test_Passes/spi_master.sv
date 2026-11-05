
module spi_master (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        start,
    input  logic [15:0] tx_data,
    input  logic [15:0] clk_div,
    input  logic        miso,

    output logic        sclk,
    output logic        mosi,
    output logic        cs_n,
    output logic [15:0] rx_data,
    output logic        busy,
    output logic        done
);

    logic [15:0] divider_count;
    logic [15:0] divider_value;
    logic [15:0] tx_shift;
    logic [15:0] rx_shift;
    logic [4:0]  bit_count;
    logic        active;

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            divider_count <= 0;
            divider_value <= 1;
            tx_shift      <= 0;
            rx_shift      <= 0;
            bit_count     <= 0;
            active        <= 0;

            sclk          <= 0;
            mosi          <= 0;
            cs_n          <= 1;
            rx_data       <= 0;
            busy          <= 0;
            done          <= 0;
        end else begin
            done <= 0;

            if (!active) begin
                sclk <= 0;
                cs_n <= 1;
                busy <= 0;
                divider_count <= 0;

                if (start) begin
                    active        <= 1;
                    busy          <= 1;
                    cs_n          <= 0;
                    tx_shift      <= tx_data;
                    rx_shift      <= 0;
                    bit_count     <= 0;
                    divider_value <= (clk_div == 0) ? 1 : clk_div;
                    mosi          <= tx_data[15];
                end
            end else begin
                if (divider_count == divider_value - 1'b1) begin
                    divider_count <= 0;
                    sclk <= ~sclk;

                    if (!sclk) begin
                        // Rising SCLK: sample incoming data
                        rx_shift <= {rx_shift[14:0], miso};
                    end else begin
                        // Falling SCLK: advance outgoing data
                        if (bit_count == 15) begin
                            active   <= 0;
                            busy     <= 0;
                            cs_n     <= 1;
                            rx_data  <= rx_shift;
                            done     <= 1;
                        end else begin
                            bit_count <= bit_count + 1'b1;
                            tx_shift <= {tx_shift[14:0], 1'b0};
                            mosi <= tx_shift[14];
                        end
                    end
                end else begin
                    divider_count <= divider_count + 1'b1;
                end
            end
        end
    end
endmodule
