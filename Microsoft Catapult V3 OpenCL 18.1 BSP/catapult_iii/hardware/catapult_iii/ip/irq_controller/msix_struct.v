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

module msix_struct
(
    input             Clk_i,             // MSI-X structure slave
    input             Rstn_i,          
    input             MsixStructSChipSelect_i,    
    input   [13:0]    MsixStructSAddress_i,       // 16KB space
    input   [3:0]     MsixStructSByteEnable_i,    
    input             MsixStructSRead_i,          
    output  [31:0]    MsixStructSReadData_o,      
    input             MsixStructSWrite_i,         
    input   [31:0]    MsixStructSWriteData_i,     
    output            MsixStructSWaitRequest_o,  
    
    // Table internal interface
    input   [4:0]     TableReadAddress_i,
    output  [31:0]    TableReadData_o,
    input   [3:0]     SetPba_i,
    input   [3:0]     ClearPba_i,
    output  [3:0]     PbaData_o
);
    
localparam MSIX_STRUCT_IDLE      = 6'h00;
localparam MSIX_STRUCT_PIPE      = 6'h03;
localparam MSIX_STRUCT_READ      = 6'h05;
localparam MSIX_STRUCT_READ_WAIT = 6'h09;
localparam MSIX_STRUCT_READ_ACK  = 6'h11;
localparam MSIX_STRUCT_WRITE_ACK = 6'h21;
    

wire   [4:0]          avalon_ram_addr;         
reg    [13:0]         msix_address_reg;
reg    [5:0]          msix_struct_state;
reg    [5:0]          msix_struct_nxtstate;
wire                  msix_read_data_valid;
wire                  msix_read;
wire                  msix_read_ack;
wire                  msix_write_ack;
wire                  msix_ack;
wire                  msix_table_hit;
wire                  msix_pba_hit;
reg                   msix_table_read_reg2;
reg                   msix_table_read_reg1;
wire   [31:0]         msix_read_data;
wire   [31:0]         avalon_table_q;
reg    [3:0]          pba_reg;
wire                  ram_write;
wire                  msix_table_rd_valid;
wire                  msix_pba_rd_valid;


/// latching the Avalon-MM address
always @(posedge Clk_i or negedge Rstn_i)
begin
   if(~Rstn_i)
     msix_address_reg <= 14'h0;
   else if((MsixStructSRead_i | MsixStructSWrite_i) & MsixStructSChipSelect_i)
     msix_address_reg <= MsixStructSAddress_i;
end
 
assign avalon_ram_addr = msix_address_reg[6:2]; 
 
    
// Main state machine
    
always @(posedge Clk_i or negedge Rstn_i)
begin
  if(~Rstn_i)
     msix_struct_state <= MSIX_STRUCT_IDLE;
  else
     msix_struct_state <= msix_struct_nxtstate;
end
  
always @*
begin
   case (msix_struct_state)
      MSIX_STRUCT_IDLE :
        if(MsixStructSChipSelect_i & (MsixStructSRead_i | MsixStructSWrite_i))
          msix_struct_nxtstate <= MSIX_STRUCT_PIPE;
        else
          msix_struct_nxtstate <= MSIX_STRUCT_IDLE;
          
      MSIX_STRUCT_PIPE :
         if(MsixStructSRead_i)
            msix_struct_nxtstate <= MSIX_STRUCT_READ;
         else if(MsixStructSWrite_i)
            msix_struct_nxtstate <= MSIX_STRUCT_WRITE_ACK;
         else
            msix_struct_nxtstate <= MSIX_STRUCT_IDLE;
            
      MSIX_STRUCT_READ, MSIX_STRUCT_READ_WAIT :
         if(msix_read_data_valid)
            msix_struct_nxtstate <= MSIX_STRUCT_READ_ACK;
         else 
            msix_struct_nxtstate <= MSIX_STRUCT_READ_WAIT; 
      
      MSIX_STRUCT_READ_ACK, MSIX_STRUCT_WRITE_ACK :
          msix_struct_nxtstate <= MSIX_STRUCT_IDLE;
          
      default:
          msix_struct_nxtstate <= MSIX_STRUCT_IDLE;
   endcase
end
  
 // state machine output assignments
  
assign msix_read = msix_struct_state[2];
assign msix_read_ack = msix_struct_state[4];
assign msix_write_ack = msix_struct_state[5];
assign msix_ack = msix_read_ack | msix_write_ack;
  

/// decode for MSIX table or PBA space

