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

module user_proj_final_tb;

	parameter ADDRESS_WIDTH = 7;
	parameter DATA_WIDTH = 32;
	parameter N_MODULES = 4;
	
	//Testbench Control
	integer s_SYSCLK_HPER = 10; //halfperiod WB bus clock
	integer s_BCLK_HPER = 10; //halfperiod master SPI clock

	//SPI Task Drivers
	reg s_BCLK_EN = 1'b1;
	integer s_BCLK_WAIT = 150;

	//UUT Top Level
		//UUT inputs
		reg wb_clk_i;
		reg wb_rst_i;
		reg wbs_stb_i;
		reg wbs_cyc_i;
		reg wbs_we_i;
		reg [3:0] wbs_sel_i;
		reg [31:0] wbs_dat_i;
		reg [31:0] wbs_adr_i;

		// Power Ports
		wire vccd1_i;
		wire vssd1_i;
		assign vccd1_i = 1'b1;
		assign vssd1_i = 1'b0;

		wire [127:0] la_data_in;
		wire [127:0] la_oenb;

		wire [`MPRJ_IO_PADS-1:0] io_in;

		//UUT outputs
		wire wbs_ack_o;
		wire [31:0] wbs_dat_o;

		wire [127:0] la_data_out;

		wire [`MPRJ_IO_PADS-1:0] io_out; //37:0
		wire [`MPRJ_IO_PADS-1:0] io_oeb; //37:0

		wire [2:0] irq;

		//UUT internal signal assignments. ADD REGS FOR UUT HERE
		assign la_data_in[2:0] = {i_MOSI, i_SS, i_BCLK}; //EXPAND MODULE IN
		assign la_data_in[4:3] = {i_stdcell_B, i_stdcell_A};
		assign la_data_in[5] = i_clkmux_S;
		assign la_data_in[6] = i_dff_CLK;
		assign la_data_in[7] = i_dff_D;
		assign la_data_in[127:8] = 0; //EXPAND MODULE IN

		assign la_oenb[127:0] = 0;

		assign io_in[37:0] = 0; //EXPAND MODULE IN


	//SPI Signals
		// inputs
		reg i_BCLK; //Master SPI clock 
		reg i_SS;   //Slave select spi_reset, ACTIVE HIGH
		reg i_MOSI; //Master out Slave In
		// outputs
		wire o_MISO; //Master in Slave Out

		//Internal signal assignments
		assign o_MISO = la_data_out[0];

	//Standard Cell Test Signals
		//Inputs
		reg i_stdcell_A;
		reg i_stdcell_B;
		//Outputs
		wire o_stdcell_X;
		
		//Internal signal assignments
		assign o_stdcell_X = la_data_out[1];
	
	//Clock Mux Test Signals
		//Inputs
		reg i_clkmux_S; //Select line for clock MUX

	//Custom DFF
		//Inputs
		reg i_dff_CLK;
		reg i_dff_D;
		//Outputs
		wire o_dff_Q;

		//Internal signal assignments
		assign o_dff_Q = la_data_out[2];

	//Error Checking
	reg s_error;

	//Clock initialization
	initial begin
		wb_clk_i = 0;
		i_dff_CLK = 0;
		i_BCLK = 0;
		i_SS <= 1'b1;       //Active high spi_reset
		wb_rst_i <= 1'b1;   //wishbone reset
		repeat (1) @(negedge wb_clk_i);
		wb_rst_i <= 1'b0;   //wishbone reset
	end

	//Clock alternating
	always #(s_SYSCLK_HPER) wb_clk_i <= (wb_clk_i === 1'b0);
	always #(s_SYSCLK_HPER) i_dff_CLK <= (i_dff_CLK === 1'b0);

	// SPI Master clock driver
	always begin
		if(s_BCLK_EN)
			i_BCLK <= (i_BCLK === 1'b0);
		else
			i_BCLK <= 1'b0;

		#(s_BCLK_HPER);
	end

	initial begin
		$dumpfile("user_proj_final.vcd");
		$dumpvars(0, user_proj_final_tb);

		//Repeat cycles of 1000 i_BCLK edges as needed to complete testbench
		repeat (10) begin //default 70
			repeat (1000) @(posedge wb_clk_i);
		end

		$display("%c[1;31m",27);
		`ifdef GL
			$display ("Monitor: Timeout, (GL) Failed");
		`else
			$display ("Monitor: Timeout, (RTL) Failed");
		`endif
		$display("%c[0m",27);
		$finish;
	end

	//Process for UUT
	initial begin
		start();

		// //Slower BCLK
		// set_master_spi_clk(5, 20); //BCLK, SYSCLK
		// wb_write(7'b0000010, 32'hDEADBEEF); //Read from WB test counter
		// wb_read(7'b0000010, 32'hDEADBEEF); //Read from WB test counter
		// spi_read(7'b0000010, 32'hDEADBEEF); //Read from WB test counter
		
		// spi_write(7'b0000010, 32'hF0F0F0F0); //Write to wb test counter
		// spi_read(7'b0000010, 32'hF0F0F0F0); //Read from WB test counter

		//Standard Cell Test
		std_cell_AND2(); //Test std cell test

		//Clock mux test
		set_master_spi_clk(5, 20); //BCLK, wb_clock
		clk_mux();

		//SPI tests
		set_master_spi_clk(5, 20); //BCLK, wb_clock
		spi_write(7'b0000000, 32'hF0F0F0F0); 
		spi_read(7'b0000000, 32'hF0F0F0F0);

		//Custom DFF tests
		custom_dff();

		complete();
	end

	user_proj_final UUT (
		.vccd1(vccd1_i),
		.vssd1(vssd1_i),

		// Wishbone Slave ports (WB MI A)
		.wb_clk_i(wb_clk_i),
		.wb_rst_i(wb_rst_i),
		.wbs_stb_i(wbs_stb_i),
		.wbs_cyc_i(wbs_cyc_i),
		.wbs_we_i(wbs_we_i),
		.wbs_sel_i(wbs_sel_i),
		.wbs_dat_i(wbs_dat_i),
		.wbs_adr_i(wbs_adr_i),
	    .wbs_ack_o(wbs_ack_o),
		.wbs_dat_o(wbs_dat_o),

		// Logic Analyzer Signals
		.la_data_in(la_data_in),
		.la_data_out(la_data_out),
		.la_oenb(la_oenb),

		// IOs
		.io_in(io_in),
		.io_out(io_out),
		.io_oeb(io_oeb),

		// IRQ
		.irq(irq)
	);

	task start();	
		begin

			//Init top level
			wbs_stb_i = 1'b0;
			wbs_cyc_i = 1'b0;
			wbs_we_i = 1'b0;
			wbs_sel_i = 0;
			wbs_dat_i = 0;
			wbs_adr_i = 0;

			//SPI init
			i_SS = 1'b1;
			i_MOSI = 1'b0;
			s_BCLK_EN = 1'b1;

			//Std cell init
			i_stdcell_A = 1'b0;
			i_stdcell_B = 1'b0;

			//clk mux init
			i_clkmux_S = 1'b0;

			//Custom DFF init
			i_dff_D = 1'b0;

			s_error = 1'b0;
			$display("Monitor: Test Started");
			repeat (1) @(negedge wb_clk_i);
		end
	endtask

	task spi_reset();
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
	*/
	task spi_write(input [ADDRESS_WIDTH - 1:0] i_addr, input [DATA_WIDTH-1:0] i_data_write);
		integer i;
		begin
			
			spi_reset();
			@(negedge i_BCLK);
			i_SS = 1'b0; //active-low

			//Step 1, send write flag
			i_MOSI = 1'b0; //read from slave 1
			@(negedge i_BCLK);
			
			//Step 2, send address, MSB first (6 downto 0)
			for(i = ADDRESS_WIDTH - 1; i >= 0; i = i - 1) begin 
				i_MOSI = i_addr[i];
				@(negedge i_BCLK);
			end

			//Step 3, Send data, MSB first
			for(i = DATA_WIDTH - 1; i > 0; i = i - 1) begin 
				i_MOSI = i_data_write[i];
				@(negedge i_BCLK);
			end

			i_MOSI = i_data_write[0];

			//Step 4, wait 2 SYSCLK cycles to assert o_DOUT_VALID 
			repeat(5) @(negedge wb_clk_i); //Wait for data to be written...
			
			spi_reset();
		end
	endtask

	/* read data FROM user area
		1. Recieve address (7 address bits, READ flag) from MOSI
		2. Wait 2 SYSCLK cycles to ensure address propogates to user modules
		3. Parallel load i_DATA_OUT from user area modules
		4. Shift out 32 bits of data to o_MOSI with contents of i_DATA_OUT
	*/
	task spi_read(input [ADDRESS_WIDTH - 1:0] i_addr, input [DATA_WIDTH - 1:0] i_data_read);
		integer i;
		reg [DATA_WIDTH - 1 : 0] o_MISO_read;
		begin
			o_MISO_read = 0;
			
			spi_reset();
			@(negedge i_BCLK);
			i_SS = 1'b0; //active-low

			//Step 1, send read flag
			i_MOSI = 1'b1; //write to slave 0, read from slave 1
			@(negedge i_BCLK);
			
			//Step 2, send address, MSB first (6 downto 0)
			for(i = ADDRESS_WIDTH - 1; i >= 0; i = i - 1) begin 
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

			spi_reset();

		end
	endtask

	task set_master_spi_clk(input integer i_BCLK_HPER, input integer i_HCLK_HPER);
		begin
			s_SYSCLK_HPER = i_HCLK_HPER;
			s_BCLK_HPER = i_BCLK_HPER;
			repeat(2) @(negedge i_BCLK);
			spi_reset();
		end
	endtask

	task wb_write(input [3:0] i_addr, input [DATA_WIDTH-1:0] i_data_write);
		begin
			repeat(1) @(negedge wb_clk_i);
			wbs_stb_i = 1; 
			wbs_cyc_i = 1; 
			wbs_we_i = 1; 
			wbs_sel_i = 4'hF; //Write to all 4 bytes
			wbs_adr_i = {{25{1'b0}}, i_addr};; //FIXME find adr bits
			wbs_dat_i = i_data_write;
			repeat(1) @(negedge wb_clk_i);
			wbs_stb_i = 0; 
			wbs_cyc_i = 0; 
			wbs_we_i = 0;
			wbs_sel_i = 0;
			wbs_dat_i = 0;
			repeat(1) @(negedge wb_clk_i);

		end
	endtask

	task wb_read(input [ADDRESS_WIDTH - 1:0] i_addr, input [DATA_WIDTH - 1:0] i_data_read);
		begin
			repeat(1) @(negedge wb_clk_i);
			wbs_stb_i = 0; 
			wbs_cyc_i = 0; 
			wbs_we_i = 0; 
			wbs_sel_i = {{25{1'b0}}, i_addr}; //FIXME find adr bits
			repeat(2) @(negedge wb_clk_i);

			if(wbs_dat_o != i_data_read)
				s_error = 1'b1;
		end
	endtask

	task std_cell_AND2();
		begin
			repeat(1) @(negedge wb_clk_i);
			i_stdcell_A = 1'b0;
			i_stdcell_B = 1'b0;
			repeat(1) @(posedge wb_clk_i);
			if(o_stdcell_X != 1'b0)
				begin
				s_error = 1'b1;
				end

			repeat(1) @(negedge wb_clk_i);
			i_stdcell_A = 1'b1;
			i_stdcell_B = 1'b0;
			repeat(1) @(posedge wb_clk_i);
			if(o_stdcell_X != 1'b0)
				begin
				s_error = 1'b1;
				end

			repeat(1) @(negedge wb_clk_i);
			i_stdcell_A = 1'b0;
			i_stdcell_B = 1'b1;
			repeat(1) @(posedge wb_clk_i);
			if(o_stdcell_X != 1'b0)
				begin
				s_error = 1'b1;
				end

			repeat(1) @(negedge wb_clk_i);
			i_stdcell_A = 1'b1;
			i_stdcell_B = 1'b1;
			repeat(1) @(posedge wb_clk_i);
			if(o_stdcell_X != 1'b1)
				begin
				s_error = 1'b1;
				end


			repeat(1) @(negedge wb_clk_i);
		end
	endtask

	task clk_mux();
		begin

			repeat(1) @(negedge wb_clk_i);

			i_clkmux_S = 1'b0; //wb clock
			wb_write(7'b0000010, 32'hDEADBEEF); //Read from WB test counter
			spi_write(7'b0000010, 32'hF0F0F0F0); //Write to wb test counter

			repeat(5) @(negedge wb_clk_i);

			i_clkmux_S = 1'b1; //spi clock
			wb_write(7'b0000010, 32'hDEADBEEF); //Read from WB test counter
			spi_write(7'b0000010, 32'hF0F0F0F0); //Write to wb test counter

			repeat(5) @(negedge i_BCLK);

			i_clkmux_S = 1'b0; //wb clock
			repeat(1) @(negedge wb_clk_i);

		end
	endtask

	task custom_dff();
		begin

			repeat(1) @(negedge i_dff_CLK);
			i_dff_D = 1'b1;
			repeat(1) @(negedge i_dff_CLK);
			i_dff_D = 1'b0;
			repeat(3) @(negedge i_dff_CLK);

		end
	endtask

	task complete();
		begin
			if(s_error == 1'b0) begin //Pass indicator
				`ifdef GL
					$display("Monitor: Test (GL) Passed");
				`else
					$display("Monitor: Test (RTL) Passed");
				`endif
				$finish;
			end

			else begin //Fail indicator
				`ifdef GL
					$display("Monitor: Test (GL) Failed");
				`else
					$display("Monitor: Test (RTL) Failed");
				`endif
				$finish;
			end

		end
	endtask

endmodule
`default_nettype wire