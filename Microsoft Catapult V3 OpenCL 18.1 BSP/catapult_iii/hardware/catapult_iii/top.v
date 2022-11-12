// (C) 1992-2019 Intel Corporation.                            
// Intel, the Intel logo, Intel, MegaCore, NIOS II, Quartus and TalkBack words    
// and logos are trademarks of Intel Corporation or its subsidiaries in the U.S.  
// and/or other countries. Other marks and brands may be claimed as the property  
// of others. See Trademarks on intel.com for full list of Intel trademarks or    
// the Trademarks & Brands Names Database (if Intel) or See www.Intel.com/legal (if Altera) 
// Your use of Intel Corporation's design tools, logic functions and other        
// software and tools, and its AMPP partner logic functions, and any output       
// files any of the foregoing (including device programming or simulation         
// files), and any associated documentation or information are expressly subject  
// to the terms and conditions of the Altera Program License Subscription         
// Agreement, Intel MegaCore Function License Agreement, or other applicable      
// license agreement, including, without limitation, that your use is for the     
// sole purpose of programming logic devices manufactured by Intel and sold by    
// Intel or its authorized distributors.  Please refer to the applicable          
// agreement for further details.                                                 


module top(
  //////// CLOCK //////////
  input        config_clk,  			// 100MHz clock
  input        pll_ref_clk,  			// reference clock for the DDR Memory PLL
  input        kernel_pll_refclk,   // 100MHz clock

  //////// PCIe //////////
  input        pcie_refclk, 		// 100MHz clock
  input        perstl0_n,   		// Reset to embedded PCIe
  input  [3:0] hip_serial_rx_in,
  output [3:0] hip_serial_tx_out,

  //////// DDR4A //////////
  input         mem0_oct_rzqin,
  output [1:0]  mem0_ba,
  output [0:0]  mem0_bg,
  output [0:0]  mem0_cke,
  output [0:0]  mem0_ck,
  output [0:0]  mem0_ck_n,
  output [0:0]  mem0_cs_n,
  output [0:0]  mem0_reset_n,
  output [0:0]  mem0_odt,
  output [0:0]  mem0_act_n,
  output [16:0] mem0_a,
  inout  [63:0] mem0_dq,
  inout  [7:0]  mem0_dqs,
  inout  [7:0]  mem0_dqs_n,
  inout  [7:0]  mem0_dbi_n, 
  output 		 mem0_par,
  input         mem0_alert_n,
  
  //////// DDR4B //////////
  input         mem1_oct_rzqin,
  output [1:0]  mem1_ba,
  output [0:0]  mem1_bg,
  output [0:0]  mem1_cke,
  output [0:0]  mem1_ck,
  output [0:0]  mem1_ck_n,
  output [0:0]  mem1_cs_n,
  output [0:0]  mem1_reset_n,
  output [0:0]  mem1_odt,
  output [0:0]  mem1_act_n,
  output [16:0] mem1_a,
  inout  [63:0] mem1_dq,
  inout  [7:0]  mem1_dqs,
  inout  [7:0]  mem1_dqs_n,
  inout  [7:0]  mem1_dbi_n,
  output 		 mem1_par,
  input         mem1_alert_n, 

   //////// LEDs //////////
  output [8:0] leds                // LEDs 0-4 are GREEN
);

//=======================================================
//  REG/WIRE declarations
//=======================================================
wire 				npor;
wire 				ddr4_local_cal_fail;
wire 				ddr4_local_cal_success;

wire         	alt_pr_freeze_freeze;	