assign msix_table_hit = ~msix_address_reg[13]; // MSIX table entries at the first 4KB
assign msix_pba_hit   =  msix_address_reg[13]; // MSIX PBA starts at the second 4KB

assign msix_table_rd_valid = msix_table_read_reg2;  // implemented with on-chip ram, a few clocks delay before data is valid
assign msix_pba_rd_valid   = 1'b1;                  // implemneted with register, always valid

assign msix_read_data_valid = msix_table_hit? msix_table_rd_valid : msix_pba_rd_valid;
assign msix_read_data       = msix_table_hit? avalon_table_q : pba_reg;


// delay chain for RAM read valide
always @(posedge Clk_i or negedge Rstn_i)
begin
   if(~Rstn_i)
     begin
      msix_table_read_reg1 <= 1'b0;
      msix_table_read_reg2 <= 1'b0;
     end
   else
     begin
       msix_table_read_reg1 <= msix_read;
       msix_table_read_reg2 <= msix_table_read_reg1;
     end
end

// MSI-X structure Avalon-MM Slave interface output assignments
assign MsixStructSWaitRequest_o = ~msix_ack;
assign MsixStructSReadData_o    = (msix_ack)? msix_read_data : 32'h0; 

assign ram_write = msix_write_ack & msix_table_hit;

/// MSIX table RAM


altsyncram   altsyncram_component (
        .clock0 (Clk_i),
        .wren_a (ram_write),
        .address_b (TableReadAddress_i),
        .data_b (32'h0),
        .wren_b (1'b0),
        .address_a (avalon_ram_addr),
        .data_a (MsixStructSWriteData_i),
        .q_a (avalon_table_q),
        .q_b (TableReadData_o),
        .aclr0 (1'b0),
        .aclr1 (1'b0),
        .addressstall_a (1'b0),
        .addressstall_b (1'b0),
        .byteena_a (1'b1),
        .byteena_b (1'b1),
        .clock1 (1'b1),
        .clocken0 (1'b1),
        .clocken1 (1'b1),
        .clocken2 (1'b1),
        .clocken3 (1'b1),
        .eccstatus (),
        .rden_a (1'b1),
        .rden_b (1'b1));
   defparam
      altsyncram_component.address_reg_b = "CLOCK0",
      altsyncram_component.clock_enable_input_a = "BYPASS",
      altsyncram_component.clock_enable_input_b = "BYPASS",
      altsyncram_component.clock_enable_output_a = "BYPASS",
      altsyncram_component.clock_enable_output_b = "BYPASS",
      altsyncram_component.indata_reg_b = "CLOCK0",
      altsyncram_component.intended_device_family = "Stratix V",
      altsyncram_component.lpm_type = "altsyncram",
      altsyncram_component.numwords_a = 32,
      altsyncram_component.numwords_b = 32,
      altsyncram_component.operation_mode = "BIDIR_DUAL_PORT",
      altsyncram_component.outdata_aclr_a = "NONE",
      altsyncram_component.outdata_aclr_b = "NONE",
      altsyncram_component.outdata_reg_a = "CLOCK0",
      altsyncram_component.outdata_reg_b = "CLOCK0",
      altsyncram_component.power_up_uninitialized = "FALSE",
      altsyncram_component.read_during_write_mode_mixed_ports = "DONT_CARE",
      altsyncram_component.read_during_write_mode_port_a = "NEW_DATA_NO_NBE_READ",
      altsyncram_component.read_during_write_mode_port_b = "NEW_DATA_NO_NBE_READ",
      altsyncram_component.widthad_a = 5,
      altsyncram_component.widthad_b = 5,
      altsyncram_component.width_a = 32,
      altsyncram_component.width_b = 32,
      altsyncram_component.width_byteena_a = 1,
      altsyncram_component.width_byteena_b = 1,
      altsyncram_component.wrcontrol_wraddress_reg_b = "CLOCK0";

// PBA registers
// 4 MSI-X entries is implemented

generate
  genvar i;
  for(i=0; i< 4; i=i+1)
    begin: PBA_registers
      always @(posedge Clk_i or negedge Rstn_i)
        begin
             if(~Rstn_i)
               pba_reg[i] <= 1'b0;
             else if(SetPba_i[i])
               pba_reg[i] <= 1'b1;
             else if(ClearPba_i[i])
                pba_reg[i] <= 1'b0;
          end
    end
endgenerate
          
  assign PbaData_o = pba_reg;
    
endmodule
    
    
