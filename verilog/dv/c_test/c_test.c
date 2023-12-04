/*
 * SPDX-FileCopyrightText: 2020 Efabless Corporation
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 * SPDX-License-Identifier: Apache-2.0
 */

// This include is relative to $CARAVEL_PATH (see Makefile)
//#include "verilog/dv/caravel/defs.h"
#include <defs.h>
//#include "verilog/dv/caravel/stub.c"
#include <stub.c>
#include <irq_vex.h>
#include <stdbool.h>

#define USER_MODULE_DSP (*(volatile uint32_t *)(USER_SPACE_ADDR + 0x10000))
#define USER_MODULE_WB (*(volatile uint32_t *)(USER_SPACE_ADDR + 0x20000))

// Any write to this range (0x3003XXXX) will toggle IRQ1 value
#define USER_MODULE_TRIGGER_IRQ1 (*(volatile uint32_t *)(USER_SPACE_ADDR + 0x30000))


void start() {
	/* Set up the housekeeping SPI to be connected internally so	*/
	/* that external pin changes don't affect it.			*/

	/* both of the following registers need to be enabled
	   enabling just one of them or none of them causes
	   the simulation to run infinitely and stopping after
	   the timeout number of cycles */

	// Set all LA probes to input
	reg_la0_oenb = reg_la0_iena = 0;
	reg_la1_oenb = reg_la1_iena = 0;
	reg_la2_oenb = reg_la2_iena = 0;
	reg_la3_oenb = reg_la3_iena = 0;

	// Clkmux control pins, default to mgmt clock, dsp & wb clocked on mgmt clock
	reg_la2_data = 0;
	reg_la2_oenb |= (1 << 8) | (1 << 9) | (1 << 10) | (1 << 11) | (1 << 12);
	reg_la2_iena |= (1 << 8) | (1 << 9) | (1 << 10) | (1 << 11) | (1 << 12);

	reg_spi_enable = 1;
	reg_wb_enable = 1;
	reg_uart_enable = 1;


	// GPIO pin 0 Used to flag the start/end of a test 
	// GPIO pin 1 Used to flag the pass/fail of a test
	reg_mprj_io_0 = GPIO_MODE_MGMT_STD_OUTPUT;
	reg_mprj_io_1 = GPIO_MODE_MGMT_STD_OUTPUT;

	// UNUSED
	reg_mprj_io_5  =  GPIO_MODE_USER_STD_INPUT_PULLDOWN;
	reg_mprj_io_6  =  GPIO_MODE_USER_STD_INPUT_NOPULL;
	reg_mprj_io_7  =  GPIO_MODE_USER_STD_INPUT_NOPULL;
	reg_mprj_io_8  =  GPIO_MODE_USER_STD_INPUT_NOPULL;

	// DSP
	reg_mprj_io_9  =  GPIO_MODE_USER_STD_OUT_MONITORED;
	reg_mprj_io_10 =  GPIO_MODE_USER_STD_OUT_MONITORED;
	reg_mprj_io_11 =  GPIO_MODE_USER_STD_OUT_MONITORED;

	// UNUSED
	reg_mprj_io_36 =  GPIO_MODE_USER_STD_INPUT_NOPULL;
	reg_mprj_io_37 =  GPIO_MODE_USER_STD_INPUT_NOPULL;
	reg_mprj_io_16 =  GPIO_MODE_USER_STD_OUTPUT;
	reg_mprj_io_17 =  GPIO_MODE_USER_STD_OUTPUT;
	reg_mprj_io_18 =  GPIO_MODE_USER_STD_OUTPUT;
	reg_mprj_io_19 =  GPIO_MODE_USER_STD_OUTPUT;
	reg_mprj_io_20 =  GPIO_MODE_USER_STD_OUTPUT;
	reg_mprj_io_21 =  GPIO_MODE_USER_STD_OUTPUT;
	reg_mprj_io_22 =  GPIO_MODE_USER_STD_OUTPUT;
	reg_mprj_io_23 =  GPIO_MODE_USER_STD_OUTPUT;
	reg_mprj_io_24 =  GPIO_MODE_USER_STD_OUTPUT;
	reg_mprj_io_25 =  GPIO_MODE_USER_STD_OUTPUT;
	reg_mprj_io_26 =  GPIO_MODE_USER_STD_OUTPUT;
	reg_mprj_io_27 =  GPIO_MODE_USER_STD_OUTPUT;
	reg_mprj_io_28 =  GPIO_MODE_USER_STD_OUTPUT;
	reg_mprj_io_29 =  GPIO_MODE_USER_STD_OUTPUT;
	reg_mprj_io_30 =  GPIO_MODE_USER_STD_OUTPUT;
	reg_mprj_io_31 =  GPIO_MODE_USER_STD_OUTPUT;

	/* Apply configuration */
	reg_mprj_xfer = 1;
	while (reg_mprj_xfer == 1);

	// Flag start of the test
	reg_mprj_datal = 1;
}

