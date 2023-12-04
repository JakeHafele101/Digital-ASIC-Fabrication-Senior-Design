`default_nettype none

/// sta-blackbox

`celldefine
module NAND (
    output X,
    input A,
    input B,
    `ifdef USE_POWER_PINS
        inout VPWR,
        inout VGND,
        inout VPB,
        inout VNB
    `endif
);
    
    assign X = ~(A & B);

endmodule
`endcelldefine

`default_nettype wire
