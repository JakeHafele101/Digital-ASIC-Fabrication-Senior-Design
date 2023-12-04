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

module backdoor_spi_dff_buffer_tb;

	parameter BUFFER_WIDTH = 2;

	reg i_CLK; 
	reg i_D;
	reg i_EN;
	reg i_RST;
	wire [1:0] o_Q;

	reg [BUFFER_WIDTH:0] s_Q_expected;
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
		$dumpfile("backdoor_spi_dff_buffer.vcd");
		$dumpvars(0, backdoor_spi_dff_buffer_tb);

		//Repeat cycles of 1000 i_CLK edges as needed to complete testbench
		repeat (140) begin //default 70
			repeat (1000) @(posedge i_CLK);
		end

		$display("%c[1;31m",27);
		`ifdef GL
			$display ("Monitor: Timeout, DFF Buffer (GL) Failed");
		`else
			$display ("Monitor: Timeout, DFF Buffer (RTL) Failed");
		`endif
		$display("%c[0m",27);
		$finish;
	end

	//Process for UUT
	initial begin
		start();

		//Expected shift operation, enable set
		buffer(1'b1, 1'b1);
		buffer(1'b0, 1'b1);

		//enable cleared, NO SHIFT
		buffer(1'b1, 1'b0);
		buffer(1'b0, 1'b0);

		//Tests done
		complete();
	end

	backdoor_spi_dff_buffer 
	#(.BUFFER_WIDTH(BUFFER_WIDTH)) 
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
			s_Q_expected = 0;
			repeat (1) @(negedge i_CLK);
			i_RST = 1'b0;
		end
	endtask

	task buffer(input data_in, input enable);
		integer i;
		begin
			reset();
			repeat(1) @(negedge i_CLK);
			i_EN = enable; //Enable shift module
			i_D = data_in;

			for(i = 0; i < BUFFER_WIDTH + 2; i = i + 1) //load data bits
				begin
					if((o_Q != s_Q_expected[BUFFER_WIDTH:BUFFER_WIDTH - 1]) && enable == 1'b1) begin //if enable set
						s_Q_error = 1'b1;
						s_Status = 2'b0;
						repeat(1) @(negedge i_CLK);
						s_Q_error = 1'b0;
					end
					else if((o_Q != s_Q_expected[BUFFER_WIDTH:BUFFER_WIDTH - 1]) && enable == 1'b0) begin //if enable cleared
						s_Q_error = 1'b1;
						s_Status = 2'b0;
						repeat(1) @(negedge i_CLK);
						s_Q_error = 1'b0;
					end
					repeat(1) @(negedge i_CLK);
					if(enable == 1'b1) begin
						s_Q_expected = {s_Q_expected[BUFFER_WIDTH-1:0], data_in};
					end 
				end

			i_EN = 1'b0; //Enable shift module
		end
	endtask

	task complete();
		begin

			if(s_Status == 1'b1) begin //Pass indicator
				`ifdef GL
					$display("Monitor: DFF Buffer (GL) Passed");
				`else
					$display("Monitor: DFF Buffer (RTL) Passed");
				`endif
				$finish;
			end

			else begin //Fail indicator
				`ifdef GL
					$display("Monitor: DFF Buffer (GL) Failed");
				`else
					$display("Monitor: DFF Buffer (RTL) Failed");
				`endif
				$finish;
			end

		end
	endtask

endmodule
`default_nettype wire