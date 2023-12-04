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

module dsp_tb;

	parameter INPUT_WIDTH =  32; 
    parameter OUTPUT_WIDTH = 32;

	integer i;

	reg i_CLK; 
	reg i_EN;
	reg i_RST;

    reg [INPUT_WIDTH -1 :0] i_DATA;
	wire [OUTPUT_WIDTH -1 :0] o_DATA;

	reg s_wish_valid;
	reg s_spi_valid;

	wire s_weight_ack;
	wire s_data_ack;
	wire s_conv_ack;

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
		$dumpfile("dsp.vcd");
		$dumpvars(0, dsp_tb);

		//Repeat cycles of 1000 i_CLK edges as needed to complete testbench
		repeat (40) begin //default 70
			repeat (1000) @(posedge i_CLK);
		end

		$display("%c[1;31m",27);
		`ifdef GL
			$display ("Monitor: Timeout, Up Counter (GL) Failed");
		`else
			$display ("Monitor: Timeout, Up Counter (RTL) Failed");
		`endif
		$display("%c[0m",27);
		$finish;
	end

	//Process for UUT
	initial begin
		start();
		
		load_weights(32'h1, 1024);
		load_data(32'h2, 1024);

		repeat(3) @(negedge i_CLK);

		accumulate(32'h3, 1050);

		repeat(3) @(negedge i_CLK);

		accumulate(32'h3, 1050);

		repeat(3) @(negedge i_CLK);

		accumulate(32'h3, 1050);

		repeat(3) @(negedge i_CLK);

		accumulate(32'h3, 1050);

		complete();
	end

	dsp 
	#(
		.BUS_WIDTH(32), 
		.DATA_WIDTH(8),
		.ADDRESS_WIDTH(10), 
		.OUTPUT_WIDTH(32)
	) 
	uut (
    	.i_CLK				(i_CLK), 		//i_CLK
    	.i_RST				(i_RST), 		//Asynchronous reset
		.i_WISH_VALID		(s_wish_valid),
		.i_SPI_VALID		(s_spi_valid),
    	.i_WISH_DATA 		(i_DATA),  		//
    	.i_SPI_DATA			(i_DATA), 		//
		.o_WEIGHT_ACK		(s_weight_ack),
		.o_DATA_ACK			(s_data_ack),
		.o_CONV_ACK			(s_conv_ack),
		.o_WISH_DATA		(o_DATA), 		//
    	.o_SPI_DATA			(o_DATA)		//Rollover 
    );

 

	task start();	
		begin
			i_RST = 1'b1;
			i_EN = 1'b0;
			s_Q_error = 1'b0;
			repeat (1) @(negedge i_CLK);
			i_RST = 1'b0;
			s_Status = 1'b1;
			s_wish_valid = 1'b0;
			$display("Monitor: Count Started");
		end
	endtask

	task reset();
		begin
			i_RST = 1'b1;
			repeat (1) @(negedge i_CLK);
			i_RST = 1'b0;
		end
	endtask

	task load_weights(input [31:0] data, input integer cycles);
		begin
			i_DATA <= data;

			for(i = 0; i < cycles; i=i) begin 
				s_spi_valid = 1'b0;
				

				if(s_weight_ack) begin
					i = i+1;
					s_spi_valid = 1'b1;
				end
				@(negedge i_CLK);
			end

			s_spi_valid = 1'b0;

		end
	endtask

	task load_data(input [31:0] data, input integer cycles);
		begin
			i_DATA <= data;

			for(i = 0; i < cycles; i=i) begin 
				s_wish_valid = 1'b0;

				if(s_data_ack) begin
					i = i+1;
					s_wish_valid = 1'b1;
				end
				@(negedge i_CLK);
			end

			s_wish_valid = 1'b0;

		end
	endtask

	task accumulate(input [31:0] data, input integer cycles);
		begin
			i_DATA <= data;
			s_wish_valid = 1'b1;
			repeat(1) @(negedge i_CLK);

			s_wish_valid = 1'b0;
			repeat(1) @(negedge i_CLK);
			
			while(s_conv_ack == 1'b0) begin
				repeat(1) @(negedge i_CLK);
			end

		end
	endtask


	task complete();
		begin
			repeat(1) @(negedge i_CLK); 

			if(s_Status == 1'b1) begin //Pass indicator
				`ifdef GL
					$display("Monitor: DSP (GL) Passed");
				`else
					$display("Monitor: DSP (RTL) Passed");
				`endif
				$finish;
			end

			else begin //Fail indicator
				`ifdef GL
					$display("Monitor: DSP (GL) Failed");
				`else
					$display("Monitor: DSP (RTL) Failed");
				`endif
				$finish;
			end

		end
	endtask

endmodule
`default_nettype wire