wire				board_kernel_clk_clk;
wire				board_kernel_clk2x_clk;
wire         	board_kernel_reset_reset_n;
wire [0:0]   	board_kernel_irq_irq;
wire [31:0]		board_acl_internal_snoop_data;
wire 				board_acl_internal_snoop_valid;
wire				board_acl_internal_snoop_ready;
wire				board_kernel_cra_waitrequest;
wire [63:0]		board_kernel_cra_readdata;
wire         	board_kernel_cra_readdatavalid;
wire [0:0]  	board_kernel_cra_burstcount;
wire [63:0]  	board_kernel_cra_writedata;
wire [29:0]  	board_kernel_cra_address;
wire         	board_kernel_cra_write;
wire         	board_kernel_cra_read;
wire [7:0]   	board_kernel_cra_byteenable;
wire         	board_kernel_cra_debugaccess;

wire         	board_kernel_mem0_waitrequest;
wire [511:0] 	board_kernel_mem0_readdata;
wire         	board_kernel_mem0_readdatavalid;
wire [4:0]   	board_kernel_mem0_burstcount;
wire [511:0] 	board_kernel_mem0_writedata;
wire [30:0]  	board_kernel_mem0_address;
wire         	board_kernel_mem0_write;
wire         	board_kernel_mem0_read;
wire [63:0]  	board_kernel_mem0_byteenable;
wire         	board_kernel_mem0_debugaccess;

wire         	board_kernel_mem1_waitrequest;
wire [511:0] 	board_kernel_mem1_readdata;
wire         	board_kernel_mem1_readdatavalid;
wire [4:0]   	board_kernel_mem1_burstcount;
wire [511:0] 	board_kernel_mem1_writedata;
wire [30:0]  	board_kernel_mem1_address;
wire         	board_kernel_mem1_write;
wire         	board_kernel_mem1_read;
wire [63:0]  	board_kernel_mem1_byteenable;
wire         	board_kernel_mem1_debugaccess;

//=======================================================
// LEDs for debug
//=======================================================
assign leds[4:3]  	= 2'b11;
assign leds[2]    	= ~ddr4_local_cal_fail;
assign leds[1]    	= ~ddr4_local_cal_success;

//=======================================================
wire [31:0] pcie_a10_hip_0_hip_ctrl_test_in;

