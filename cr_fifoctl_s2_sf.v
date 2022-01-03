// SPDX-License-Identifier: Apache-2.0
/*
 * Copyright 2022, Luke E. McKay.
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

/** Dual Clock FIFO Controller with Static Flags
 *  Version 0.1.0
 */
module cr_fifoctl_s2_sf
#(
  parameter pDepth = 8,       //!< Depth/size of FIFO in words, power of 2
  parameter pPushAeLevel = 2, //!< PushAlmostEmpty is set when FIFO count <= this
  parameter pPushAfLevel = 2, //!< PushAlmostFull is set when FIFO count > this
  parameter pPopAeLevel = 2,  //!< PopAlmostEmpty is set when FIFO count <= this
  parameter pPopAfLevel = 2,  //!< PopAlmostFull flag is set when FIFO count is > this
//  parameter pErrMode = 0,     //!< 0 -> set till reset;  1 -> set while error exists  @todo this make sense?
//  parameter pPushSync = 2,    //!< Push flag sync mode
//  parameter pPopSync = 2,     //!< Pop flag sync mode
  parameter pRstMode = 0      //!< 0 -> asynchronous reset;  1 -> synchronous reset
)(
  //# {{clocks|}}
  input  wire Push_clk,        //!< Clock input for push interface
  input  wire Push_rst_n,      //!< Reset input for push interface, active low
  input  wire Pop_clk,         //!< Clock input for pop interface
  input  wire Pop_rst_n,       //!< Reset input for pop interface, active low
  //# {{}}
  input  wire PushReq_n,       //!< FIFO push request, active low
  output wire PushWordCount,   //!< Number of words in FIFO
  output wire PushEmpty,       //!< Status flag FIFO empty
  output wire PushAlmostEmpty, //!< Status flag FIFO almost empty (pPushAeLevel)
  output wire PushHalfFull,    //!< Status flag FIFO half full
  output wire PushAlmostFull,  //!< Status flag FIFO almost full (pPushAfLevel)
  output wire PushFull,        //!< Status flag FIFO full
  output wire PushError,       //!< Status flag FIFO overrun error
  //# {{}}
  input  wire PopReq_n,        //!< FIFO pop request, active low
  output wire PopWordCount,    //!< Number of words in FIFO
  output wire PopEmpty,        //!< Status flag FIFO empty
  output wire PopAlmostEmpty,  //!< Status flag FIFO almost empty (pPopAeLevel)
  output wire PopHalfFull,     //!< Status flag FIFO half full
  output wire PopAlmostFull,   //!< Status flag FIFO almost full (pPopAfLevel)
  output wire PopFull,         //!< Status flag FIFO full
  output wire PopError,        //!< Status flag FIFO underrun error
  //# {{}}
  output wire                      WrEn_n, //!< Write enable for RAM write port
  output wire [$clog2(pDepth)-1:0] WrAddr, //!< Address for RAM write port
  output wire                      RdEn_n, //!< Read enable for RAM read port
  output wire [$clog2(pDepth)-1:0] RdAddr  //!< Address for RAM read port
);

localparam ADDR_SIZE = $clog2(pDepth);
// @todo add error for incorrect size

wire [ADDR_SIZE-1:0] waddr, raddr;
wire [  ADDR_SIZE:0] wptr, rptr, wq2_rptr, rq2_wptr;

// Synchronize the read pointer to write domain
cr_sync #(
  .pWidth(ADDR_SIZE),
  .pStages(2),
  .pSimEn(0),
  .pRstMode(0) )
inst_sync_r2w (
  .Q     (wq2_rptr),
  .D     (rptr),
  .Clk   (Push_clk),
  .Rst_n (Push_rst_n)
);

// Synchronize the write pointer to read domain
cr_sync #(
  .pWidth(ADDR_SIZE) )
inst_sync_w2r (
  .Q     (rq2_wptr),
  .D     (wptr),
  .Clk   (Pop_clk),
  .Rst_n (Pop_rst_n)
);

// The module handling the write requests
cr_fifoctrl_ptr #(
  .pAddrSize(ADDR_SIZE),
  .pCtrlAlmostSize(5),
  .pCtrlType(0) )
inst_wptr_full (
  .CtrlAlmostLimit (push_af),
  .CtrlLimit       (push_full),
  .Addr            (waddr),
  .Ptr             (wptr),
  .RmtPtr          (wq2_rptr),
  .Inc             (winc),
  .Clk             (Push_clk),
  .Rst_n           (Push_rst_n)
);

// The module handling read requests
cr_fifoctrl_ptr #(
  .pAddrSize(ADDR_SIZE),
  .pCtrlAlmostSize(3),
  .pCtrlType(1) )
inst_rptr_empty (
  .CtrlAlmostLimit (pop_ae),
  .CtrlLimit       (pop_empty),
  .Addr            (raddr),
  .Ptr             (rptr),
  .RmtPtr          (rq2_wptr),
  .Inc             (rinc),
  .Clk             (Pop_clk),
  .Rst_n           (Pop_rst_n)
);

endmodule
