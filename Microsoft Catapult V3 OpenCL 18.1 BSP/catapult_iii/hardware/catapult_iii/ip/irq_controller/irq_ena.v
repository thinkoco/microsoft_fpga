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

module irq_ena
(
   input         clk,
   input         resetn,
   input  [31:0] irq,

   input  [31:0] slave_writedata,
   input  	     slave_read,
   input         slave_write,
   input  [3:0]  slave_byteenable,
   output [31:0] slave_readdata,
   output        slave_waitrequest,

   output [31:0] irq_out
);

reg [31:0] ena_state;

initial   
    ena_state <= 32'hF;
always@(posedge clk or negedge resetn)
  if (!resetn)
    ena_state <= 32'hF;
  else if (slave_write)
    ena_state <= slave_writedata;

assign irq_out = irq & ena_state;

assign slave_waitrequest = 1'b0;
assign slave_readdata = ena_state;
  
endmodule

