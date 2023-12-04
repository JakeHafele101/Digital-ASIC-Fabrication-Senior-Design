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

module module_control_test_tb;
	localparam N_MODULES = 4;

	reg OK;

	reg we_i;
  reg [2:0] addr_i; // The portion of the address used for module selection
  reg [N_MODULES-1:0][31:0] module_data_i;
  wire [31:0] data_o;
  wire [N_MODULES-1:0] module_we_o;

	initial begin
		$dumpfile("module_control_test.vcd");
		$dumpvars(0, module_control_test_tb);

		OK = 1'b1;
		addr_i = 3'b000;
		module_data_i = { // 3 downto 0
			32'hFEEDC0DE,
			32'hCAFEB0BA,
			32'h8BADF00D,
			32'hDEADBEEF
		};

		#1 we_i = 0;
		#1 if (data_o != 0) OK = 0;
		#1 addr_i = 3'b001;
		#1 if (data_o != 32'hDEADBEEF || module_we_o != 4'b0000) OK = 0;
		#1 addr_i = 3'b010;
		#1 if (data_o != 32'h8BADF00D || module_we_o != 4'b0000) OK = 0;
		#1 addr_i = 3'b011;
		#1 if (data_o != 32'hCAFEB0BA || module_we_o != 4'b0000) OK = 0;
		#1 addr_i = 3'b100;
		#1 if (data_o != 32'hFEEDC0DE || module_we_o != 4'b0000) OK = 0;

		#1 we_i = 1;
		   addr_i = 3'b001;
		#1 if (data_o != 32'hDEADBEEF || module_we_o != 4'b0001) OK = 0;
		#1 addr_i = 3'b010;
		#1 if (data_o != 32'h8BADF00D || module_we_o != 4'b0010) OK = 0;
		#1 addr_i = 3'b011;
		#1 if (data_o != 32'hCAFEB0BA || module_we_o != 4'b0100) OK = 0;
		#1 addr_i = 3'b100;
		#1 if (data_o != 32'hFEEDC0DE || module_we_o != 4'b1000) OK = 0;
		#1;

		if (OK == 1'b1) $display("PASSED");
		else $display("FAILED");
		
		$finish;
	end

	module_control uut(
    .we_i(we_i),
    .addr_i(addr_i),
    .module_data_i(module_data_i),
    .data_o(data_o),
    .module_we_o(module_we_o)
  );

endmodule
`default_nettype wire