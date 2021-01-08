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

`define   TEST_FILE   "../sw_n5/test.hex" 
`define   SIM_TIME    1500_000
`define   SIM_LEVEL   0

`define SOC_SETUP_TIME 800*2001

`include "spiflash.v"

`include "sst26wf080b.v"
`include "23LC512.v"
`include "caravel.v"

`ifdef SIM

`ifdef FAST
    `define USE_DFFRAM_BEH
    `define NO_HC_CACHE
    `include "DFFRAM_beh.v"
`else
	`ifndef GL_UA
		`include "user_project/IPs/DFFRAM_4K.v"
		`include "user_project/IPs/DFFRAMBB.v"
		`include "user_project/IPs/DMC_32x16HC.v"
	`endif
`endif

`ifdef GL_UA
	`include "gl/user_project/gl/apb_sys_0.v"
	`include "gl/user_project/gl/DFFRAM_4K.v"
	`include "gl/user_project/gl/DMC_32x16HC.v"
	`include "gl/user_project/gl/NfiVe32_SYS.v"
	`include "gl/user_project/gl/user_project_wrapper.v"
`else

`include "user_project/AHB_sys_0/AHBlite_sys_0.v"

`include "user_project/AHB_sys_0/AHBlite_bus0.v"
`include "user_project/AHB_sys_0/AHBlite_GPIO.v"
`include "user_project/AHB_sys_0/AHBlite_db_reg.v"

`include "user_project/AHB_sys_0/APB_sys_0/APB_WDT32.v"
`include "user_project/AHB_sys_0/APB_sys_0/APB_TIMER32.v"
`include "user_project/AHB_sys_0/APB_sys_0/APB_PWM32.v"
`include "user_project/AHB_sys_0/APB_sys_0/AHB_2_APB.v"
`include "user_project/AHB_sys_0/APB_sys_0/APB_bus0.v"
`include "user_project/AHB_sys_0/APB_sys_0/APB_sys_0.v"

`include "user_project/IPs/TIMER32.v"
`include "user_project/IPs/PWM32.v"
`include "user_project/IPs/WDT32.v"
`include "user_project/IPs/spi_master.v"
`include "user_project/IPs/i2c_master.v"
`include "user_project/IPs/GPIO.v"
`include "user_project/IPs/APB_UART.v"
`include "user_project/IPs/APB_SPI.v"
`include "user_project/IPs/APB_I2C.v"
`include "user_project/IPs/AHBSRAM.v"
`include "user_project/acc/AHB_SPM.v"

`include "user_project/IPs/QSPI_XIP_CTRL.v"
`include "user_project/IPs/DMC_32x16HC.v"

`include "user_project/IPs/RAM_4Kx32.v"
`include "user_project/IPs/RAM_3Kx32.v"

