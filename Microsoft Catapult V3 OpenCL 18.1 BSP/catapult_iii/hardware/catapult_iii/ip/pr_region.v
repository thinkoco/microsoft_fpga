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

module pr_region (
  input  wire [31:0]  cc_snoop_data,
  input  wire         cc_snoop_valid,
  output wire         cc_snoop_ready,
  input  wire         cc_snoop_clk_clk,
  input  wire         clock_reset_clk,
  input  wire         clock_reset2x_clk,
  input  wire         clock_reset_reset_reset_n,
  output wire         kernel_cra_waitrequest,
  output wire [63:0]  kernel_cra_readdata,
  output wire         kernel_cra_readdatavalid,
  input  wire [0:0]   kernel_cra_burstcount,
  input  wire [63:0]  kernel_cra_writedata,
  input  wire [29:0]  kernel_cra_address,
  input  wire         kernel_cra_write,
  input  wire         kernel_cra_read,
  input  wire [7:0]   kernel_cra_byteenable,
  input  wire         kernel_cra_debugaccess,
  output wire         kernel_irq_irq,
  
  input  wire         kernel_mem0_waitrequest,
  input  wire [511:0] kernel_mem0_readdata,
  input  wire         kernel_mem0_readdatavalid,
  output wire [4:0]   kernel_mem0_burstcount,
  output wire [511:0] kernel_mem0_writedata,
  output wire [30:0]  kernel_mem0_address,
  output wire         kernel_mem0_write,
  output wire         kernel_mem0_read,
  output wire [63:0]  kernel_mem0_byteenable,
  
  input  wire         kernel_mem1_waitrequest,
  input  wire [511:0] kernel_mem1_readdata,
  input  wire         kernel_mem1_readdatavalid,
  output wire [4:0]   kernel_mem1_burstcount,
  output wire [511:0] kernel_mem1_writedata,
  output wire [30:0]  kernel_mem1_address,
  output wire         kernel_mem1_write,
  output wire         kernel_mem1_read,
  output wire [63:0]  kernel_mem1_byteenable   
);

  wire          pipelined_kernel_mem0_s0_waitrequest;
  wire  [511:0] pipelined_kernel_mem0_s0_readdata;
  wire          pipelined_kernel_mem0_s0_readdatavalid;
  wire    [4:0] pipelined_kernel_mem0_s0_burstcount;
  wire  [511:0] pipelined_kernel_mem0_s0_writedata;
  wire   [30:0] pipelined_kernel_mem0_s0_address;
  wire          pipelined_kernel_mem0_s0_write;
  wire          pipelined_kernel_mem0_s0_read;
  wire   [63:0] pipelined_kernel_mem0_s0_byteenable;
  
  wire          pipelined_kernel_mem1_s0_waitrequest;
  wire  [511:0] pipelined_kernel_mem1_s0_readdata;
  wire          pipelined_kernel_mem1_s0_readdatavalid;
  wire    [4:0] pipelined_kernel_mem1_s0_burstcount;
  wire  [511:0] pipelined_kernel_mem1_s0_writedata;
  wire   [30:0] pipelined_kernel_mem1_s0_address;
  wire          pipelined_kernel_mem1_s0_write;
  wire          pipelined_kernel_mem1_s0_read;
  wire   [63:0] pipelined_kernel_mem1_s0_byteenable;  

//=======================================================
//  kernel_mem pipeline stage instantiation
//=======================================================
kernel_mem_mm_bridge_0 kernel_mem0_inst(
  .clk(clock_reset_clk), 
  .m0_waitrequest(kernel_mem0_waitrequest),
  .m0_readdata(kernel_mem0_readdata),
  .m0_readdatavalid(kernel_mem0_readdatavalid),
  .m0_burstcount(kernel_mem0_burstcount),
  .m0_writedata(kernel_mem0_writedata),
  .m0_address(kernel_mem0_address),
  .m0_write(kernel_mem0_write),
  .m0_read(kernel_mem0_read),
  .m0_byteenable(kernel_mem0_byteenable),
  .reset(~clock_reset_reset_reset_n),
  .s0_waitrequest(pipelined_kernel_mem0_s0_waitrequest),
  .s0_readdata(pipelined_kernel_mem0_s0_readdata),
  .s0_readdatavalid(pipelined_kernel_mem0_s0_readdatavalid),
  .s0_burstcount(pipelined_kernel_mem0_s0_burstcount),
  .s0_writedata(pipelined_kernel_mem0_s0_writedata),
  .s0_address(pipelined_kernel_mem0_s0_address),
  .s0_write(pipelined_kernel_mem0_s0_write),
  .s0_read(pipelined_kernel_mem0_s0_read),
  .s0_byteenable(pipelined_kernel_mem0_s0_byteenable)
);

