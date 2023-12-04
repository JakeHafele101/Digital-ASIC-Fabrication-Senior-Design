// SPDX-FileCopyrightText: 2020 Efabless Corporation
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
// SPDX-License-Identifier: Apache-2.0

`default_nettype none

`timescale 1 ns / 1 ps

module wishbone_test_tb;
	reg OK;
	
	reg wb_clk_i;
  reg wb_rst_i;
  reg wb_stb_i;
  reg wb_cyc_i;
  reg wb_we_i;
  reg [3:0] wb_sel_i;
  reg [31:0] wb_dat_i;
  reg [31:0] wb_adr_i;
  wire wb_ack_o;
  wire [31:0] wb_dat_o;

  reg spi_we_i;
  reg [31:0] spi_data_i;
  reg [31:0] spi_addr_i;
  wire [31:0] spi_data_o;

	always #1 wb_clk_i = ~wb_clk_i;

	initial begin
		$dumpfile("wishbone_test.vcd");
		$dumpvars(0, wishbone_test_tb);

		OK = 1'b1;

		wb_clk_i = 0;
		wb_rst_i = 0;
		wb_stb_i = 0;
		wb_cyc_i = 0;
		wb_we_i = 0;
		wb_sel_i = 0;
		wb_dat_i = 0;
		wb_adr_i = 0;
		spi_we_i = 0;
		spi_data_i = 0;
		spi_addr_i = 0;

		// Reset
		wb_rst_i = 1;
		#2 wb_rst_i = 0;

		// Wishbone & SPI Read
		#2 if (wb_dat_o != 1 || spi_data_o != 1) OK = 0;

		// Wishbone Write
		wb_stb_i = 1; wb_cyc_i = 1; wb_we_i = 1; wb_sel_i = 4'hF; wb_dat_i = 32'hDEADBEEF;
		#2 if (wb_ack_o != 1 || wb_dat_o != 32'hDEADBEEF || spi_data_o != 32'hDEADBEEF) OK = 0;

		// Count
		wb_stb_i = 0; wb_cyc_i = 0; wb_we_i = 0;
		#2 if (wb_ack_o != 0 || wb_dat_o != 32'hDEADBEF0 || spi_data_o != 32'hDEADBEF0) OK = 0;

		// Wishbone Write without STB
		wb_stb_i = 0; wb_cyc_i = 1; wb_we_i = 1; wb_sel_i = 4'hF; wb_dat_i = 32'hDEADBEEF;
		#2 if (wb_ack_o != 0 || wb_dat_o != 32'hDEADBEF1 || spi_data_o != 32'hDEADBEF1) OK = 0;

		// Wishbone Write without WE
		wb_stb_i = 1; wb_cyc_i = 1; wb_we_i = 0; wb_sel_i = 4'hF; wb_dat_i = 32'hDEADBEEF;
		#2 if (wb_ack_o != 1 || wb_dat_o != 32'hDEADBEF2 || spi_data_o != 32'hDEADBEF2) OK = 0;
		
		// Wishbone Write without CYC
		wb_stb_i = 1; wb_cyc_i = 0; wb_we_i = 1; wb_sel_i = 4'hF; wb_dat_i = 32'hDEADBEEF;
		#2 if (wb_ack_o != 0 || wb_dat_o != 32'hDEADBEF3 || spi_data_o != 32'hDEADBEF3) OK = 0;

		// Partial Wishbone Write
		wb_stb_i = 1; wb_cyc_i = 1; wb_we_i = 1; wb_sel_i = 4'hA; wb_dat_i = 32'hCAFEB0BA;
		#2 if (wb_ack_o != 1 || wb_dat_o != 32'hCAADB0F4 || spi_data_o != 32'hCAADB0F4) OK = 0;

		wb_stb_i = 0; wb_cyc_i = 0; wb_we_i = 0;

		// SPI Write
		spi_we_i = 1; spi_data_i = 32'h8BADF00D;
		#2 if (wb_ack_o != 0 || wb_dat_o != 32'h8BADF00D || spi_data_o != 32'h8BADF00D) OK = 0;
		#2 if (wb_ack_o != 0 || wb_dat_o != 32'h8BADF00D || spi_data_o != 32'h8BADF00D) OK = 0;

		// Count
		spi_we_i = 0;
		#2 if (wb_ack_o != 0 || wb_dat_o != 32'h8BADF00E || spi_data_o != 32'h8BADF00E) OK = 0;

		// SPI Write takes priority, but wishbone still acknowledges.
		spi_we_i = 1; spi_data_i = 32'h8BADF00D; wb_stb_i = 1; wb_cyc_i = 1; wb_we_i = 1; wb_sel_i = 4'hF; wb_dat_i = 32'hDEADBEEF;
		#2 if (wb_ack_o != 1 || wb_dat_o != 32'h8BADF00D || spi_data_o != 32'h8BADF00D) OK = 0;
		#2 if (wb_ack_o != 1 || wb_dat_o != 32'h8BADF00D || spi_data_o != 32'h8BADF00D) OK = 0;

		#2;

		if (OK == 1'b1) $display("PASSED");
		else $display("FAILED");
		
		$finish;
	end

	 wishbone_test uut(
    .wb_clk_i(wb_clk_i),
    .wb_rst_i(wb_rst_i),
    .wb_stb_i(wb_stb_i),
    .wb_cyc_i(wb_cyc_i),
    .wb_we_i(wb_we_i),
    .wb_sel_i(wb_sel_i),
    .wb_dat_i(wb_dat_i),
    .wb_adr_i(wb_adr_i),
    .wb_ack_o(wb_ack_o),
    .wb_dat_o(wb_dat_o),

    .spi_we_i(spi_we_i),
    .spi_data_i(spi_data_i),
    .spi_addr_i(spi_addr_i),
    .spi_data_o(spi_data_o)
	);

endmodule
`default_nettype wire