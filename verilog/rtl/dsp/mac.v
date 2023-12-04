module mac #(
        parameter INPUT_WIDTH =  8, 
        parameter OUTPUT_WIDTH = 32
    ) (
    input wire i_CLK,                               //Clock
    input wire i_RST,                               //Reset
    input wire i_EN,                                //Enable start counting 
    input wire [INPUT_WIDTH - 1:0] i_WEIGHT,        //Input Weight 
    input wire [INPUT_WIDTH - 1:0] i_DATA,          //Input Data 
    output wire [OUTPUT_WIDTH - 1:0] o_ACCUMULATE    //Output Accumulation
    );


    wire [(INPUT_WIDTH *2) - 1:0] s_mult;
    wire [OUTPUT_WIDTH - 1:0] s_accumulate;
    reg [OUTPUT_WIDTH - 1:0] s_last_accumulate;


    always @(posedge i_CLK) begin
        if(i_RST) begin                             //Asynch reset                          
            s_last_accumulate <= 0;                 //Reset accumulation to 0
        end 
        else if(i_EN) begin                         //if i_EN asserted, start counting
            s_last_accumulate <= s_accumulate;
        end
    end

    assign s_mult = i_WEIGHT * i_DATA;
    assign s_accumulate = s_mult + s_last_accumulate;
    assign o_ACCUMULATE = s_accumulate;

endmodule
`default_nettype wire
