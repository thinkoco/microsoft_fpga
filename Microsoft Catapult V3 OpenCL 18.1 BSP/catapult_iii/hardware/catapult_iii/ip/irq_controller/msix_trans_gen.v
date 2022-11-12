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

module msix_trans_gen 
(
    input                                   Clk_i,
    input                                   Rstn_i,
// Master Interface
    output                                  MsixMWrite_o,
    output     [63:0]                       MsixMAddress_o,
    output     [31:0]                       MsixMWriteData_o,
    output     [3:0]                        MsixMByteEnable_o,
    input                                   MsixMWaitRequest_i,

// MSI-X Structure interface
    output    [4:0]                         TableReadAddress_o,    
    input     [31:0]                        TableReadData_i,       
    output    [3:0]                         ClearPba_o,    
    output    [3:0]                         SetPba_o,
    input     [3:0]                         PbaData_i,
 
// IRQ interface
    input     [3:0]                         Irq_i,   
   
/// PCIe Interrupt Interface
    input     [81:0]                        MsiIntfc_i,
    input     [15:0]                        MsixIntfc_i,
    output                                  IntxReq_o
   
);
   
localparam            MSIX_IDLE           = 6'h00;
localparam            MSIX_PIPE           = 6'h03;
localparam            MSIX_READ_TABLE     = 6'h05;  
localparam            MSIX_CHECK_MASK     = 6'h09;  
localparam            MSIX_MSIXWR         = 6'h11;
localparam            MSIX_MSIWR          = 6'h21;

localparam            ARB_IDLE            = 5'h00;
localparam            ARB_GRANT_0         = 5'h03; 
localparam            ARB_GRANT_1         = 5'h05;  
localparam            ARB_GRANT_2         = 5'h09;     
localparam            ARB_GRANT_3         = 5'h11;  

wire                  msix_mode;     
wire                  msi_mode;
wire                  intx_mode;
wire                  master_enable;
wire                  msix_enable;
wire                  msi_enable;       
wire                  vector_masked;
reg    [5:0]          msix_state;
reg    [5:0]          msix_nxt_state;
reg    [4:0]          arb_nxt_state;
reg    [4:0]          arb_state;
wire   [3:0]          msix_grant;
wire                  msix_sm_idle;
wire                  msix_sm_read_table;
wire                  msix_sm_pipe;
wire                  msix_sm_msiwr;
wire                  msix_sm_msixwr;
wire   [63:0]         msix_address;
wire   [31:0]         msix_data;
wire   [63:0]         msi_address;
wire   [15:0]         msi_data;
reg    [1:0]          msi_msg_num;
reg    [4:0]          addr_cntr;
reg    [2:0]          delay_cntr;
reg    [127:0]        msix_entry_reg;
wire                  irq_change;
reg    [3:0]         irq_reg;
wire   [3:0]         irq_rise;


assign msi_enable       = MsiIntfc_i[80];
assign master_enable    = MsiIntfc_i[81];  
assign msix_enable      = MsixIntfc_i[15];
 

assign msix_mode =  msix_enable & ~msi_enable;
assign msi_mode  =  ~msix_enable & msi_enable;
assign intx_mode =  ~msix_enable & ~msi_enable;


/// Generate INtx
assign IntxReq_o = |irq_reg & intx_mode ;


always @(posedge Clk_i or negedge Rstn_i)
 begin
    if(~Rstn_i)
       irq_reg <= 4'h0;
    else
       irq_reg <= Irq_i;   
 end
   
assign irq_change = irq_reg != Irq_i;

always @(posedge Clk_i or negedge Rstn_i)
 begin
    if(~Rstn_i)
       msix_state <= 6'h0;
    else
       msix_state <= msix_nxt_state;   
 end

