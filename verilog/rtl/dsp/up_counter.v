module up_counter #(
        parameter COUNT_TARGET =  1023, //What value the counter should count to beforee reseting
        parameter COUNT_WIDTH = 10
    ) (
    input wire i_CLK,                               //Clock
    input wire i_RST,                               //Reset
    input wire i_EN,                                //Enable start counting 
    output reg [COUNT_WIDTH - 1:0] o_CNT,           //Output count
    output reg o_ROLL                               //Indicates if there was a roll over
    );

    always @(posedge i_CLK, posedge i_RST) begin
        if(i_RST) begin                             //Asynch reset
            o_CNT <= 0;                             //Reset counter to 0
            o_ROLL <= 0;                            //Reset roll over to 0
        end 
        else if(i_EN) begin                         //if i_EN asserted, start counting
            o_CNT <= o_CNT + 1; 

            if(o_CNT == COUNT_TARGET - 1) begin
                o_ROLL <= 1;               
            end
            else begin
                o_ROLL <= 0;
            end
        end
    end
endmodule
`default_nettype wire
