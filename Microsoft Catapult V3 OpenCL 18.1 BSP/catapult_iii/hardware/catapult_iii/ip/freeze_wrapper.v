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

module freeze_wrapper(

  input           freeze,

  //////// board ports //////////
  input           board_kernel_clk_clk,
  input           board_kernel_clk2x_clk,
  input           board_kernel_reset_reset_n,
  output [0:0]    board_kernel_irq_irq,
  input [31:0]    board_acl_internal_snoop_data,
  input           board_acl_internal_snoop_valid,
  output          board_acl_internal_snoop_ready,
  output          board_kernel_cra_waitrequest,
  output [63:0]   board_kernel_cra_readdata,
  output          board_kernel_cra_readdatavalid,
  input [0:0]     board_kernel_cra_burstcount,
  input [63:0]    board_kernel_cra_writedata,
  input [29:0]    board_kernel_cra_address,
  input           board_kernel_cra_write,
  input           board_kernel_cra_read,
  input [7:0]     board_kernel_cra_byteenable,
  input           board_kernel_cra_debugaccess,
  
  input           board_kernel_mem0_waitrequest,
  input [511:0]   board_kernel_mem0_readdata,
  input           board_kernel_mem0_readdatavalid,
  output [4:0]    board_kernel_mem0_burstcount,
  output [511:0]  board_kernel_mem0_writedata,
  output [30:0]   board_kernel_mem0_address,
  output          board_kernel_mem0_write,
  output          board_kernel_mem0_read,
  output [63:0]   board_kernel_mem0_byteenable,
  output          board_kernel_mem0_debugaccess,
  
  input           board_kernel_mem1_waitrequest,
  input [511:0]   board_kernel_mem1_readdata,
  input           board_kernel_mem1_readdatavalid,
  output [4:0]    board_kernel_mem1_burstcount,
  output [511:0]  board_kernel_mem1_writedata,
  output [30:0]   board_kernel_mem1_address,
  output          board_kernel_mem1_write,
  output          board_kernel_mem1_read,
  output [63:0]   board_kernel_mem1_byteenable,
  output          board_kernel_mem1_debugaccess    
);

reg  [7:0]        kernel_reset_count;                          // counter to release RESETn and FREEZE in the proper sequence
reg  [2:0]        freeze_kernel_clk;                           // metastability hardening to being FREEZE signal onto the kernel clock
reg               kernel_system_clock_reset_reset_reset_n;     // RESETn signal must be held de-asserted during PR, then assert when PR is done
reg               pr_freeze_reg;                               // internal copy of the FREEZE signal, held asserted longer than the input FREEZE signal to allow PR region to be reset

// control signals out of the Kernel that must be held inactive during PR (controlled by the FREEZE signal)
wire              kernel_system_kernel_irq_irq;
wire              kernel_system_cc_snoop_ready;
wire              kernel_system_kernel_cra_waitrequest;
wire              kernel_system_kernel_cra_readdatavalid;

wire              kernel_system_kernel_mem0_read;
wire              kernel_system_kernel_mem0_write;

wire              kernel_system_kernel_mem1_read;
wire              kernel_system_kernel_mem1_write;

