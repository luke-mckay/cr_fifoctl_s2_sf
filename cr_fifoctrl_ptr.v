// SPDX-License-Identifier: Apache-2.0
/*
 * Copyright 2021, Luke E. McKay.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

/** FIFO Controler Pointer Tracking Module
 *  Version 0.1.0
 */
 module cr_fifoctrl_ptr
#(
  parameter pAddrSize = 3,
  parameter pCtrlAlmostSize = 5,
  parameter pCtrlType = 0
)(
  output reg                 CtrlLimit,
  output reg                 CtrlAlmostLimit,
  output     [pAddrSize-1:0] Addr,
  output reg [pAddrSize  :0] Ptr,
  input      [pAddrSize  :0] RmtPtr,
  input                      Inc,
  input                      Clk,
  input                      Rst_n
);

reg  [pAddrSize:0] bin;
wire [pAddrSize:0] binNext;
wire [pAddrSize:0] grayNext;
reg  [pAddrSize:0] rmptPtrBin;
wire               ctrlInitial;
wire [pAddrSize:0] subtract;
wire 	             ctrlLimit_next;
wire               ctrlAlmostLimit_next;

always @(posedge Clk or negedge Rst_n)
begin
  if (!Rst_n)
  begin
    {bin, Ptr} <= 0;
    CtrlLimit <= ctrlInitial;
    CtrlAlmostLimit <= ctrlInitial;
  end
  else
  begin
    {bin, Ptr} <= {binNext, grayNext};
    CtrlLimit <= ctrlLimit_next;
    CtrlAlmostLimit <= ctrlAlmostLimit_next;
  end
end

generate
  if (pCtrlType==0)
  begin
    //-----------------------------------------------------------------
    // Simplified version of the three necessary full-tests:
    // assign ctrlLimit_next=((wgnext[pAddrSize] !=RmtPtr[pAddrSize] ) &&
    // (wgnext[pAddrSize-1] !=RmtPtr[pAddrSize-1]) &&
    // (wgnext[pAddrSize-2:0]==RmtPtr[pAddrSize-2:0]));
    //-----------------------------------------------------------------
    assign ctrlLimit_next = (grayNext ==
                           {~RmtPtr[pAddrSize:pAddrSize-1],RmtPtr[pAddrSize-2:0]});
    assign ctrlInitial = 0;
    assign subtract = binNext - rmptPtrBin - pCtrlAlmostSize;
  end
  else if (pCtrlType==1)
  begin
    //--------------------------------------------------------------
    // FIFO empty when the next rptr == synchronized wptr or on reset
    //--------------------------------------------------------------
    assign ctrlLimit_next = (rgraynext == RmtPtr);
    assign ctrlInitial = 1;
    assign subtract = (binNext + pCtrlAlmostSize)-rmptPtrBin;
  end
endgenerate

// Gray code to Binary code conversion
cr_gray2bin #(
  .pWidth(pAddrSize+1) )
inst_gray2bin (
  .G (RmtPtr),
  .B (rmptPtrBin)
);

// Binary to Gray code conversion
cr_bin2gray #(
  .pWidth(pAddrSize) )
inst_gray2bin (
  .B (binNext)
  .G (grayNext),
);

assign binNext = bin + (Inc & ~CtrlLimit);
assign ctrlAlmostLimit_next = ~subtract[pAddrSize];

// Memory address pointer (okay to use binary to address memory)
assign Addr = bin[pAddrSize-1:0];

endmodule
