 /*                                                                      
 Copyright 2017 Silicon Integrated Microelectronics, Inc.                
                                                                         
 Licensed under the Apache License, Version 2.0 (the "License");         
 you may not use this file except in compliance with the License.        
 You may obtain a copy of the License at                                 
                                                                         
     http://www.apache.org/licenses/LICENSE-2.0                          
                                                                         
  Unless required by applicable law or agreed to in writing, software    
 distributed under the License is distributed on an "AS IS" BASIS,       
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and     
 limitations under the License.                                          
 */                                                                      
                                                                         
                                                                         
                                                                         
//=====================================================================
//--        _______   ___
//--       (   ____/ /__/
//--        \ \     __
//--     ____\ \   / /
//--    /_______\ /_/   MICROELECTRONICS
//--
//=====================================================================
// Designer   : Bob Hu
//
// Description:
//  The ITCM-SRAM module to implement ITCM SRAM
//
// ====================================================================

`include "e203_defines.v"

  `ifdef E203_HAS_ITCM //{
module e203_itcm_ram(

  input                              sd,
  input                              ds,
  input                              ls,

  input                              cs,  
  input                              we,  
  input  [`E203_ITCM_RAM_AW-1:0] addr, 
  input  [`E203_ITCM_RAM_MW-1:0] wem,
  input  [`E203_ITCM_RAM_DW-1:0] din,          
  output [`E203_ITCM_RAM_DW-1:0] dout,
  input                              rst_n,
  input                              clk

);

wire wren =  we & cs;

wire [7:0]wea;
assign wea = (wren) ? wem  : 8'b0;

wire rden;
assign rden = (~we) & cs;

// bram u_e203_itcm_gnrl_ram(
//
//	.doa    (dout),
//	.dia    (din ),
//	.addra  (addr),
//	.wea    (wea ),
//	.cea    (cs  ),
//	.clka   (clk ),
//	.rsta   (1'b0),
//	
//	.dob    (),
//	.dib    (`E203_ITCM_RAM_DW'b0),
//	.addrb  (13'b0),
//	.web    (8'b0),
//	.ceb    (1'b0),
//	.clkb   (1'b0),
//	.rstb   (1'b0)
//    );
 
  riscv_ram64 u_e203_itcm_gnrl_ram
 (
	.address(addr),
	.byteena(wea),
	.clock  (clk),
	.data   (din),
   .rden   (rden),
	.wren   (wren),
	.q      (dout)
	);
 
//  sirv_gnrl_ram #(
//      `ifndef E203_HAS_ECC//{
//    .FORCE_X2ZERO(0),
//      `endif//}
//    .DP(`E203_ITCM_RAM_DP),
//    .DW(`E203_ITCM_RAM_DW),
//    .MW(`E203_ITCM_RAM_MW),
//    .AW(`E203_ITCM_RAM_AW) 
//  ) u_e203_itcm_gnrl_ram(
//  .sd  (sd  ),
//  .ds  (ds  ),
//  .ls  (ls  ),
//
//  .rst_n (rst_n ),
//  .clk (clk ),
//  .cs  (cs  ),
//  .we  (we  ),
//  .addr(addr),
//  .din (din ),
//  .wem (wem ),
//  .dout(dout)
//  );
                                                      
endmodule
  `endif//}
