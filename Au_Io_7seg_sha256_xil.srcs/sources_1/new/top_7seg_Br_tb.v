`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/13/2020 02:54:34 PM
// Design Name: 
// Module Name: top_7seg_Br_tb
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


module top_7seg_Br_tb(
    );
    // from the system
    reg clk;
    reg  rst;   
	wire rst_n;
    wire usb_rx;           // USB->Serial input
    wire usb_tx;          // USB->Serial output
    wire [7:0] led;       // 8 user controllable LEDs   
  
    // Output
	wire[7:0] io_seg;
	wire [3:0] io_sel;

// internal segment data. The Display Controller drives this
wire [7:0] io_seg_int;

// digit values to display    
wire [3:0] val3; 
wire [3:0] val2;   
wire [3:0] val1;   
wire [3:0] val0;    

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
  parameter STATE_WR_BLOCK_NEXT    = 2;
  parameter STATE_CTRL_INIT        = 3;
  parameter STATE_CTRL_INIT_NEXT   = 4;
  parameter STATE_WAIT_READY       = 5;
  parameter STATE_WAIT_READY_NEXT  = 6;
  parameter STATE_READ_DIGEST      = 7;
  parameter STATE_READ_DIGEST_NEXT = 8;
  parameter STATE_DISP_SHA         = 9;
  

  //----------------------------------------------------------------
  // Register and Wire declarations.
  //----------------------------------------------------------------
  reg [31 : 0] cycle_ctr;
  reg [31 : 0] error_ctr;
  reg [31 : 0] tc_ctr;

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
assign rst_n = ~rst;


// load the 7seg digit values from the free running counter
assign val3 = digest_data[255 : 224];
assign val2 = digest_data[223 : 192];
assign val1 = digest_data[191 : 160];
assign val0 = digest_data[159 : 128];

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
	
	.seg0_hex(state[3:0]), // val0),
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
		
		cycle_ctr <= 32'h0;
		error_ctr <= 32'h0;
		tc_ctr <= 32'h0;
		
		tb_cs <= 0;
		tb_we <= 0;
		tb_address <= 26'h0; // MOY 6'h0;
		tb_write_data <= 32'h0;
	
		block <= 512'h61626380000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000018;
	
		end
	else begin
	
		case(state)
			STATE_IDLE: begin
				state <= STATE_WR_BLOCK_NEXT;
				tb_address <= ADDR_BLOCK0;
				tb_write_data <= block[511 : 480];
      			tb_cs <= 1;
     			tb_we <= 1;
				blk_cnt <= 0;
				digest_data <= 0 ;
				end
			STATE_WR_BLOCK: begin
				state <= STATE_WR_BLOCK_NEXT;
      			tb_cs <= 1;
     			tb_we <= 1;
				end
			STATE_WR_BLOCK_NEXT: begin
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
					state <= STATE_READ_DIGEST_NEXT;					
					tb_address <= ADDR_DIGEST0;
					blk_cnt <= 0;
					digest_data <= 0;
					end
				end
			STATE_WAIT_READY_NEXT: begin
      			tb_cs <= 1;
     			tb_we <= 0;
				state <= STATE_WAIT_READY;
				end
			STATE_READ_DIGEST: begin
				state <= STATE_READ_DIGEST_NEXT;
      			tb_cs <= 1;
     			tb_we <= 0;
				end
			STATE_READ_DIGEST_NEXT: begin
				if( blk_cnt == 8 ) begin
					state <= STATE_DISP_SHA;
      				tb_cs <= 0;
                    $display("Done 0x%x",  digest_data[255 : 252]);
                    $display("     0x%x",  digest_data[251 : 248]); 
                    $display("     0x%x",  digest_data[247 : 244]); 
                    $display("     0x%x",  digest_data[243 : 240]);
					end
				else begin					
					block <= block << 32 ;
					tb_address <= tb_address + 1;
					digest_data[31 : 0] <= tb_read_data;
					digest_data[255:32] <= digest_data[223:0];
					blk_cnt <= blk_cnt + 1;
					end
				end
			STATE_DISP_SHA: begin
//					state <= STATE_IDLE;
				end
			
			default: begin
				state <= STATE_IDLE;
			end
		endcase
		end
	end
	 

    initial begin : main

      $display("\n");
      $display("-----------------------------------------------------");
      $display("--                                                 --");
      $display("-- Testbench for Michael                           --");
      $display("--                                                 --");
      $display("-----------------------------------------------------");
      $display("\n\n");
      
		// set Reset for a few clocks
        rst = 1;
        clk = 0;
        #50;
        clk = 1;
        #50;
        clk = 0;
        #50;
        clk = 1;
        #50;
        clk = 0;
        #50;
        clk = 1;
        #50;
        clk = 0;
        
        // Reset done now
        rst = 0;
        #50;
        clk = 1;
        #50;
        clk = 0;
        #50;

		// clock away
        repeat (1000) begin
            clk =  ! clk;
            #50;
        end

        #200;
        clk =  ! clk;
        

      $display("\n");
      $display("-----------------------------------------------------");
      $display("--                                                 --");
      $display("-- Testbench Done                                  --");
      $display("--                                                 --");
      $display("-----------------------------------------------------");
        
        end
            
endmodule