always @*
begin
    case(msix_state)
       MSIX_IDLE :
          if(|PbaData_i[3:0] & master_enable & msix_mode)
             msix_nxt_state <= MSIX_PIPE;
          else if(msi_mode & irq_change & |Irq_i)
            msix_nxt_state <= MSIX_MSIWR;
          else
             msix_nxt_state <= MSIX_IDLE;
       MSIX_PIPE :
          msix_nxt_state <= MSIX_READ_TABLE;
       MSIX_READ_TABLE :
          if(delay_cntr == 6)  // ram actual read latency + 4 DWs
             msix_nxt_state <= MSIX_CHECK_MASK;
          else
             msix_nxt_state <= MSIX_READ_TABLE;  
                
       MSIX_CHECK_MASK :
          if(vector_masked)
             msix_nxt_state <= MSIX_IDLE;
          else
             msix_nxt_state <= MSIX_MSIXWR;
       MSIX_MSIXWR :
          if(~MsixMWaitRequest_i)
             msix_nxt_state <= MSIX_IDLE;
          else
             msix_nxt_state <= MSIX_MSIXWR;
       MSIX_MSIWR :
          if(~MsixMWaitRequest_i)
             msix_nxt_state <= MSIX_IDLE;
          else
             msix_nxt_state <= MSIX_MSIWR;
       default:
          msix_nxt_state <= MSIX_IDLE;
    endcase
end 

assign   msix_sm_idle          = ~msix_state[0];
assign   msix_sm_read_table    = msix_state[2];
assign   msix_sm_pipe          = msix_state[1];
assign   msix_sm_msiwr         =   msix_state[5];
assign   msix_sm_msixwr        = msix_state[4];

// MSIX Table entry reading
/// IRQ service arbitration (round robin)
      
      
always @(posedge Clk_i or negedge Rstn_i)
begin
  if(~Rstn_i)
     arb_state <= 5'h0;
  else
     arb_state <= arb_nxt_state;   
end

      
always @*
begin
  case(arb_state)
    ARB_IDLE :
       if(PbaData_i[0] & msix_sm_idle)
          arb_nxt_state <= ARB_GRANT_0;
       else if(PbaData_i[1] & msix_sm_idle)
         arb_nxt_state <= ARB_GRANT_1;
       else if(PbaData_i[2] & msix_sm_idle)
         arb_nxt_state <= ARB_GRANT_2;
       else if(PbaData_i[3] & msix_sm_idle)
         arb_nxt_state <= ARB_GRANT_3;
       else
          arb_nxt_state <= ARB_IDLE;
          
    ARB_GRANT_0 :
       if(PbaData_i[1] & msix_sm_idle)
         arb_nxt_state <= ARB_GRANT_1;
       else if(PbaData_i[2] & msix_sm_idle)
         arb_nxt_state <= ARB_GRANT_2;
       else if(PbaData_i[3] & msix_sm_idle)
         arb_nxt_state <= ARB_GRANT_3;
       else if(msix_sm_idle)
          arb_nxt_state <= ARB_IDLE;
       else
          arb_nxt_state <= ARB_GRANT_0;

    ARB_GRANT_1 :
       if(PbaData_i[2] & msix_sm_idle)
         arb_nxt_state <= ARB_GRANT_2;
       else if(PbaData_i[3] & msix_sm_idle)
         arb_nxt_state <= ARB_GRANT_3;
       else if(msix_sm_idle)
          arb_nxt_state <= ARB_IDLE;
       else
          arb_nxt_state <= ARB_GRANT_1;         
          
    ARB_GRANT_2 :
       if(PbaData_i[3] & msix_sm_idle)
         arb_nxt_state <= ARB_GRANT_3;
       else if(PbaData_i[1] & msix_sm_idle)
         arb_nxt_state <= ARB_GRANT_1;
       else if(msix_sm_idle)
          arb_nxt_state <= ARB_IDLE;
       else
          arb_nxt_state <= ARB_GRANT_2;         

    ARB_GRANT_3 :
       if(PbaData_i[1] & msix_sm_idle)
         arb_nxt_state <= ARB_GRANT_1;
       else if(PbaData_i[2] & msix_sm_idle)
         arb_nxt_state <= ARB_GRANT_2;
       else if(msix_sm_idle)
          arb_nxt_state <= ARB_IDLE;
       else
          arb_nxt_state <= ARB_GRANT_3;         
                            
    default:
       arb_nxt_state <= ARB_IDLE;
  endcase
