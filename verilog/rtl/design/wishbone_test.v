`default_nettype none

module wishbone_test (
    input clk_i,
    input rst_i,
    input wb_we_i,
    input [3:0] wb_sel_i,
    input [31:0] wb_dat_i,
    output [31:0] wb_dat_o,

    input spi_we_i,
    input [31:0] spi_data_i,
    output [31:0] spi_data_o
);
    reg [31:0] counter_val;

    // Everything occurs on rising edges
    always @(posedge clk_i) begin
        if (rst_i) begin
            // Synchronous reset state
            counter_val <= 0;
        end else begin
            // Default behavior (count up)
            counter_val <= counter_val + 1;

            if (wb_we_i) begin
                // Decode address here if needed.
                // Write the correct bits based on sel
                if (wb_sel_i[3])
                    counter_val[31:24] <= wb_dat_i[31:24];
                if (wb_sel_i[2])
                    counter_val[23:16] <= wb_dat_i[23:16];
                if (wb_sel_i[1])
                    counter_val[15:8] <= wb_dat_i[15:8];
                if (wb_sel_i[0])
                    counter_val[7:0] <= wb_dat_i[7:0];
            end
            // SPI writing takes precedence
            if (spi_we_i) begin
                // Decode address here if needed, write to internal reg
                counter_val <= spi_data_i;
            end
        end
    end

    assign wb_dat_o = counter_val;
    assign spi_data_o = counter_val;
    // https://cdn.opencores.org/downloads/wbspec_b4.pdf, page 106
endmodule

`default_nettype wire