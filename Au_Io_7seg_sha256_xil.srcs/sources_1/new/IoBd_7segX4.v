`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: MoySys, LLC
// Engineer: Michael Moy
//
// Create Date: 09/13/2020 03:13:38 PM
// Design Name:
// Module Name: IoBd_7segX4
// Project Name:
// Target Devices:
// Tool Versions:
// Description:
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////


module IoBd_7segX4(
	input clk,
	input reset,
	input [3:0] seg3_hex,
	input seg3_dp,
	input seg3_ena,
	input [3:0] seg2_hex,
	input seg2_dp,
	input seg2_ena,
	input [3:0] seg1_hex,
	input seg1_dp,
	input seg1_ena,
	input [3:0] seg0_hex,
	input seg0_dp,
	input seg0_ena,
	input [3:0] bright,
	output reg [7:0] seg_data,
	output reg [3:0] seg_select
	);


// State values and Hold time contant
localparam	STATE_IDLE  = 0,	// Initial/Reset state
			STATE_SEG_3 = 1,	// display Left most Digit
			STATE_SEG_2 = 2,	// display second digit
			STATE_SEG_1 = 3,	// display third digit
			STATE_SEG_0 = 4,	// display right most digit
			STATE_DARK  = 5,	// all displays off to control brightness
			
			LED_HOLD_CNT = 500;	// keep the display iluminated for a while

reg [2:0] seg_state;
reg [15:0] dark_period;
reg [15:0] hold;

reg [3:0] hex_val;

wire [6:0] seg_data_int;
reg        seg_data_dp;

wire       not_blanking;

//assign seg_data[6:0] = ( not_blanking ? seg_data_int[6:0] : 6'b000000 );
//assign seg_data[7]   = ( not_blanking ? seg_data_dp      : 0 );
always @(posedge clk) begin
	seg_data[6:0] <= ( not_blanking ? seg_data_int[6:0] : 6'b000000 );
	seg_data[7]   <= ( not_blanking ? seg_data_dp      : 0 );
end

assign not_blanking =  ( hold < (LED_HOLD_CNT-3) && hold > 3 );


// wire up the hex to 7 seg pattern converter
hexto7segment h27seg(
	.hex_in(hex_val),
	.seg_out(seg_data_int[6:0])
	);

// Digit-Segment controller State Machine
always @(posedge clk or posedge reset)begin
	if(reset) begin
		dark_period <= 0;
		seg_select[3] <= 1;
		seg_select[2] <= 1;
		seg_select[1] <= 1;
		seg_select[0] <= 1;
		seg_state <= STATE_IDLE;
		hex_val <= seg3_hex;
		seg_data_dp <= seg3_dp;
		hold <= LED_HOLD_CNT;
		end
	else begin
		case(seg_state)
			STATE_IDLE: begin
				seg_select[3] <= 1;
				seg_select[2] <= 1;
				seg_select[1] <= 1;
				seg_select[0] <= 1;
				seg_state <= STATE_SEG_3;
				hex_val <= seg3_hex;
				seg_data_dp <= seg3_dp;
				hold <= LED_HOLD_CNT;
				end
	
			STATE_SEG_3: begin
				if(seg3_ena) begin
					seg_select[3] <= 0;
					seg_select[2] <= 1;
					seg_select[1] <= 1;
					seg_select[0] <= 1;
					end
				else begin
					seg_select[3] <= 1;
					seg_select[2] <= 1;
					seg_select[1] <= 1;
					seg_select[0] <= 1;
					end
				if( hold == 0 ) begin
					seg_state <= STATE_SEG_2;
					hex_val <= seg2_hex;
					seg_data_dp <= seg2_dp;
					hold <= LED_HOLD_CNT;
					end
				else begin
					hold <= hold - 1 ;
					end
				end
	
			STATE_SEG_2: begin
				if(seg2_ena && not_blanking ) begin
					seg_select[3] <= 1;
					seg_select[2] <= 0;
					seg_select[1] <= 1;
					seg_select[0] <= 1;
					end
				else begin
					seg_select[3] <= 1;
					seg_select[2] <= 1;
					seg_select[1] <= 1;
					seg_select[0] <= 1;
					end
				if( hold == 0 ) begin
					seg_state <= STATE_SEG_1;
					hex_val <= seg1_hex;
					seg_data_dp <= seg1_dp;
					hold <= LED_HOLD_CNT;
					end
				else begin
					hex_val <= seg2_hex;
					hold <= hold - 1 ;
					end
				end
	
			STATE_SEG_1: begin
				if(seg1_ena && not_blanking ) begin
					seg_select[3] <= 1;
					seg_select[2] <= 1;
					seg_select[1] <= 0;
					seg_select[0] <= 1;
					end
				else begin
					seg_select[3] <= 1;
					seg_select[2] <= 1;
					seg_select[1] <= 1;
					seg_select[0] <= 1;
					end
				if( hold == 0 ) begin
					seg_state <= STATE_SEG_0;
					hex_val <= seg0_hex;
					seg_data_dp <= seg0_dp;
					hold <= LED_HOLD_CNT;
					end
				else begin
					hex_val <= seg1_hex;
					hold <= hold - 1 ;
					end
				end
	
			STATE_SEG_0: begin
				if(seg0_ena && not_blanking ) begin
					seg_select[3] <= 1;
					seg_select[2] <= 1;
					seg_select[1] <= 1;
					seg_select[0] <= 0;
					end
				else begin
					seg_select[3] <= 1;
					seg_select[2] <= 1;
					seg_select[1] <= 1;
					seg_select[0] <= 1;
					end
				if( hold == 0 ) begin
					seg_state <= STATE_DARK;
					hex_val <= seg3_hex;
					hold <= LED_HOLD_CNT;
					dark_period <= 0;
					end
				else begin
					hex_val <= seg0_hex;
					hold <= hold - 1 ;
					end
				end
					
			STATE_DARK: begin
				seg_select[3] <= 1;
				seg_select[2] <= 1;
				seg_select[1] <= 1;
				seg_select[0] <= 1;
				if(dark_period[3:0] == 4'h4) begin // bright || bright == 0) begin
					seg_state <= STATE_SEG_3;
		            dark_period <= 0;
					hex_val <= seg3_hex;
					seg_data_dp <= seg3_dp;
					hold <= LED_HOLD_CNT;
					end
				else begin
					seg_state <= STATE_DARK;
		            dark_period <= dark_period + 1;
					end
				end
	
			default: begin
				seg_select[3] <= 1;
				seg_select[2] <= 1;
				seg_select[1] <= 1;
				seg_select[0] <= 1;
				end
	
			endcase
		end
	end

endmodule

// The Module to convert a 4 bit Hex value to the Segment Map for that hex value
module hexto7segment(
	input      [3:0] hex_in,
	output reg [6:0] seg_out
	);

always @* begin
	case (hex_in)
		4'b0000 :	// Hexadecimal 0
			seg_out = 7'b1111110;
		4'b0001 :	// Hexadecimal 1
			seg_out = 7'b0110000;
		4'b0010 :	// Hexadecimal 2
			seg_out = 7'b1101101;
		4'b0011 :	// Hexadecimal 3
			seg_out = 7'b1111001;
		4'b0100 :	// Hexadecimal 4
			seg_out = 7'b0110011;
		4'b0101 :	// Hexadecimal 5
			seg_out = 7'b1011011;
		4'b0110 :	// Hexadecimal 6
			seg_out = 7'b1011111;
		4'b0111 :	// Hexadecimal 7
			seg_out = 7'b1110000;
		4'b1000 :	// Hexadecimal 8
			seg_out = 7'b1111111;
		4'b1001 :	// Hexadecimal 9
			seg_out = 7'b1111011;
		4'b1010 :	// Hexadecimal A
			seg_out = 7'b1110111;
		4'b1011 :	// Hexadecimal B
			seg_out = 7'b0011111;
		4'b1100 :	// Hexadecimal C
			seg_out = 7'b1001110;
		4'b1101 :	// Hexadecimal D
			seg_out = 7'b0111101;
		4'b1110 :	// Hexadecimal E
			seg_out = 7'b1001111;
		4'b1111 :	// Hexadecimal F
			seg_out = 7'b1000111;
		endcase
	end

endmodule