void fail() {
	reg_mprj_datal = 0;
	while (true) continue;
}

void pass() {
	reg_mprj_datal = 2;
	while (true) continue;
}

void test_standard_cell() {
	// Test standard cell AND gate
	// Enable inputs and outputs
	// output enable is active low, input enable is active high. See dv/README.md
	reg_la2_oenb |= (1 << 6) | (1 << 7);
	reg_la2_iena |= (1 << 6) | (1 << 7);

	// Test all four cases
	reg_la2_data = 0;
	if (reg_la2_data_in & (1 << 0)) fail();
	reg_la2_data = (1 << 6);
	if (reg_la2_data_in & (1 << 0)) fail();
	reg_la2_data = (1 << 7);
	if (reg_la2_data_in & (1 << 0)) fail();
	reg_la2_data = (1 << 6) | (1 << 7);
	if (!(reg_la2_data_in & (1 << 0))) fail();
}


void test_custom_cell() {
	// Test custom cell NAND gate
	// Enable inputs and outputs
	// output enable is active low, input enable is active high. See dv/README.md
	reg_la2_oenb |= (1 << 13) | (1 << 14);
	reg_la2_iena |= (1 << 13) | (1 << 14);

	// Test all four cases
	reg_la2_data = 0;
	if (!(reg_la2_data_in & (1 << 1))) fail();
	reg_la2_data = (1 << 13);
	if (!(reg_la2_data_in & (1 << 1))) fail();
	reg_la2_data = (1 << 14);
	if (!(reg_la2_data_in & (1 << 1))) fail();
	reg_la2_data = (1 << 13) | (1 << 14);
	if (reg_la2_data_in & (1 << 1)) fail();
}

void test_wishbone_test() {
	// asm("addi sp,sp,-32; \
	// 	   sw s0,24(sp); \
	// 		 addi s0,sp,32");


	// asm("lui a5,0x30020; \
	//      lw a4,0(a5); \
	// 		 sw a4,4(a5); \
	// 		 sw s0,8(a5); \
	// 		 sw a4,-28(s0); \
	// 		 sw a4,12(a5); \
	// 		 lw a4,-28(s0); \
	// 		 sw a4,16(a5)");


	// asm("lw s0,24(sp); \
	// 		 addi sp,sp,32");



	// Verify it counts upwards from 0
	USER_MODULE_WB = 0;
	if (USER_MODULE_WB > 0x1000) fail();
	if (reg_la0_data_in > 0x1000) fail();

	// Verify it counts upwards after a load
	USER_MODULE_WB = 0xDEADBEEF;
	if (USER_MODULE_WB < 0xDEADBEEF) fail();
	if (USER_MODULE_WB > 0xDEADDEEF) fail();
	if (reg_la0_data_in < 0xDEADBEEF) fail();
	if (reg_la0_data_in > 0xDEADDEEF) fail();
	

	// Verify it counts continually increasing
	USER_MODULE_WB = 0;
	uint32_t last = USER_MODULE_WB;
	for (int i = 0; i < 10; i++) {
		uint32_t tmp = USER_MODULE_WB;
		if (tmp <= last) fail();
		last = tmp;
	}

	// Verify you can write to an individual byte without overwriting the rest
	USER_MODULE_WB = 0x33221100;
	((volatile uint8_t *)&USER_MODULE_WB)[3] = 0x44;
	if (USER_MODULE_WB < 0x44221100) fail();
	if (USER_MODULE_WB > 0x44223100) fail();


	// Try clocking manually using the clkmux
	// First, route the wishbone clock to the LA pin 9
	reg_la2_data = (1 << 10);
	// You cannot write to the wishbone registers with the clock on the LA pin
	// As the wishbone bus will finish the transaction before you
	// can send a rising edge on the clock here.
	// So we will just read via the LA probes

	// No change expected - no clock received
	uint32_t tmp = reg_la0_data_in;
	if (reg_la0_data_in != tmp) fail();

	// one clock = one increment
	reg_la2_data = (1 << 10) | (1 << 9);
	reg_la2_data = (1 << 10);
	if (reg_la0_data_in != tmp + 1) fail();

	// Disable the primary clkmux, verify no clocking still
	reg_la2_data = (1 << 8) | (1 << 10);
	if (reg_la0_data_in != tmp + 1) fail();

	// And disconnect the LA probes, no change expected
	reg_la2_data = (1 << 8);
	if (reg_la0_data_in != tmp + 1) fail();

	// And turn the main clock back on
	reg_la2_data = 0;
}


