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

module shift_out_reg_tb;
	parameter DATA_WIDTH = 32;

	reg i_CLK; 
	reg i_RST;
	reg i_START;
	reg [DATA_WIDTH-1:0] i_D;
	wire o_Q;

	reg s_Q_error; //Error checking

	reg s_Status;

	initial begin
		i_CLK = 0;
	end

	//Clock alternating
	always #12 i_CLK <= (i_CLK === 1'b0);

	initial begin
		i_RST <= 1'b1;       //Active high reset
		repeat (2) @(negedge i_CLK);
		i_RST <= 1'b0;	    // Release reset
	end

	initial begin
		$dumpfile("shift_out_reg.vcd");
		$dumpvars(0, shift_out_reg_tb);

		//Repeat cycles of 1000 i_CLK edges as needed to complete testbench
		repeat (140) begin //default 70
			repeat (1000) @(posedge i_CLK);
		end

		$display("%c[1;31m",27);
		`ifdef GL
			$display ("Monitor: Timeout, Shift Out Reg (GL) Failed");
		`else
			$display ("Monitor: Timeout, Shift Out Reg (RTL) Failed");
		`endif
		$display("%c[0m",27);
		$finish;
	end

	//Process for UUT
	initial begin
		start();

		//Expected shift operation, enable set
		shift_out(32'h12345678);
		shift_out(32'hF0F0F0F0);
		shift_out(32'h00000000);
		shift_out(32'hFFFFFFFF);

		complete();
	end

	shift_out_reg 
	#(.DATA_WIDTH(DATA_WIDTH)) 
	uut (
    	.i_CLK   (i_CLK), //i_CLK
    	.i_RST   (i_RST), //Asynchronous reset
    	.i_START (i_START),  //Enable to shift left by 1
    	.i_D     (i_D), //LSB input 
    	.o_Q     (o_Q)
    );

	task start();	
		begin
			i_RST = 1'b1;
			i_START = 1'b0;
			i_D = 32'd0;
			s_Q_error = 1'b0;
			repeat (1) @(negedge i_CLK);
			i_RST = 1'b0;
			s_Status = 2'b1;
			$display("Monitor: Shift Out Reg Started");
		end
	endtask

	task reset();
		begin
			i_RST = 1'b1;
			repeat (1) @(negedge i_CLK);
			i_RST = 1'b0;
		end
	endtask

	task shift_out(input [DATA_WIDTH-1:0] data_in);
		integer i;
		reg [DATA_WIDTH - 1 : 0] s_data_in_measured;
		begin
			reset();
			i_D = data_in;
			s_data_in_measured = 0;
			repeat(1) @(negedge i_CLK);
			i_START = 1'b1;
			repeat(1) @(negedge i_CLK);
			i_START = 1'b0;

			for(i = 0; i < DATA_WIDTH; i = i + 1) begin 
				s_data_in_measured = {s_data_in_measured[DATA_WIDTH - 2 : 0], o_Q};
				@(negedge i_CLK);
			end

			if(s_data_in_measured != data_in) begin
				s_Q_error = 1'b1;
				s_Status = 2'b0;
				repeat(1) @(negedge i_CLK);
				s_Q_error = 1'b0;
			end

			repeat(1) @(negedge i_CLK);

		end
	endtask

	task complete();
		begin

			if(s_Status == 1'b1) begin //Pass indicator
				`ifdef GL
					$display("Monitor: Shift Out Reg (GL) Passed");
				`else
					$display("Monitor: Shift Out Reg (RTL) Passed");
				`endif
				$finish;
			end

			else begin //Fail indicator
				`ifdef GL
					$display("Monitor: Shift Out Reg (GL) Failed");
				`else
					$display("Monitor: Shift Out Reg (RTL) Failed");
				`endif
				$finish;
			end

		end
	endtask

endmodule
`default_nettype wire