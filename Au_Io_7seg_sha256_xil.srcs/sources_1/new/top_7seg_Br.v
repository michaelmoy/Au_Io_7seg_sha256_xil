`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: MoySys, LLC
// Engineer: Michael Moy
//
// Create Date: 09/13/2020 02:54:34 PM
// Design Name: Au_Io_7seg_sha256_xil
// Module Name: top_7seg_Br
// Project Name: Au_Io_7seg_sha256_xil
// Target Devices: Io Shield on top of the Au FPGA base.
// Tool Versions:
// Description:  Top level Project for SHA256 calculations with the SHA256 output
//               displayed on the 7-SEG displays of the Alchitry Au-Io Board setup.
//
//               This project currently does one 512bit block.
//
// Dependencies:
//
// Revision 1.0 - 09/23/2020 MEM Original Art. Refactored from the AuIo 7seg display project.
//
// Additional Comments:
//
// Author: Michael Moy
// Copyright (c) 2020, MoySys, LLC
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or
// without modification, are permitted provided that the following
// conditions are met:
//
// 1. Redistributions of source code must retain the above copyright
//    notice, this list of conditions and the following disclaimer.
//
// 2. Redistributions in binary form must reproduce the above copyright
//    notice, this list of conditions and the following disclaimer in
//    the documentation and/or other materials provided with the
//    distribution.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
// LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
// FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
// COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
// INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
// BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
// LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
// STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
// ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
//
//////////////////////////////////////////////////////////////////////////////////


module top_7seg_Br(
    input clk,
    input rst_n,
    input usb_rx,           // USB->Serial input
    output usb_tx,           // USB->Serial output
    output [7:0] led,       // 8 user controllable LEDs
	output wire [7:0] io_seg,
	output wire [3:0] io_sel
    );

// internal segment data. The Display Controller drives this
wire [7:0] io_seg_int;

// digit values to display
reg [3:0] val3;
reg [3:0] val2;
reg [3:0] val1;
reg [3:0] val0;

// digit enable flags
wire ena_3 = 1;
wire ena_2 = 1;
wire ena_1 = 1;
wire ena_0 = 1;

// free running counter
reg [64:0] counter;




//----------------------------------------------------------------
// Internal constant and parameter definitions.
//----------------------------------------------------------------
parameter DEBUG = 0;

parameter CLK_HALF_PERIOD = 2;
parameter CLK_PERIOD = 2 * CLK_HALF_PERIOD;

// The address map.
parameter ADDR_NAME0       = 8'h00;
parameter ADDR_NAME1       = 8'h01;
parameter ADDR_VERSION     = 8'h02;

parameter ADDR_CTRL        = 8'h08;
parameter CTRL_INIT_VALUE  = 8'h01;
parameter CTRL_NEXT_VALUE  = 8'h02;
parameter CTRL_MODE_VALUE  = 8'h04;

parameter ADDR_STATUS      = 8'h09;
parameter STATUS_READY_BIT = 0;
parameter STATUS_VALID_BIT = 1;

parameter ADDR_BLOCK0    = 8'h10;
parameter ADDR_BLOCK1    = 8'h11;
parameter ADDR_BLOCK2    = 8'h12;
parameter ADDR_BLOCK3    = 8'h13;
parameter ADDR_BLOCK4    = 8'h14;
parameter ADDR_BLOCK5    = 8'h15;
parameter ADDR_BLOCK6    = 8'h16;
parameter ADDR_BLOCK7    = 8'h17;
parameter ADDR_BLOCK8    = 8'h18;
parameter ADDR_BLOCK9    = 8'h19;
parameter ADDR_BLOCK10   = 8'h1a;
parameter ADDR_BLOCK11   = 8'h1b;
parameter ADDR_BLOCK12   = 8'h1c;
parameter ADDR_BLOCK13   = 8'h1d;
parameter ADDR_BLOCK14   = 8'h1e;
parameter ADDR_BLOCK15   = 8'h1f;

parameter ADDR_DIGEST0   = 8'h20;
parameter ADDR_DIGEST1   = 8'h21;
parameter ADDR_DIGEST2   = 8'h22;
parameter ADDR_DIGEST3   = 8'h23;
parameter ADDR_DIGEST4   = 8'h24;
parameter ADDR_DIGEST5   = 8'h25;
parameter ADDR_DIGEST6   = 8'h26;
parameter ADDR_DIGEST7   = 8'h27;

parameter SHA224_MODE    = 0;
parameter SHA256_MODE    = 1;

parameter STATE_IDLE             = 0;
parameter STATE_WR_BLOCK         = 1;
parameter STATE_CTRL_INIT        = 3;
parameter STATE_CTRL_INIT_NEXT   = 4;
parameter STATE_WAIT_READY       = 5;
parameter STATE_READ_DIGEST      = 7;
parameter STATE_DISP_SHA         = 9;


//----------------------------------------------------------------
// Register and Wire declarations.
//----------------------------------------------------------------
reg           tb_cs;
reg           tb_we;
reg [27 : 0]   tb_address; // MOY [7 : 0]   tb_address;
reg [31 : 0]  tb_write_data;
wire [31 : 0] tb_read_data;
wire          tb_error;

reg [31 : 0]  read_data;
reg [255 : 0] digest_data;

reg [3:0] state;

reg [511:0] block;
reg [7:0] blk_cnt;

//----------------------------------------------------------------
// Device Under Test.
//----------------------------------------------------------------
sha256 dut(
		.clk(clk),
		.reset_n(rst_n),
		.cs(tb_cs),
		.we(tb_we),
		.address(tb_address),
		.write_data(tb_write_data),
		.read_data(tb_read_data),
		.error(tb_error)
		);

assign usb_tx = usb_rx ;



// load the Au LED's from the free running counter
assign led[7:0] = counter[27:20];

// wire up the segments as needed. Set DP off:1 for now
assign io_seg[0] = ~io_seg_int[6];
assign io_seg[1] = ~io_seg_int[5];
assign io_seg[2] = ~io_seg_int[4];
assign io_seg[3] = ~io_seg_int[3];
assign io_seg[4] = ~io_seg_int[2];
assign io_seg[5] = ~io_seg_int[1];
assign io_seg[6] = ~io_seg_int[0];
assign io_seg[7] = ~io_seg_int[7];

// wire up the Io Board 4 Digit 7seg Display Controller
IoBd_7segX4 IoBoard7segDisplay(
	.clk(clk),
	.reset(~rst_n),

	.seg3_hex(val3),
	.seg3_dp(0),
	.seg3_ena(ena_3),

	.seg2_hex(val2),
	.seg2_dp(0),
	.seg2_ena(ena_2),

	.seg1_hex(val1),
	.seg1_dp(0),
	.seg1_ena(ena_1),

	.seg0_hex(val0),
	.seg0_dp(0),
	.seg0_ena(ena_0),

	.bright(4'h4),
	.seg_data(io_seg_int),
	.seg_select(io_sel)
	);

// keep a free running counter to use for Display Data
always @(posedge clk) begin
	if(rst_n == 0) begin
		counter <= 0;
		end
	else begin
		if( usb_rx == 0 )
			counter <= 0;
		else
			counter <= counter + 1;
		end
	end

// the state machine
always @(posedge clk or negedge rst_n) begin
	if(rst_n == 0) begin
		state <= STATE_IDLE;
		tb_cs <= 0;
		tb_we <= 0;
		tb_address <= 26'h0; // MOY 6'h0;
		tb_write_data <= 32'h0;

		// Input block: 'abc' with padding added
		block <= 512'h61626380000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000018;

		// set the display to all zero'z
		val3 <= 0 ;
		val2 <= 0;
		val1 <= 0;
		val0 <= 0;

		end
	else begin

		case(state)
			STATE_IDLE: begin
				state <= STATE_WR_BLOCK;
				tb_address <= ADDR_BLOCK0;
				tb_write_data <= block[511 : 480];
				tb_cs <= 1;
				tb_we <= 1;
				blk_cnt <= 0;
				digest_data <= 0 ;
				end
			STATE_WR_BLOCK: begin
				if( blk_cnt == 15 ) begin
					state <= STATE_CTRL_INIT;
					tb_address <= ADDR_CTRL;
					tb_write_data <= (CTRL_MODE_VALUE + CTRL_INIT_VALUE);
					end
				else begin
					block <= block << 32 ;
					tb_address <= tb_address + 1;
					tb_write_data <= block[479 : 448];
					blk_cnt <= blk_cnt + 1;
					end
				end
			STATE_CTRL_INIT: begin
				state <= STATE_CTRL_INIT_NEXT;
				tb_cs <= 0;
				tb_we <= 0;
				end
			STATE_CTRL_INIT_NEXT: begin
				state <= STATE_WAIT_READY;
				tb_cs <= 1;
				tb_we <= 0;
				read_data <= 0;
				tb_address <= ADDR_STATUS;
				end
			STATE_WAIT_READY: begin
				if( tb_read_data != 3 )
					state <= STATE_WAIT_READY;
				else begin
					state <= STATE_READ_DIGEST;
					tb_address <= ADDR_DIGEST0;
					blk_cnt <= 0;
					digest_data <= 0;
					end
				end
			STATE_READ_DIGEST: begin
				if( blk_cnt == 8 ) begin
					state <= STATE_DISP_SHA;
					tb_cs <= 0;
					end
				else begin
					tb_address <= tb_address + 1;
					digest_data[31 : 0] <= tb_read_data;
					digest_data[255:32] <= digest_data[223:0];
					blk_cnt <= blk_cnt + 1;
					end
				end
			STATE_DISP_SHA: begin
//					state <= STATE_IDLE;

					// load the 7seg digit values from some of the top bytes of the SHA256 Sum output
					if( counter[29:28] == 0 ) begin
						val3 <= digest_data[255 : 252];
						val2 <= digest_data[251 : 248];
						val1 <= digest_data[247 : 244];
						val0 <= digest_data[243 : 240];
						end
					else  if( counter[29:28] == 1 ) begin
						val3 <= digest_data[239 : 236];
						val2 <= digest_data[235 : 232];
						val1 <= digest_data[231 : 228];
						val0 <= digest_data[227 : 224];
						end
					else  if( counter[29:28] == 2 ) begin
						val3 <= digest_data[223 : 220];
						val2 <= digest_data[219 : 216];
						val1 <= digest_data[215 : 212];
						val0 <= digest_data[211 : 208];
						end
					else begin
						val3 <= digest_data[207 : 204];
						val2 <= digest_data[203 : 200];
						val1 <= digest_data[199 : 196];
						val0 <= digest_data[195 : 192];
						end
					end

			default: begin
				state <= STATE_IDLE;
			end
		endcase
		end
	end


endmodule