`include "user_project/DFFRFile.v"

`include "user_project/NfiVe32.v"
`include "user_project/soc_core.v"

`endif
`endif

module io_ports_tb;
	reg clock;
    reg RSTB;
	reg power1, power2;
	reg power3, power4;

	wire gpio;
	wire [37:0] mprj_io;
	wire [7:0] mprj_io_0;

	assign mprj_io_0 = mprj_io[7:0];

	// External clock is used by default.  Make this artificially fast for the
	// simulation.  Normally this would be a slow clock and the digital PLL
	// would be the fast clock.

	always #12.5 clock <= (clock === 1'b0);

	initial begin
		clock = 0;
	end

	// GPIO Loopback!
    // wire [13:0] GPIO_PINS;
    // generate
    //     genvar i;
    //     for(i=0; i<14; i=i+1)
    //         assign GPIO_PINS[i] = GPIOOEN_Sys0_S2[i] ? GPIOOUT_Sys0_S2[i] : 1'bz;
    // endgenerate

    // assign GPIO_PINS[15:8] = GPIO_PINS[7:0];
    // assign GPIOIN_Sys0_S2 = GPIO_PINS;

	// Serial Terminal connected to UART0 TX*/
    terminal term(.rx(mprj_io[21]));  // RsTx_Sys0_SS0_S0

    // SPI SRAM connected to SPI0
    wire SPI_HOLD = 1'b1;
    M23LC512 SPI_SRAM(
        .RESET(~RSTB),
        .SO_SIO1(mprj_io[24]),  // MSI_Sys0_SS0_S2
        .SI_SIO0(mprj_io[25]),  // MSO_Sys0_SS0_S2
        .CS_N(mprj_io[26]),     // SSn_Sys0_SS0_S2
        .SCK(mprj_io[27]),      // SCLK_Sys0_SS0_S2
        .HOLD_N_SIO3(SPI_HOLD)
	);

	initial begin
		// Load the application into the N5 flash memory
		#1  $readmemh(`TEST_FILE, flash.I0.memory);
		$display("---------N5 Flash -----------");
		$display("Memory[0]: %0d, Memory[1]: %0d, Memory[2]: %0d, Memory[3]: %0d", 
            flash.I0.memory[0], flash.I0.memory[1], flash.I0.memory[2], flash.I0.memory[3]);
	end

	initial begin
		$dumpfile("io_ports.vcd");
		$dumpvars(0, io_ports_tb);

		RSTB <= 1'b0;
		#2000;
		RSTB <= 1'b1;	    // Release reset
		#(`SOC_SETUP_TIME);
		#(`SIM_TIME);
	    $finish;
	end

	initial begin		// Power-up sequence
		power1 <= 1'b0;
		power2 <= 1'b0;
		power3 <= 1'b0;
		power4 <= 1'b0;
		#200;
		power1 <= 1'b1;
		#200;
		power2 <= 1'b1;
		#200;
		power3 <= 1'b1;
		#200;
		power4 <= 1'b1;
	end

	wire flash_csb;
	wire flash_clk;
	wire flash_io0;
	wire flash_io1;

	wire VDD3V3 = power1;
	wire VDD1V8 = power2;
	wire USER_VDD3V3 = power3;
	wire USER_VDD1V8 = power4;
	wire VSS = 1'b0;

	caravel uut (
		.vddio	  (VDD3V3),
		.vssio	  (VSS),
		.vdda	  (VDD3V3),
		.vssa	  (VSS),
		.vccd	  (VDD1V8),
		.vssd	  (VSS),
		.vdda1    (USER_VDD3V3),
		.vdda2    (USER_VDD3V3),
		.vssa1	  (VSS),
		.vssa2	  (VSS),
		.vccd1	  (USER_VDD1V8),
		.vccd2	  (USER_VDD1V8),
		.vssd1	  (VSS),
		.vssd2	  (VSS),
		.clock	  (clock),
		.gpio     (gpio),
        .mprj_io  (mprj_io),
		.flash_csb(flash_csb),
		.flash_clk(flash_clk),
		.flash_io0(flash_io0),
		.flash_io1(flash_io1),
		.resetb	  (RSTB)
	);

	spiflash #(
		.FILENAME("io_ports.hex")
	) spiflash (
		.csb(flash_csb),
		.clk(flash_clk),
		.io0(flash_io0),
		.io1(flash_io1),
		.io2(),			// not used
		.io3()			// not used
	);

	/* N5 Flash */
    sst26wf080b flash(
        .SCK(mprj_io[18]),     // fsclk
        .SIO(mprj_io[17:14]),  // fdo
        .CEb(mprj_io[19])      // fcen
    );

endmodule

module terminal #(parameter bit_time = 400) (input rx);

    integer i;
    reg [7:0] char;
    initial begin
        forever begin
            @(negedge rx);
            i = 0;
            char = 0;
            #(3*bit_time/2);
            for(i=0; i<8; i=i+1) begin
                char[i] = rx;
                #bit_time;
            end
            $write("%c", char);
        end
    end


endmodule
`default_nettype wire
