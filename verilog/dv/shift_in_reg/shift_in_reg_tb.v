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

module shift_in_reg_tb;

	parameter DATA_WIDTH = 32;

	reg  i_CLK; 
	reg i_D;
	reg i_EN;
	reg i_RST;
	wire [DATA_WIDTH:0] o_Q;
	wire [DATA_WIDTH - 1:0] o_Data;
	wire o_WE;

	reg s_Q_error; //Error checking

	assign o_Data = o_Q[DATA_WIDTH - 1 : 0];
	assign o_WE = o_Q[DATA_WIDTH];

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
		$dumpfile("shift_in_reg.vcd");
		$dumpvars(0, shift_in_reg_tb);

		//Repeat cycles of 1000 i_CLK edges as needed to complete testbench
		repeat (140) begin //default 70
			repeat (1000) @(posedge i_CLK);
		end

		$display("%c[1;31m",27);
		`ifdef GL
			$display ("Monitor: Timeout, Shift In Reg (GL) Failed");
		`else
			$display ("Monitor: Timeout, Shift In Reg (RTL) Failed");
		`endif
		$display("%c[0m",27);
		$finish;
	end

	//Process for UUT
	initial begin
		start();

		//Expected shift operation, enable set
		shift_in(32'd100, 1'b1);
		shift_in(32'd256, 1'b1);
		shift_in(32'd10498, 1'b1);
		shift_in(32'h00000000, 1'b1);
		shift_in(32'hFFFFFFFF, 1'b1);

		//enable cleared, NO SHIFT
		shift_in(32'd100, 1'b0);
		shift_in(32'd256, 1'b0);
		shift_in(32'd10498, 1'b0);
		shift_in(32'h00000000, 1'b0);
		shift_in(32'hFFFFFFFF, 1'b0);

		complete();
	end

	shift_in_reg 
	#(.DATA_WIDTH(DATA_WIDTH)) 
	uut (
    	.i_CLK  (i_CLK), //i_CLK
    	.i_RST  (i_RST), //Asynchronous reset
    	.i_EN   (i_EN),  //Enable to shift left by 1
    	.i_D    (i_D), //LSB input 
    	.o_Q    (o_Q)
    );

	task start();	
		begin
			i_RST = 1'b1;
			i_EN = 1'b0;
			i_D = 1'b0;
			s_Q_error = 1'b0;
			repeat (1) @(negedge i_CLK);
			i_RST = 1'b0;
			s_Status = 2'b1;
			$display("Monitor: Shift In Reg Started");
		end
	endtask

	task reset();
		begin
			i_RST = 1'b1;
			repeat (1) @(negedge i_CLK);
			i_RST = 1'b0;
		end
	endtask

	task shift_in(input [DATA_WIDTH-1:0] data_in, input enable);
		integer i;
		begin
			reset();
			repeat(1) @(negedge i_CLK);
			i_EN = enable; //Enable shift module

			for(i = DATA_WIDTH - 1; i >= 0; i = i - 1) //load data bits
				begin
					i_D = data_in[i];
					repeat(1) @(negedge i_CLK);
				end

			i_EN = 1'b0; //Enable shift module

			if((o_Data != data_in || o_WE != 1'b1) && enable == 1'b1) begin //if enable set
				s_Q_error = 1'b1;
				s_Status = 2'b0;
				repeat(1) @(negedge i_CLK);
				s_Q_error = 1'b0;
			end
			else if((o_Data != 32'd1 || o_WE != 1'b0) && enable == 1'b0) begin //if enable cleared
				s_Q_error = 1'b1;
				s_Status = 2'b0;
				repeat(1) @(negedge i_CLK);
				s_Q_error = 1'b0;
			end
		end
	endtask

	task complete();
		begin

			if(s_Status == 1'b1) begin //Pass indicator
				`ifdef GL
					$display("Monitor: Shift In Reg (GL) Passed");
				`else
					$display("Monitor: Shift In Reg (RTL) Passed");
				`endif
				$finish;
			end

			else begin //Fail indicator
				`ifdef GL
					$display("Monitor: Shift In Reg (GL) Failed");
				`else
					$display("Monitor: Shift In Reg (RTL) Failed");
				`endif
				$finish;
			end

		end
	endtask

endmodule
`default_nettype wire