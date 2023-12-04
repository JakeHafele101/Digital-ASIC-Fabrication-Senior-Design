`default_nettype none

/// sta-blackbox

`celldefine
(*keep*)
module SIGN (
`ifdef USE_POWER_PINS
  inout vccd1,
  inout vssd1
`endif
);
endmodule
`endcelldefine

`default_nettype wire
