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

module pcie_irq 
(
// Slave Inteface
   input            Clk_i,             // MSI-X structure slave
   input            Rstn_i,          
   input            MsixStructSChipSelect_i,    
   input   [13:0]   MsixStructSAddress_i,       // 16KB space
   input   [3:0]    MsixStructSByteEnable_i,    
   input            MsixStructSRead_i,          
   output  [31:0]   MsixStructSReadData_o,      
   input            MsixStructSWrite_i,         
   input   [31:0]   MsixStructSWriteData_i,     
   output           MsixStructSWaitRequest_o,  
 
// Master Interface
   output           MsixMWrite_o,
   output  [63:0]   MsixMAddress_o,
   output  [31:0]   MsixMWriteData_o,
   output  [3:0]    MsixMByteEnable_o,
   input            MsixMWaitRequest_i,      
 
// IRQ interface               
   input   [31:0]   Irq_i,                           
 
// PCIe HIP interface
   input   [81:0]   MsiIntfc_i,
   input   [15:0]   MsixIntfc_i,
   output           IntxReq_o,
   input            IntxAck_i,
 
// Irq Bridge Interface
   input            IrqRead_i,          
   output  [31:0]   IrqReadData_o,
 
// Irq Mask
  input    [31:0]   MaskWritedata_i,
  input             MaskRead_i,
  input             MaskWrite_i,
  input    [3:0]    MaskByteenable_i,
  output   [31:0]   MaskReaddata_o,
  output            MaskWaitrequest_o
);
      
   wire    [31:0]   table_read_data;                              
   wire    [3:0]    pba_clear;                          
   wire    [3:0]    pba_set;                         
   wire    [3:0]    pba_q;
   wire    [4:0]    table_read_address;
   wire    [31:0]   Irq_masked;


// MSIX structure block
msix_struct msix_structure
(
     .Clk_i(Clk_i),            
     .Rstn_i(Rstn_i),                                        
     .MsixStructSChipSelect_i(MsixStructSChipSelect_i),                       
     .MsixStructSAddress_i(MsixStructSAddress_i),         
     .MsixStructSByteEnable_i(MsixStructSByteEnable_i),                       
     .MsixStructSRead_i(MsixStructSRead_i),                             
     .MsixStructSReadData_o(MsixStructSReadData_o),                                  
     .MsixStructSWrite_i(MsixStructSWrite_i),                            
     .MsixStructSWriteData_i(MsixStructSWriteData_i),                           
     .MsixStructSWaitRequest_o(MsixStructSWaitRequest_o),                         
     .TableReadAddress_i(table_read_address),                            
     .TableReadData_o(table_read_data),                               
     .SetPba_i(pba_set),                                   
     .ClearPba_i(pba_clear),                               
     .PbaData_o(pba_q)   
);


/// IRQ generator via Mwr
msix_trans_gen irq_gen
(
     .Clk_i(Clk_i),
     .Rstn_i(Rstn_i),
     .MsixMWrite_o(MsixMWrite_o),
     .MsixMAddress_o(MsixMAddress_o),
     .MsixMWriteData_o(MsixMWriteData_o),
     .MsixMByteEnable_o(MsixMByteEnable_o),
     .MsixMWaitRequest_i(MsixMWaitRequest_i),
     .TableReadAddress_o(table_read_address),    
     .TableReadData_i(table_read_data),       
     .SetPba_o(pba_set),    
     .ClearPba_o(pba_clear),
     .PbaData_i(pba_q),
     .Irq_i(Irq_masked[3:0]),   
     .MsiIntfc_i(MsiIntfc_i),
     .MsixIntfc_i(MsixIntfc_i),
     .IntxReq_o(IntxReq_o)
);               

/// IRQ Bridge
irq_bridge irq_ports
(
    .clk(Clk_i),
    .read(IrqRead_i),
    .rst_n(Rstn_i),
    .readdata(IrqReadData_o),
    .irq_i(Irq_masked)
);

/// IRQ Mask
irq_ena irq_enable_mask
(
    .clk(Clk_i),
    .resetn(Rstn_i),
    .irq(Irq_i),
    .slave_writedata(MaskWritedata_i),
    .slave_read(MaskRead_i),
    .slave_write(MaskWrite_i),
    .slave_byteenable(MaskByteenable_i),
    .slave_readdata(MaskReaddata_o),
    .slave_waitrequest(MaskWaitrequest_o),
    .irq_out(Irq_masked)
);

endmodule              
