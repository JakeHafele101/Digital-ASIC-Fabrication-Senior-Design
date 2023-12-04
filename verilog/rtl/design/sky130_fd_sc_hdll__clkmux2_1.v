/*
 * Copyright 2020 The SkyWater PDK Authors
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     https://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * SPDX-License-Identifier: Apache-2.0
*/


`ifndef SKY130_FD_SC_HDLL__CLKMUX2_1_FUNCTIONAL_V
`define SKY130_FD_SC_HDLL__CLKMUX2_1_FUNCTIONAL_V

/**
 * clkmux2: Clock mux.
 *
 * Verilog simulation functional model.
 */

`default_nettype none

/// sta-blackbox

// Import user defined primitives.
`celldefine
module sky130_fd_sc_hdll__clkmux2_1 (
    output X,
    input A0,
    input A1,
    input S,
    `ifdef USE_POWER_PINS
        inout VPWR,
        inout VGND,
        inout VPB,
        inout VNB
    `endif
);

    assign X = S ? A1 : A0;

endmodule
`endcelldefine

`default_nettype wire
`endif  // SKY130_FD_SC_HDLL__CLKMUX2_1_FUNCTIONAL_V
