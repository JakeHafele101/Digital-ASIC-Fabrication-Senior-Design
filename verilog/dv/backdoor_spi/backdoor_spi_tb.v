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

module backdoor_spi_tb;

	parameter ADDRESS_WIDTH = 8;
	parameter DATA_WIDTH = 32;
	parameter BUFFER_WIDTH = 2;
	
	//Testbench Control
	integer s_SYSCLK_HPER = 10;
	integer s_BCLK_HPER = 10;

	reg s_BCLK_EN = 1'b1;
	integer s_BCLK_WAIT = 150;

	//UUT inputs
	reg i_SYSCLK, i_BCLK; 
	reg i_SS;
	reg i_MOSI;
	reg [DATA_WIDTH - 1:0] i_DATA_OUT;

	//UUT outputs
	wire o_MISO;
	wire [ADDRESS_WIDTH - 2:0] o_ADDR;
	wire [DATA_WIDTH - 1:0] o_DATA_IN;
	wire o_DOUT_VALID;

	//Error Checking
	reg s_error;

	//Clock initialization
	initial begin
		i_SYSCLK = 0;
		i_BCLK = 0;
	end

	//Clock alternating
	always #(s_SYSCLK_HPER) i_SYSCLK <= (i_SYSCLK === 1'b0);

	always begin
		if(s_BCLK_EN)
			i_BCLK <= (i_BCLK === 1'b0);
		else
			i_BCLK <= 1'b0;

		#(s_BCLK_HPER);
	end

	//Initial reset
	initial begin
		i_SS <= 1'b1;       //Active high reset
	end

	initial begin
		$dumpfile("backdoor_spi.vcd");
		$dumpvars(0, backdoor_spi_tb);

		//Repeat cycles of 1000 i_BCLK edges as needed to complete testbench
		repeat (10) begin //default 70
			repeat (1000) @(posedge i_BCLK);
		end

		$display("%c[1;31m",27);
		`ifdef GL
			$display ("Monitor: Timeout, Backdoor SPI (GL) Failed");
		`else
			$display ("Monitor: Timeout, Backdoor SPI (RTL) Failed");
		`endif
		$display("%c[0m",27);
		$finish;
	end

	//Process for UUT
	initial begin
		start();

		//Read only
		read(7'b1100101, 32'h12345678); //Address, data read
		read(7'b1100101, 32'hF0F0F0F0); //Address, data read
		read(7'b1100101, 32'h00000000); //Address, data read
		read(7'b1100101, 32'hFFFFFFFF); //Address, data read

		//Write
		write(7'b1100101, 32'h12345678, 32'h12345678); //Address, data write, data read
		write(7'b0101010, 32'hF0F0F0F0, 32'h0F0F0F0F);
		write(7'b0000000, 32'h00000000, 32'h00000000);
		write(7'b1111111, 32'hFFFFFFFF, 32'hFFFFFFFF);

		// //Faster BCLK
		set_clk_period(53, 10); //BCLK, SYSCLK
		read(7'b1100101, 32'h12345678); //Address, data read
		read(7'b1100101, 32'hF0F0F0F0); //Address, data read
		read(7'b1100101, 32'h00000000); //Address, data read
		read(7'b1100101, 32'hFFFFFFFF); //Address, data read
		write(7'b1100101, 32'h12345678, 32'h12345678); //Address, data write, data read
		write(7'b0101010, 32'hF0F0F0F0, 32'h0F0F0F0F);
		write(7'b0000000, 32'h00000000, 32'h00000000);
		write(7'b1111111, 32'hFFFFFFFF, 32'hFFFFFFFF);

		// //Slower BCLK
		set_clk_period(3, 10); //BCLK, SYSCLK
		read(7'b1100101, 32'h12345678); //Address, data read
		read(7'b1100101, 32'hF0F0F0F0); //Address, data read
		read(7'b1100101, 32'h00000000); //Address, data read
		read(7'b1100101, 32'hFFFFFFFF); //Address, data read
		write(7'b1100101, 32'h12345678, 32'h12345678); //Address, data write, data read
		write(7'b0101010, 32'hF0F0F0F0, 32'h0F0F0F0F);
		write(7'b0000000, 32'h00000000, 32'h00000000);
		write(7'b1111111, 32'hFFFFFFFF, 32'hFFFFFFFF);

		complete();
	end

	//Instantiate UUT
	backdoor_spi
	#(
		.ADDRESS_WIDTH(ADDRESS_WIDTH),
		.DATA_WIDTH(DATA_WIDTH),
		.BUFFER_WIDTH(BUFFER_WIDTH)
	)
	uut (
		.i_SYSCLK(i_SYSCLK),
		.i_BCLK(i_BCLK),
		.i_SS(i_SS),
		.i_MOSI(i_MOSI),
		.i_DATA_OUT(i_DATA_OUT),

		.o_MISO(o_MISO),
		.o_ADDR(o_ADDR),
		.o_DATA_IN(o_DATA_IN),
		.o_DOUT_VALID(o_DOUT_VALID)
	);


	task start();	
		begin
			i_SS = 1'b1;
			i_MOSI = 1'b0;
			i_DATA_OUT = 32'h12345678;
			s_BCLK_EN = 1'b1;

			s_error = 1'b0;
			$display("Monitor: Backdoor SPI Started, test");
			repeat (1) @(negedge i_BCLK);
		end
	endtask

	task reset();
		begin
			i_SS = 1'b1;
			s_BCLK_EN = 1'b1;
			repeat (1) @(negedge i_BCLK);
		end
	endtask

	/* write data TO user area
		1. Send READ flag from MOSIMOSI
		2. Send address (7 bits) from MOSI, MSB first
		3. Send 32 bit data from MOSI, MSB first
		4. Wait 2 SYSCLK cycles to assert o_DOUT_VALID flag
		5. Wait 1 SYSCLK cycle for o_DOUT_VALID flag to clear
	*/
	task write(input [ADDRESS_WIDTH - 2:0] i_addr, input [DATA_WIDTH-1:0] i_data_write, input [DATA_WIDTH-1:0] i_data_read);
		integer i;
		begin
			
			reset();
			i_DATA_OUT = i_data_read;
			@(negedge i_BCLK);
			i_SS = 1'b0; //active-low

			//Step 1, send write flag
			i_MOSI = 1'b0; //read from slave 1
			@(negedge i_BCLK);

			//Check o_DOUT_VALID 0
			if(o_DOUT_VALID != 1'b0) begin
				s_error = 1'b1;
			end
			
			//Step 2, send address, MSB first (6 downto 0)
			for(i = ADDRESS_WIDTH - 2; i >= 0; i = i - 1) begin 
				i_MOSI = i_addr[i];
				@(negedge i_BCLK);
			end

			//Check o_ADDR, o_DOUT_VALID 0
			if(o_DOUT_VALID != 1'b0 || o_ADDR != i_addr) begin
				s_error = 1'b1;
			end

			//Step 3, Send data, MSB first
			for(i = DATA_WIDTH - 1; i > 0; i = i - 1) begin 
				i_MOSI = i_data_write[i];
				@(negedge i_BCLK);
			end

			i_MOSI = i_data_write[0];

			//Step 4, wait 2 SYSCLK cycles to assert o_DOUT_VALID 
			@(posedge o_DOUT_VALID);
			@(negedge i_SYSCLK);

			//Check o_DOUT_VALID 1
			if(o_DOUT_VALID != 1'b1 || o_DATA_IN != i_data_write)
				s_error = 1'b1;

			//Step 5, clear o_DOUT_VALID
			//Check o_DOUT_VALID 0
			@(negedge i_SYSCLK);
			if(o_DOUT_VALID != 1'b0)
				s_error = 1'b1;

			repeat(2) @(negedge i_SYSCLK);
			
		end
	endtask

	/* read data FROM user area
		1. Recieve address (7 address bits, READ flag) from MOSI
		2. Wait 2 SYSCLK cycles to ensure address propogates to user modules
		3. Parallel load i_DATA_OUT from user area modules
		4. Shift out 32 bits of data to o_MOSI with contents of i_DATA_OUT
	*/
	task read(input [ADDRESS_WIDTH - 2:0] i_addr, input [DATA_WIDTH-1:0] i_data_read);
		integer i;
		reg [DATA_WIDTH - 1 : 0] o_MISO_read;
		begin
			o_MISO_read = 0;
			
			reset();
			i_DATA_OUT = i_data_read;
			@(negedge i_BCLK);
			i_SS = 1'b0; //active-low

			//Step 1, send read flag
			i_MOSI = 1'b1; //write to slave 0, read from slave 1
			@(negedge i_BCLK);
			
			//Step 2, send address, MSB first (6 downto 0)
			for(i = ADDRESS_WIDTH - 2; i >= 0; i = i - 1) begin 
				i_MOSI = i_addr[i];
				@(negedge i_BCLK);
			end

			//Step 3, disable BCLK 
			s_BCLK_EN = 1'b0; //Disable BCLK for X us
			#(s_BCLK_WAIT);
			s_BCLK_EN = 1'b1;

			//Step 4, Shift out o_MISO, count then verify
			for(i = 0; i < DATA_WIDTH; i = i + 1) begin 
				@(negedge i_BCLK);
				o_MISO_read = {o_MISO_read[DATA_WIDTH - 2 : 0], o_MISO};
			end

			@(negedge i_BCLK); //wait for error checking...

			if(o_MISO_read != i_data_read)
				s_error = 1'b1;

		end
	endtask

	task set_clk_period(input integer i_BCLK_HPER, input integer i_HCLK_HPER);
		begin
			s_SYSCLK_HPER = i_HCLK_HPER;
			s_BCLK_HPER = i_BCLK_HPER;
			repeat(2) @(negedge i_BCLK);
			reset();
		end
	endtask

	task complete();
		begin
			if(s_error == 1'b0) begin //Pass indicator
				`ifdef GL
					$display("Monitor: Backdoor SPI (GL) Passed");
				`else
					$display("Monitor: Backdoor SPI (RTL) Passed");
				`endif
				$finish;
			end

			else begin //Fail indicator
				`ifdef GL
					$display("Monitor: Backdoor SPI (GL) Failed");
				`else
					$display("Monitor: Backdoor SPI (RTL) Failed");
				`endif
				$finish;
			end

		end
	endtask

endmodule
`default_nettype wire