volatile bool irq1_ack = false;
volatile bool irq0_ack = false;

void isr(void) {
	if (user_irq_1_ev_pending_read()) {
		USER_MODULE_TRIGGER_IRQ1 = 0x12345678;
		irq1_ack = true;
		// Clear pending interrupt
		user_irq_1_ev_pending_write(1);
	}

	if (user_irq_0_ev_pending_read()) {
		irq0_ack = true;
		// Clear pending interrupt
		user_irq_0_ev_pending_write(1);
	}

	return;
}

void test_dsp() {
	// Initialize (1 << 15) to output, and (1 << 8) | (1 << 9) | (1 << 10) to input
	reg_la2_oenb |= (1 << 15);
	reg_la2_iena |= (1 << 15);

	// Set the reset pin high
	reg_la2_data |= (1 << 15);
	// Set the reset pin low
	reg_la2_data &= ~(1 << 15);


	// Load weights (1024)
	for (int i = 0; i < 1024; i++) {
		USER_MODULE_DSP = i;
	}

	// Load data (1024)
	for (int i = 0; i < 1024; i++) {
		USER_MODULE_DSP = 1;
	}
	
	// Start Convolution (circular buffer. this byte is shifted in, data[0] is shifted out)
	USER_MODULE_DSP = 1;

	// Wait for convolution to complete by polling first
	while (!(reg_la2_data_in & (1 << 4))) continue;
	if (USER_MODULE_DSP != 0x1FE00) fail();
	if (reg_la1_data_in != 0x1FE00) fail();


	// Run two more convolutions vi IRQ
	
	// Enable the DSP convolution complete interrupt
	irq_setie(irq_getie() | (1 << USER_IRQ_0_INTERRUPT));
	irq_setmask(irq_getmask() | (1 << USER_IRQ_0_INTERRUPT));
	// Enable the IRQ both on the IRQ's enable line, and in user_irq_ena
	user_irq_ena_out_write(1 << 0);
	user_irq_0_ev_pending_write(1); // Clear any pending interrupt
	user_irq_0_ev_enable_write(1);
	irq0_ack = false;
	

	// write to the DSP module's input, this clears the ack interrupt line
	USER_MODULE_DSP = 2;
	// Wait for interrupt
	while (!irq0_ack) continue;
	irq0_ack = false;

	if (USER_MODULE_DSP != 0x1FEFF) fail();
	if (reg_la1_data_in != 0x1FEFF) fail();


	USER_MODULE_DSP = 3;
	while (!irq0_ack) continue;
	irq0_ack = false;

	if (USER_MODULE_DSP != 0x200FC) fail();
	if (reg_la1_data_in != 0x200FC) fail();
}

void test_irq1() {
	irq_setie(irq_getie() | (1 << USER_IRQ_1_INTERRUPT));
	irq_setmask(irq_getmask() | (1 << USER_IRQ_1_INTERRUPT));

	// Enable the IRQ both on the IRQ's enable line, and in user_irq_ena
	user_irq_ena_out_write(1 << 1);
	user_irq_1_ev_enable_write(1);

	irq1_ack = false;

	USER_MODULE_TRIGGER_IRQ1 = 1;
	while (!irq1_ack) continue;
	irq1_ack = false;

	USER_MODULE_TRIGGER_IRQ1 = 2;
	while (!irq1_ack) continue;
	irq1_ack = false;
}

void main()
{
	start();

	test_irq1();
	test_standard_cell();
	test_custom_cell();
	test_wishbone_test();
	test_dsp();
	
	pass();
}