// capture the freeze signal onto the kernel clock domain
always @( posedge board_kernel_clk_clk or negedge board_kernel_reset_reset_n)  
begin
   if ( board_kernel_reset_reset_n == 1'b0 ) begin
      freeze_kernel_clk[0] <= 1'b0;
      freeze_kernel_clk[1] <= 1'b0;
      freeze_kernel_clk[2] <= 1'b0;
   end else begin
      freeze_kernel_clk[0] <= freeze;
      freeze_kernel_clk[1] <= freeze_kernel_clk[0];
      freeze_kernel_clk[2] <= freeze_kernel_clk[1];
   end
end

// circuitry to implement freeze/reset requirements on the GLOBAL kernel RESETn signal
// During PR (when freeze input is asserted), hold RESETn HIGH
// After PR is done, continue to hold control outputs from this block in the frozen (inactive) state while RESETn is driven low
// Finally, release the internal freeze signal and then release the kernel RESETn signal
always @( posedge board_kernel_clk_clk or negedge board_kernel_reset_reset_n )
begin
   if ( board_kernel_reset_reset_n == 1'b0 ) begin
      kernel_reset_count <= 8'h00;
      kernel_system_clock_reset_reset_reset_n <= 1'b0;
      pr_freeze_reg       <= 1'b0;
   end else begin

      if ( freeze_kernel_clk[2] == 1'b1 ) begin
         kernel_reset_count <= 8'h00;
      end else if (kernel_reset_count != 8'hFF) begin
         kernel_reset_count <= kernel_reset_count + 1'b1;
      end else begin
         kernel_reset_count <= kernel_reset_count;
      end
      
      if ( (freeze_kernel_clk[2] == 1'b1) || (kernel_reset_count == 8'hFF) ) begin
         kernel_system_clock_reset_reset_reset_n <= 1'b1;
      end else if ( kernel_reset_count >= 8'h40 ) begin
         kernel_system_clock_reset_reset_reset_n <= 1'b0;
      end
      
      if ( freeze_kernel_clk[2] == 1'b1 || (!kernel_reset_count[7] && pr_freeze_reg) ) begin
          pr_freeze_reg       <= 1'b1;
      end else begin
          pr_freeze_reg       <= 1'b0;
      end

   end
end
         
      

// hold all control outputs from the Kernel region inactive during PR
// Signals in the PR region will toggle at random during PR, we must protect external circuitry from being corrupted
assign board_kernel_irq_irq            = pr_freeze_reg ?   1'b0:kernel_system_kernel_irq_irq;
assign board_acl_internal_snoop_ready  = pr_freeze_reg ?   1'b0:kernel_system_cc_snoop_ready;
assign board_kernel_cra_waitrequest    = pr_freeze_reg ?   1'b1:kernel_system_kernel_cra_waitrequest;
assign board_kernel_cra_readdatavalid  = pr_freeze_reg ?   1'b0:kernel_system_kernel_cra_readdatavalid;

assign board_kernel_mem0_read          = pr_freeze_reg ?   1'b0:kernel_system_kernel_mem0_read;
assign board_kernel_mem0_write         = pr_freeze_reg ?   1'b0:kernel_system_kernel_mem0_write;
assign board_kernel_mem0_debugaccess   = 1'b0;     // not used

assign board_kernel_mem1_read          = pr_freeze_reg ?   1'b0:kernel_system_kernel_mem1_read;
assign board_kernel_mem1_write         = pr_freeze_reg ?   1'b0:kernel_system_kernel_mem1_write;
assign board_kernel_mem1_debugaccess   = 1'b0;     // not used

//=======================================================
//  pr_region instantiation
//=======================================================
pr_region pr_region_inst
(
  .clock_reset_clk(board_kernel_clk_clk),
  .clock_reset2x_clk(board_kernel_clk2x_clk),
  .clock_reset_reset_reset_n(kernel_system_clock_reset_reset_reset_n),
  .kernel_irq_irq(kernel_system_kernel_irq_irq),
  .cc_snoop_clk_clk(board_kernel_clk_clk),
  .cc_snoop_data(board_acl_internal_snoop_data),
  .cc_snoop_valid(board_acl_internal_snoop_valid),
  .cc_snoop_ready(kernel_system_cc_snoop_ready),
  .kernel_cra_waitrequest(kernel_system_kernel_cra_waitrequest),
  .kernel_cra_readdata(board_kernel_cra_readdata),
  .kernel_cra_readdatavalid(kernel_system_kernel_cra_readdatavalid),
  .kernel_cra_burstcount(board_kernel_cra_burstcount),
  .kernel_cra_writedata(board_kernel_cra_writedata),
  .kernel_cra_address(board_kernel_cra_address),
  .kernel_cra_write(board_kernel_cra_write),
  .kernel_cra_read(board_kernel_cra_read),
  .kernel_cra_byteenable(board_kernel_cra_byteenable),
  .kernel_cra_debugaccess(board_kernel_cra_debugaccess),
  
  .kernel_mem0_address(board_kernel_mem0_address),
  .kernel_mem0_read(kernel_system_kernel_mem0_read),
  .kernel_mem0_write(kernel_system_kernel_mem0_write),
  .kernel_mem0_burstcount(board_kernel_mem0_burstcount),
  .kernel_mem0_writedata(board_kernel_mem0_writedata),
  .kernel_mem0_byteenable(board_kernel_mem0_byteenable),
  .kernel_mem0_readdata(board_kernel_mem0_readdata),
  .kernel_mem0_waitrequest(board_kernel_mem0_waitrequest),
  .kernel_mem0_readdatavalid(board_kernel_mem0_readdatavalid),
  
  .kernel_mem1_address(board_kernel_mem1_address),
  .kernel_mem1_read(kernel_system_kernel_mem1_read),
  .kernel_mem1_write(kernel_system_kernel_mem1_write),
  .kernel_mem1_burstcount(board_kernel_mem1_burstcount),
  .kernel_mem1_writedata(board_kernel_mem1_writedata),
  .kernel_mem1_byteenable(board_kernel_mem1_byteenable),
  .kernel_mem1_readdata(board_kernel_mem1_readdata),
  .kernel_mem1_waitrequest(board_kernel_mem1_waitrequest),
  .kernel_mem1_readdatavalid(board_kernel_mem1_readdatavalid)  
);

endmodule