kernel_mem_mm_bridge_0 kernel_mem1_inst(
  .clk(clock_reset_clk), 
  .m0_waitrequest(kernel_mem1_waitrequest),
  .m0_readdata(kernel_mem1_readdata),
  .m0_readdatavalid(kernel_mem1_readdatavalid),
  .m0_burstcount(kernel_mem1_burstcount),
  .m0_writedata(kernel_mem1_writedata),
  .m0_address(kernel_mem1_address),
  .m0_write(kernel_mem1_write),
  .m0_read(kernel_mem1_read),
  .m0_byteenable(kernel_mem1_byteenable),
  .reset(~clock_reset_reset_reset_n),
  .s0_waitrequest(pipelined_kernel_mem1_s0_waitrequest),
  .s0_readdata(pipelined_kernel_mem1_s0_readdata),
  .s0_readdatavalid(pipelined_kernel_mem1_s0_readdatavalid),
  .s0_burstcount(pipelined_kernel_mem1_s0_burstcount),
  .s0_writedata(pipelined_kernel_mem1_s0_writedata),
  .s0_address(pipelined_kernel_mem1_s0_address),
  .s0_write(pipelined_kernel_mem1_s0_write),
  .s0_read(pipelined_kernel_mem1_s0_read),
  .s0_byteenable(pipelined_kernel_mem1_s0_byteenable)
);


//=======================================================
//  kernel_system instantiation
//=======================================================
kernel_system kernel_system_inst
(
  // kernel_system ports
  .clock_reset_clk(clock_reset_clk),
  .clock_reset2x_clk(clock_reset2x_clk),
  .clock_reset_reset_reset_n(clock_reset_reset_reset_n),
  .kernel_irq_irq(kernel_irq_irq),
  .cc_snoop_clk_clk(cc_snoop_clk_clk),
  .cc_snoop_data(cc_snoop_data),
  .cc_snoop_valid(cc_snoop_valid),
  .cc_snoop_ready(cc_snoop_ready),
  .kernel_cra_waitrequest(kernel_cra_waitrequest),
  .kernel_cra_readdata(kernel_cra_readdata),
  .kernel_cra_readdatavalid(kernel_cra_readdatavalid),
  .kernel_cra_burstcount(kernel_cra_burstcount),
  .kernel_cra_writedata(kernel_cra_writedata),
  .kernel_cra_address(kernel_cra_address),
  .kernel_cra_write(kernel_cra_write),
  .kernel_cra_read(kernel_cra_read),
  .kernel_cra_byteenable(kernel_cra_byteenable),
  .kernel_cra_debugaccess(kernel_cra_debugaccess),
  
  .kernel_mem0_address(pipelined_kernel_mem0_s0_address),
  .kernel_mem0_read(pipelined_kernel_mem0_s0_read),
  .kernel_mem0_write(pipelined_kernel_mem0_s0_write),
  .kernel_mem0_burstcount(pipelined_kernel_mem0_s0_burstcount),
  .kernel_mem0_writedata(pipelined_kernel_mem0_s0_writedata),
  .kernel_mem0_byteenable(pipelined_kernel_mem0_s0_byteenable),
  .kernel_mem0_readdata(pipelined_kernel_mem0_s0_readdata),
  .kernel_mem0_waitrequest(pipelined_kernel_mem0_s0_waitrequest),
  .kernel_mem0_readdatavalid(pipelined_kernel_mem0_s0_readdatavalid),
  
  .kernel_mem1_address(pipelined_kernel_mem1_s0_address),
  .kernel_mem1_read(pipelined_kernel_mem1_s0_read),
  .kernel_mem1_write(pipelined_kernel_mem1_s0_write),
  .kernel_mem1_burstcount(pipelined_kernel_mem1_s0_burstcount),
  .kernel_mem1_writedata(pipelined_kernel_mem1_s0_writedata),
  .kernel_mem1_byteenable(pipelined_kernel_mem1_s0_byteenable),
  .kernel_mem1_readdata(pipelined_kernel_mem1_s0_readdata),
  .kernel_mem1_waitrequest(pipelined_kernel_mem1_s0_waitrequest),
  .kernel_mem1_readdatavalid(pipelined_kernel_mem1_s0_readdatavalid)  
);

endmodule
