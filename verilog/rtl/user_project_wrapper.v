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
/*
 *-------------------------------------------------------------
 *
 * user_project_wrapper
 *
 * This wrapper enumerates all of the pins available to the
 * user for the user project.
 *
 * An example user project is provided in this wrapper.  The
 * example should be removed and replaced with the actual
 * user project.
 *
 *-------------------------------------------------------------
 */
module user_project_wrapper #(
    parameter BITS = 32
) (
`ifdef USE_POWER_PINS
    inout vdda1,	// User area 1 3.3V supply
    inout vdda2,	// User area 2 3.3V supply
    inout vssa1,	// User area 1 analog ground
    inout vssa2,	// User area 2 analog ground
    inout vccd1,	// User area 1 1.8V supply
    inout vccd2,	// User area 2 1.8v supply
    inout vssd1,	// User area 1 digital ground
    inout vssd2,	// User area 2 digital ground
`endif

    // Wishbone Slave ports (WB MI A)
    input wb_clk_i,
    input wb_rst_i,
    input wbs_stb_i,
    input wbs_cyc_i,
    input wbs_we_i,
    input [3:0] wbs_sel_i,
    input [31:0] wbs_dat_i,
    input [31:0] wbs_adr_i,
    output wbs_ack_o,
    output [31:0] wbs_dat_o,

    // Logic Analyzer Signals
    input  [127:0] la_data_in,
    output [127:0] la_data_out,
    input  [127:0] la_oenb,

    // IOs
    input  [`MPRJ_IO_PADS-1:0] io_in,
    output [`MPRJ_IO_PADS-1:0] io_out,
    output [`MPRJ_IO_PADS-1:0] io_oeb,

    // Analog (direct connection to GPIO pad---use with caution)
    // Note that analog I/O is not available on the 7 lowest-numbered
    // GPIO pads, and so the analog_io indexing is offset from the
    // GPIO indexing by 7 (also upper 2 GPIOs do not have analog_io).
    inout [`MPRJ_IO_PADS-10:0] analog_io,

    // Independent clock (on independent integer divider)
    input   user_clock2,

    // User maskable interrupt signals
    output [2:0] user_irq
);

    //Memory Enable
    wire s_select_weight_memory;
    wire s_select_data_memory;
    
    wire s_we_weight_memory;
    wire s_we_data_memory;

    //Mem Address
    wire [9:0] s_weight_address;
    wire [9:0] s_data_address;

    //Mem Data In
    wire [7:0] s_weight_input;
    wire [7:0] s_data_input;

    //Mem Data Out
    wire [7:0] s_weight_out;
    wire [7:0] s_data_out;



   user_proj_final g_proj_final (
    `ifdef USE_POWER_PINS
      .vccd1(vccd1),	// User area 1 1.8V power
      .vssd1(vssd1),	// User area 1 digital ground
    `endif

    .wb_clk_i(wb_clk_i),
    .wb_rst_i(wb_rst_i),

    // MGMT SoC Wishbone Slave

    .wbs_cyc_i(wbs_cyc_i),
    .wbs_stb_i(wbs_stb_i),
    .wbs_we_i(wbs_we_i),
    .wbs_sel_i(wbs_sel_i),
    .wbs_adr_i(wbs_adr_i),
    .wbs_dat_i(wbs_dat_i),
    .wbs_ack_o(wbs_ack_o),
    .wbs_dat_o(wbs_dat_o),

    // Logic Analyzer

    .la_data_in(la_data_in),
    .la_data_out(la_data_out),
    .la_oenb (la_oenb),

    // IO Pads

    .io_in (io_in[37:0]),
    .io_out(io_out[37:0]),
    .io_oeb(io_oeb[37:0]),

    // IRQ
    .irq(user_irq),

    .i_WEIGHT_OUT_FINAL(s_weight_out),
    .i_DATA_OUT_FINAL(s_data_out),

    .o_SELECT_WEIGHT_MEMORY_FINAL(s_select_weight_memory),
    .o_SELECT_DATA_MEMORY_FINAL(s_select_data_memory),

    .o_WE_WEIGHT_MEMORY_FINAL(s_we_weight_memory),
    .o_WE_DATA_MEMORY_FINAL(s_we_data_memory),

    .o_WEIGHT_ADDRESS_FINAL(s_weight_address),
    .o_DATA_ADDRESS_FINAL(s_data_address),

    .o_WEIGHT_INPUT_FINAL(s_weight_input),
    .o_DATA_INPUT_FINAL(s_data_input)
);
   
  sky130_sram_1kbyte_1rw1r_8x1024_8 g_weight_memory(

        `ifdef USE_POWER_PINS
	        .vccd1(vccd1),	// User area 1 1.8V power
	        .vssd1(vssd1),	// User area 1 digital ground
        `endif

        // rw
        .clk0(wb_clk_i),
        .csb0(~s_select_weight_memory),
        .web0(~s_we_weight_memory),
        .addr0(s_weight_address),
        .din0(s_weight_input),
        .dout0(s_weight_out),
        // r
        .clk1(wb_clk_i),
        .csb1(~s_select_weight_memory),
        .addr1(),
        .dout1()
    );

    sky130_sram_1kbyte_1rw1r_8x1024_8 g_data_memory(

        `ifdef USE_POWER_PINS
	        .vccd1(vccd1),	// User area 1 1.8V power
	        .vssd1(vssd1),	// User area 1 digital ground
        `endif

        // rw
        .clk0(wb_clk_i),
        .csb0(~s_select_data_memory),
        .web0(~s_we_data_memory),
        .addr0(s_data_address),
        .din0(s_data_input),
        .dout0(s_data_out),
        // r
        .clk1(wb_clk_i),
        .csb1(~s_select_data_memory),
        .addr1(),
        .dout1()
    );

    (*keep*)
    SIGN g_signature(
        `ifdef USE_POWER_PINS
	        .vccd1(vccd1),
            .vssd1(vssd1)
        `endif
    );

endmodule	// user_project_wrapper

`default_nettype wire