assign pcie_a10_hip_0_hip_ctrl_test_in = 32'h188;;
// board instantiation
//=======================================================
board board_inst
(
  // Global signals
  .config_clk_clk( config_clk ),
  .kernel_refclk_clk ( kernel_pll_refclk ),
  .reset_n( perstl0_n ),

  // PCIe pins
  .pcie_refclk_clk( pcie_refclk ),
  .pcie_npor_pin_perst( perstl0_n ),
  .pcie_hip_ctrl_test_in(pcie_a10_hip_0_hip_ctrl_test_in),
  .pcie_npor_npor( npor ),
  .pcie_npor_out_reset_n( npor ),
  .pcie_hip_serial_rx_in0( hip_serial_rx_in[0] ),
  .pcie_hip_serial_rx_in1( hip_serial_rx_in[1] ),
  .pcie_hip_serial_rx_in2( hip_serial_rx_in[2] ),
  .pcie_hip_serial_rx_in3( hip_serial_rx_in[3] ),
  .pcie_hip_serial_tx_out0( hip_serial_tx_out[0] ),
  .pcie_hip_serial_tx_out1( hip_serial_tx_out[1] ),
  .pcie_hip_serial_tx_out2( hip_serial_tx_out[2] ),
  .pcie_hip_serial_tx_out3( hip_serial_tx_out[3] ),


  // DDR4A pins
  .ddr4a_pll_ref_clk( pll_ref_clk ),
  .ddr4a_oct_oct_rzqin( mem0_oct_rzqin ),
  .ddr4a_mem_ba( mem0_ba ),
  .ddr4a_mem_bg( mem0_bg ),
  .ddr4a_mem_cke( mem0_cke ),
  .ddr4a_mem_ck( mem0_ck ),
  .ddr4a_mem_ck_n( mem0_ck_n ),
  .ddr4a_mem_cs_n( mem0_cs_n ),
  .ddr4a_mem_reset_n( mem0_reset_n ),
  .ddr4a_mem_odt( mem0_odt ), 
  .ddr4a_mem_act_n( mem0_act_n ), 
  .ddr4a_mem_a( mem0_a ),
  .ddr4a_mem_dq( mem0_dq ),
  .ddr4a_mem_dqs( mem0_dqs ),
  .ddr4a_mem_dqs_n( mem0_dqs_n ),
  .ddr4a_mem_dbi_n( mem0_dbi_n ),
  .ddr4a_mem_par( mem0_par ),
  .ddr4a_mem_alert_n( mem0_alert_n ), 
  
   // DDR4B pins
  .ddr4b_pll_ref_clk( pll_ref_clk ),
  .ddr4b_oct_oct_rzqin( mem1_oct_rzqin ),
  .ddr4b_mem_ba( mem1_ba ),
  .ddr4b_mem_bg( mem1_bg ),
  .ddr4b_mem_cke( mem1_cke ),
  .ddr4b_mem_ck( mem1_ck ),
  .ddr4b_mem_ck_n( mem1_ck_n ),
  .ddr4b_mem_cs_n( mem1_cs_n ),
  .ddr4b_mem_reset_n( mem1_reset_n ),
  .ddr4b_mem_odt( mem1_odt ), 
  .ddr4b_mem_act_n( mem1_act_n ), 
  .ddr4b_mem_a( mem1_a ),
  .ddr4b_mem_dq( mem1_dq ),
  .ddr4b_mem_dqs( mem1_dqs ),
  .ddr4b_mem_dqs_n( mem1_dqs_n ),
  .ddr4b_mem_dbi_n( mem1_dbi_n ),
  .ddr4b_mem_par( mem1_par ),
  .ddr4b_mem_alert_n( mem1_alert_n ),
  
  .ddr4_status_local_cal_fail( ddr4_local_cal_fail ),
  .ddr4_status_local_cal_success( ddr4_local_cal_success ),

  // signals for PR
  .alt_pr_freeze_freeze(alt_pr_freeze_freeze),

  // board ports
  .kernel_clk_clk(board_kernel_clk_clk),
  .kernel_clk2x_clk(board_kernel_clk2x_clk),
  .kernel_reset_reset_n(board_kernel_reset_reset_n),
  .kernel_irq_irq(board_kernel_irq_irq),
  .acl_internal_snoop_data(board_acl_internal_snoop_data),
  .acl_internal_snoop_valid(board_acl_internal_snoop_valid),
  .acl_internal_snoop_ready(board_acl_internal_snoop_ready),
  .kernel_cra_waitrequest(board_kernel_cra_waitrequest),
  .kernel_cra_readdata(board_kernel_cra_readdata),
  .kernel_cra_readdatavalid(board_kernel_cra_readdatavalid),
  .kernel_cra_burstcount(board_kernel_cra_burstcount),
  .kernel_cra_writedata(board_kernel_cra_writedata),
  .kernel_cra_address(board_kernel_cra_address),
  .kernel_cra_write(board_kernel_cra_write),
  .kernel_cra_read(board_kernel_cra_read),
  .kernel_cra_byteenable(board_kernel_cra_byteenable),
  .kernel_cra_debugaccess(board_kernel_cra_debugaccess),
  
  .kernel_mem0_waitrequest(board_kernel_mem0_waitrequest),
  .kernel_mem0_readdata(board_kernel_mem0_readdata),
  .kernel_mem0_readdatavalid(board_kernel_mem0_readdatavalid),
  .kernel_mem0_burstcount(board_kernel_mem0_burstcount),
  .kernel_mem0_writedata(board_kernel_mem0_writedata),
  .kernel_mem0_address(board_kernel_mem0_address),
  .kernel_mem0_write(board_kernel_mem0_write),
  .kernel_mem0_read(board_kernel_mem0_read),
  .kernel_mem0_byteenable(board_kernel_mem0_byteenable),
  .kernel_mem0_debugaccess(board_kernel_mem0_debugaccess),
  
  .kernel_mem1_waitrequest(board_kernel_mem1_waitrequest),
  .kernel_mem1_readdata(board_kernel_mem1_readdata),
  .kernel_mem1_readdatavalid(board_kernel_mem1_readdatavalid),
  .kernel_mem1_burstcount(board_kernel_mem1_burstcount),
  .kernel_mem1_writedata(board_kernel_mem1_writedata),
  .kernel_mem1_address(board_kernel_mem1_address),
  .kernel_mem1_write(board_kernel_mem1_write),
  .kernel_mem1_read(board_kernel_mem1_read),
  .kernel_mem1_byteenable(board_kernel_mem1_byteenable),
  .kernel_mem1_debugaccess(board_kernel_mem1_debugaccess)
);

