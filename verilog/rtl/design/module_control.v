`default_nettype none

module module_control #(
    parameter N_MODULES = 8'd4
)(
    input we_i,
    input [2:0] addr_i, // The portion of the address used for module selection
    input [(N_MODULES * 32) - 1 : 0] module_data_i,
    output [31:0] data_o,
    output [N_MODULES-1:0] module_we_o
);
    assign data_o = (
        addr_i == 3'b001 ? module_data_i[31  : 0]  :
        addr_i == 3'b010 ? module_data_i[63  : 32] :
        addr_i == 3'b011 ? module_data_i[95  : 64] :
        addr_i == 3'b100 ? module_data_i[127 : 96] :
        {32{1'b0}}
    );

    assign module_we_o[0] = we_i && addr_i == 3'b001;
    assign module_we_o[1] = we_i && addr_i == 3'b010;
    assign module_we_o[2] = we_i && addr_i == 3'b011;
    assign module_we_o[3] = we_i && addr_i == 3'b100;
endmodule

`default_nettype wire
