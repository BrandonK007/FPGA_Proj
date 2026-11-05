
module rx_fifo (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        wr_en,
    input  logic        rd_en,
    input  logic [15:0] wr_data,

    output logic [15:0] rd_data,
    output logic        full,
    output logic        empty,
    output logic [8:0]  count
);

    logic [15:0] mem [0:255];
    logic [7:0] wr_ptr;
    logic [7:0] rd_ptr;

    logic write_ok;
    logic read_ok;

    assign empty = (count == 0);
    assign full  = (count == 256);

    assign read_ok  = rd_en && !empty;
    assign write_ok = wr_en && !full;

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            wr_ptr  <= 0;
            rd_ptr  <= 0;
            count   <= 0;
            rd_data <= 0;
        end else begin
            if (write_ok) begin
                mem[wr_ptr] <= wr_data;
                wr_ptr <= wr_ptr + 1'b1;
            end

            if (read_ok) begin
                rd_data <= mem[rd_ptr];
                rd_ptr <= rd_ptr + 1'b1;
            end

            case ({write_ok, read_ok})
                2'b10: count <= count + 1'b1;
                2'b01: count <= count - 1'b1;
                default: count <= count;
            endcase
        end
    end

endmodule