//=======================================================
// freeze wrapper instantiation
//=======================================================
freeze_wrapper freeze_wrapper_inst
(
  .freeze(alt_pr_freeze_freeze),  
  
  // board ports
  .board_kernel_clk_clk(board_kernel_clk_clk),
  .board_kernel_clk2x_clk(board_kernel_clk2x_clk),
  .board_kernel_reset_reset_n(board_kernel_reset_reset_n),
  .board_kernel_irq_irq(board_kernel_irq_irq),
  .board_acl_internal_snoop_data(board_acl_internal_snoop_data),
  .board_acl_internal_snoop_valid(board_acl_internal_snoop_valid),
  .board_acl_internal_snoop_ready(board_acl_internal_snoop_ready),
  .board_kernel_cra_waitrequest(board_kernel_cra_waitrequest),
  .board_kernel_cra_readdata(board_kernel_cra_readdata),
  .board_kernel_cra_readdatavalid(board_kernel_cra_readdatavalid),
  .board_kernel_cra_burstcount(board_kernel_cra_burstcount),
  .board_kernel_cra_writedata(board_kernel_cra_writedata),
  .board_kernel_cra_address(board_kernel_cra_address),
  .board_kernel_cra_write(board_kernel_cra_write),
  .board_kernel_cra_read(board_kernel_cra_read),
  .board_kernel_cra_byteenable(board_kernel_cra_byteenable),
  .board_kernel_cra_debugaccess(board_kernel_cra_debugaccess),
  
  .board_kernel_mem0_waitrequest(board_kernel_mem0_waitrequest),
  .board_kernel_mem0_readdata(board_kernel_mem0_readdata),
  .board_kernel_mem0_readdatavalid(board_kernel_mem0_readdatavalid),
  .board_kernel_mem0_burstcount(board_kernel_mem0_burstcount),
  .board_kernel_mem0_writedata(board_kernel_mem0_writedata),
  .board_kernel_mem0_address(board_kernel_mem0_address),
  .board_kernel_mem0_write(board_kernel_mem0_write),
  .board_kernel_mem0_read(board_kernel_mem0_read),
  .board_kernel_mem0_byteenable(board_kernel_mem0_byteenable),
  .board_kernel_mem0_debugaccess(board_kernel_mem0_debugaccess),
  
  .board_kernel_mem1_waitrequest(board_kernel_mem1_waitrequest),
  .board_kernel_mem1_readdata(board_kernel_mem1_readdata),
  .board_kernel_mem1_readdatavalid(board_kernel_mem1_readdatavalid),
  .board_kernel_mem1_burstcount(board_kernel_mem1_burstcount),
  .board_kernel_mem1_writedata(board_kernel_mem1_writedata),
  .board_kernel_mem1_address(board_kernel_mem1_address),
  .board_kernel_mem1_write(board_kernel_mem1_write),
  .board_kernel_mem1_read(board_kernel_mem1_read),
  .board_kernel_mem1_byteenable(board_kernel_mem1_byteenable),
  .board_kernel_mem1_debugaccess(board_kernel_mem1_debugaccess)  
);

endmodule