end

assign msix_grant[3:0] = arb_state[4:1];

/// ram address counter
always @ (posedge Clk_i or negedge Rstn_i)
begin
  if(~Rstn_i)
    addr_cntr <= 5'h0;
  else if(msix_sm_pipe)   // load address based on grant
    case (msix_grant)
       4'b0010 :    addr_cntr <= 5'h4;
       4'b0100 :    addr_cntr <= 5'h08;
       4'b1000 :    addr_cntr <= 5'hC;
       default :    addr_cntr <= 5'h0;
    endcase
  else if(msix_sm_read_table)
    addr_cntr <= addr_cntr + 1;
end
   
// ram delay counter   
always @ (posedge Clk_i or negedge Rstn_i)
begin
  if(~Rstn_i)
     delay_cntr <= 3'h0;
  else if(msix_sm_idle)   
     delay_cntr <= 3'h0;
  else if(msix_sm_read_table)
     delay_cntr <= delay_cntr + 1;
end

/// table entry register

generate
  genvar i;
  for(i=0; i< 4; i=i+1)
  begin : TABLE_ENTRY
    always@ (posedge Clk_i or negedge Rstn_i)
    begin
       if(~Rstn_i)
          msix_entry_reg[((i+1)*32)-1:i*32] <= 32'h0;
       else if(delay_cntr == (i + 2))   
          msix_entry_reg[((i+1)*32)-1:i*32] <= TableReadData_i;
    end
  end
endgenerate

assign vector_masked = msix_entry_reg[96];
/// Clearing the PBA bits
assign irq_rise[0]              = ~irq_reg[0] & Irq_i[0];
assign ClearPba_o[0]            = (msix_sm_msixwr & ~MsixMWaitRequest_i & msix_grant[0]);
assign SetPba_o[0]              = irq_rise[0] & msix_mode;

assign irq_rise[1]              = ~irq_reg[1] & Irq_i[1];
assign ClearPba_o[1]            = (msix_sm_msixwr & ~MsixMWaitRequest_i & msix_grant[1]);
assign SetPba_o[1]              = irq_rise[1] & msix_mode;

assign irq_rise[2]              = ~irq_reg[2] & Irq_i[2];
assign ClearPba_o[2]            = (msix_sm_msixwr & ~MsixMWaitRequest_i & msix_grant[2]);
assign SetPba_o[2]              = irq_rise[2] & msix_mode;

assign irq_rise[3]              = ~irq_reg[3] & Irq_i[3];
assign ClearPba_o[3]            = (msix_sm_msixwr & ~MsixMWaitRequest_i & msix_grant[3]);
assign SetPba_o[3]              = irq_rise[3] & msix_mode;


// Write address/data
always @*  // encode lower 2 bits of MSI data
begin
   case(Irq_i)
     4'b0010 : msi_msg_num <= 2'b01;      
     4'b0100 : msi_msg_num <= 2'b10;
     4'b1000 : msi_msg_num <= 2'b11;   
     default :   msi_msg_num <= 2'b00;
   endcase
end
  
assign TableReadAddress_o = addr_cntr[4:0];
  
assign msix_address      = msix_entry_reg[63:0];
assign msi_address      = MsiIntfc_i[63:0];        
assign msix_data         = msix_entry_reg[95:64];
assign msi_data          = MsiIntfc_i[79:64];


assign MsixMWrite_o      = (msix_sm_msixwr | msix_sm_msiwr);
assign MsixMAddress_o    = msix_mode? msix_address : msi_address;
assign MsixMWriteData_o  = msix_mode? msix_data : {16'b0, msi_data};
assign MsixMByteEnable_o = (msix_sm_msixwr | msix_sm_msiwr)? 4'b1111 : 4'b0000;

 
endmodule
