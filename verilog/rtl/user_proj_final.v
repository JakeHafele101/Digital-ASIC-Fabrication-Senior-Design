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
 * user_proj_example
 *
 * This is an example of a (trivially simple) user project,
 * showing how the user project can connect to the logic
 * analyzer, the wishbone bus, and the I/O pads.
 *
 * This project generates an integer count, which is output
 * on the user area GPIO pads (digital output only).  The
 * wishbone connection allows the project to be controlled
 * (start and stop) from the management SoC program.
 *
 * See the testbenches in directory "mprj_counter" for the
 * example programs that drive this user project.  The three
 * testbenches are "io_ports", "la_test1", and "la_test2".
 *
 *-------------------------------------------------------------
 */

module user_proj_final (
`ifdef USE_POWER_PINS
    inout vccd1,	// User area 1 1.8V supply
    inout vssd1,	// User area 1 digital ground
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
    output wbs_ack_o, //FIXME?
    output [31:0] wbs_dat_o,

    // Logic Analyzer Signals
    input  [127:0] la_data_in,
    output [127:0] la_data_out,
    input  [127:0] la_oenb,

    // IOs
    input  [37:0] io_in,
    output [37:0] io_out,
    output [37:0] io_oeb,

    // IRQ
    output [2:0] irq,

    //Memory Pass through

    input [7:0] i_WEIGHT_OUT_FINAL,
    input [7:0] i_DATA_OUT_FINAL,

    output o_SELECT_WEIGHT_MEMORY_FINAL,
    output o_SELECT_DATA_MEMORY_FINAL,

    output o_WE_WEIGHT_MEMORY_FINAL,
    output o_WE_DATA_MEMORY_FINAL,

    output [9:0] o_WEIGHT_ADDRESS_FINAL,
    output [9:0] o_DATA_ADDRESS_FINAL,

    output [7:0] o_WEIGHT_INPUT_FINAL,
    output [7:0] o_DATA_INPUT_FINAL
);

//Clock mux Internal signals
    wire clkmux_CLK_s;
    wire dsp_module_CLK_s;
    wire wb_module_CLK_s;

// Backdoor SPI Internal signals
    wire [6:0]  spi_module_adr_s;
    wire [31:0] spi_master_data_in_s; //Data FROM master SPI, wire to each module
    wire [31:0] spi_sel_module_data_out_s; //Data FROM master SPI, wire to each module
    wire        spi_master_WE_s; //WE from Master SPI

    wire [127:0] spi_total_module_data_out_s; //32-bit word for each design module
    wire [3:0]   spi_module_we_s; //one hot decoded WE for chosen module based on adr[2:0]

    wire [31:0] spi_module2_data_out_s, spi_module1_data_out_s;


//Wishbone Internal Signals
    wire [127:0] wb_total_module_data_out_s; //32-bit word for each design module
    wire [3:0]   wb_module_we_s; //one hot decoded WE for chosen module based on adr[2:0]

    wire [31:0] wb_module2_data_out_s, wb_module1_data_out_s;

    reg wbs_ack_delay; // Ack delay - Required due to bug in mgmt_core

// DSP Internal Signals

    wire dsp_weight_ack;
    wire dsp_data_ack;
    wire dsp_conv_ack;

    assign la_data_out[66] = dsp_weight_ack;
    assign la_data_out[67] = dsp_data_ack;
    assign la_data_out[68] = dsp_conv_ack;

    assign io_out[9] = dsp_weight_ack;
    assign io_out[10] = dsp_data_ack;
    assign io_out[11] = dsp_conv_ack;

    assign irq[0] = dsp_conv_ack;

    // Writes to 0x3003XXXX will cause a pulse on IRQ1
    assign irq[1] = wb_module_we_s[2];

/*--------------------------------------*/
/*             Backdoor SPI             */
/*--------------------------------------*/

    backdoor_spi g_backdoor_spi (
        .i_SYSCLK(clkmux_CLK_s),                  
        .i_BCLK(io_in[5]),                    //Master SPI clk
        .i_SS(io_in[6]),                      //Master SPI Slave Select, ACTIVE LOW
        .i_MOSI(io_in[7]),                    //Master Out, Slave In
        .i_DATA_OUT(spi_sel_module_data_out_s),    //Data from SPI Module control, per module address and register address

        .o_MISO(io_out[8]),                   //Master in, Slave Out
        .o_ADDR(spi_module_adr_s),            //7 bit address field for SPI module address, SPI reg address
        .o_DATA_IN(spi_master_data_in_s),    //Data from Master SPI, wire to each design module
        .o_DOUT_VALID(spi_master_WE_s)        //Write enable from master SPI, sent to g_backdoor_spi_module_control
    );

    module_control g_backdoor_spi_module_control (
        .we_i(spi_master_WE_s), ////Write enable from master SPI, from g_backdoor_spi
        .addr_i(spi_module_adr_s[2:0]), //portion of address for module selection
        .module_data_i(spi_total_module_data_out_s), //32 bit data from each module (4 total)
        .data_o(spi_sel_module_data_out_s), //Goes to SPI to be read by master
        .module_we_o(spi_module_we_s) //Write enable for specific module
    );

    assign spi_total_module_data_out_s = {{64{1'b0}}, spi_module2_data_out_s, spi_module1_data_out_s};

/*--------------------------------------*/
/*           Wishbone Bus               */
/*--------------------------------------*/

    module_control g_wishbone_module_control (
        .we_i(wbs_we_i && wbs_stb_i && wbs_cyc_i && wbs_ack_delay && (wbs_adr_i[31:20] == 12'h300)), ////Write enable from wishbone bus
        .addr_i(wbs_adr_i[18:16]), // module determination address
        .module_data_i(wb_total_module_data_out_s), //32 bit data from each module (4 total)
        .data_o(wbs_dat_o), //Goes to wb bus
        .module_we_o(wb_module_we_s) //Write enable for specific module
    );

    assign wb_total_module_data_out_s = {{64{1'b0}}, wb_module2_data_out_s, wb_module1_data_out_s};

    always @(posedge wb_clk_i)
        wbs_ack_delay <= wbs_stb_i && wbs_cyc_i && !wbs_ack_delay;

    assign wbs_ack_o = wbs_ack_delay;

/*--------------------------------------*/
/*            Clock Gating              */
/*--------------------------------------*/

    sky130_fd_sc_hdll__clkmux2_1 g_clkmux2_1 (
        `ifdef USE_POWER_PINS
            .VPWR(vccd1),
            .VGND(vssd1),
            .VPB(vccd1),
            .VNB(vssd1),
        `endif
        .X(clkmux_CLK_s),  //clk MUX output
        .A0(wb_clk_i), //Input 0, wishbone clock
        .A1(io_in[5]), //Input 1, SPI clock
        .S(la_data_in[72])  //Select line
    );

    assign la_data_out[69] = clkmux_CLK_s; // Clock output

    sky130_fd_sc_hdll__clkmux2_1 g_clkmux2_2 (
        `ifdef USE_POWER_PINS
            .VPWR(vccd1),
            .VGND(vssd1),
            .VPB(vccd1),
            .VNB(vssd1),
        `endif
        .X(wb_module_CLK_s),  //clk MUX output
        .A0(clkmux_CLK_s), //Input 0, wishbone clock
        .A1(la_data_in[73]), //Input 1, SPI clock
        .S(la_data_in[74])  //Select line
    );

    sky130_fd_sc_hdll__clkmux2_1 g_clkmux2_3 (
        `ifdef USE_POWER_PINS
            .VPWR(vccd1),
            .VGND(vssd1),
            .VPB(vccd1),
            .VNB(vssd1),
        `endif
        .X(dsp_module_CLK_s),  //clk MUX output
        .A0(clkmux_CLK_s), //Input 0, wishbone clock
        .A1(la_data_in[75]), //Input 1, SPI clock
        .S(la_data_in[76])  //Select line
    );

/*--------------------------------------*/
/*         Road Noise Filter            */
/*--------------------------------------*/

    dsp g_dsp (

        .i_CLK(dsp_module_CLK_s),      
        .i_RST(wb_rst_i || la_data_in[79]),

        .i_WISH_VALID(wb_module_we_s[0]),
        .i_SPI_VALID(spi_module_we_s[0]),

        .i_WISH_DATA(wbs_dat_i),
        .i_SPI_DATA(spi_master_data_in_s),

        .i_WEIGHT_OUT(i_WEIGHT_OUT_FINAL),
        .i_DATA_OUT(i_DATA_OUT_FINAL),

        .o_WEIGHT_ACK(dsp_weight_ack),
        .o_DATA_ACK(dsp_data_ack),
        .o_CONV_ACK(dsp_conv_ack),

        .o_WISH_DATA(wb_module1_data_out_s),     
        .o_SPI_DATA(spi_module1_data_out_s),

        .o_SELECT_WEIGHT_MEMORY(o_SELECT_WEIGHT_MEMORY_FINAL),
        .o_SELECT_DATA_MEMORY(o_SELECT_DATA_MEMORY_FINAL),

        .o_WE_WEIGHT_MEMORY(o_WE_WEIGHT_MEMORY_FINAL),
        .o_WE_DATA_MEMORY(o_WE_DATA_MEMORY_FINAL),

        .o_WEIGHT_ADDRESS(o_WEIGHT_ADDRESS_FINAL),
        .o_DATA_ADDRESS(o_DATA_ADDRESS_FINAL),

        .o_WEIGHT_INPUT(o_WEIGHT_INPUT_FINAL),
        .o_DATA_INPUT(o_DATA_INPUT_FINAL)  
    );


/*--------------------------------------*/
/*             Wishbone Test            */
/*--------------------------------------*/
    //Module 02 for module addressing, addr[2:0] = 010
    wishbone_test g_wishbone_test (
        .clk_i(wb_module_CLK_s), 
        .rst_i(wb_rst_i),
        .wb_we_i(wb_module_we_s[1]),
        .wb_sel_i(wbs_sel_i),
        .wb_dat_i(wbs_dat_i),
        .wb_dat_o(wb_module2_data_out_s),

        .spi_we_i(spi_module_we_s[1]),
        .spi_data_i(spi_master_data_in_s),
        .spi_data_o(spi_module2_data_out_s) 
    );

/*--------------------------------------*/
/*          Standard Cell Test          */
/*--------------------------------------*/

    assign la_data_out[64] = la_data_in[70] && la_data_in[71];

/*--------------------------------------*/
/*          Custom Cell Test            */
/*--------------------------------------*/
    
    NAND g_NAND(
        `ifdef USE_POWER_PINS
            .VPWR(vccd1),
            .VGND(vssd1),
            .VPB(vccd1),
            .VNB(vssd1),
        `endif
        .A(la_data_in[77]),
        .B(la_data_in[78]),
        .X(la_data_out[65])
    );

/*--------------------------------------*/
/*             Caravel I/O              */
/*--------------------------------------*/

    //Logic Analyzer
    assign la_data_out[31:0] = wb_module2_data_out_s; //wishbone test 32bit counter
    assign la_data_out[63:32] = wb_module1_data_out_s; //DSP output
    assign la_data_out[127:70] = 0; //Fill remaining bits to 0

    // IO
    assign io_out[7:0] = 0; //Fill remaining bits to 0
    assign io_out[37:12] = 0; //Fill remaining bits to 0
    assign io_oeb = la_data_in[127:90];
    // IRQ
    assign irq[2] = 0; // Unused

endmodule
`default_nettype wire


