module dsp #(
        parameter BUS_WIDTH = 32,
        parameter DATA_WIDTH = 8,
        parameter ADDRESS_WIDTH = 10,
        parameter OUTPUT_WIDTH = 32
    ) (       
        input i_CLK,                                //System clock in user area
        input i_RST,  
        
        input i_WISH_VALID,                                
        input i_SPI_VALID,                          

        input [BUS_WIDTH -1:0] i_WISH_DATA,         //
        input [BUS_WIDTH -1:0] i_SPI_DATA,  

        input [DATA_WIDTH -1:0] i_WEIGHT_OUT,
        input [DATA_WIDTH -1:0] i_DATA_OUT,
        
        output o_WEIGHT_ACK,
        output o_DATA_ACK,
        output o_CONV_ACK,        

        output [OUTPUT_WIDTH -1:0] o_WISH_DATA,     //
        output [OUTPUT_WIDTH -1:0] o_SPI_DATA,       //

        output o_SELECT_WEIGHT_MEMORY,
        output o_SELECT_DATA_MEMORY,

        output o_WE_WEIGHT_MEMORY,
        output o_WE_DATA_MEMORY,

        output [ADDRESS_WIDTH -1:0] o_WEIGHT_ADDRESS,
        output [ADDRESS_WIDTH -1:0] o_DATA_ADDRESS,

        output [DATA_WIDTH -1:0] o_WEIGHT_INPUT,
        output [DATA_WIDTH -1:0] o_DATA_INPUT


    );

    //State
    parameter WEIGHT_WAIT = 0, WEIGHT_PRELOAD = 1, DATA_WAIT = 2, DATA_PRELOAD = 3, CONV_LOAD = 4, CONV_EXEC = 5, CONV_WAIT = 6;
    parameter STATE_SIZE = 3;
    reg [STATE_SIZE - 1:0] state;

    //Resets
    reg [3:0] s_reset_mac;

    reg s_reset_weight_counter;
    reg s_reset_data_counter;

    //Memory Enable
    reg s_select_weight_memory;
    reg s_select_data_memory;
    
    reg s_we_weight_memory;
    reg s_we_data_memory;

    //Mac enable
    reg s_enable_mac;
    reg s_enable_weight_counter;
    reg s_enable_data_counter;

    //Data Ready ACK
    reg s_ack_weight;
    reg s_ack_data;
    reg s_ack_conv;
    
    //Mem Address
    wire [ADDRESS_WIDTH -1:0] s_weight_address;
    wire [ADDRESS_WIDTH -1:0] s_data_address;

    //Mem Data In
    reg [DATA_WIDTH -1:0] s_weight_input;
    reg [DATA_WIDTH -1:0] s_data_input;

    //Mem Data Out
    wire [DATA_WIDTH -1:0] s_weight_out;
    wire [DATA_WIDTH -1:0] s_data_out;

    reg [DATA_WIDTH -1:0] s_weight_out_latch;
    reg [DATA_WIDTH -1:0] s_data_out_latch;

    //Accumulate Out
    wire [OUTPUT_WIDTH -1:0] s_accumulate_out;
    reg [OUTPUT_WIDTH -1:0] s_accumulate_out_latch;

    //Rollover
    wire s_weight_rollover;
    wire s_data_rollover;

    wire [0:0] s_mask;

    //Delay 3 cycles
    reg [2:0]s_delay;
    

    always @(posedge i_CLK, posedge(i_RST)) begin
        if(i_RST) begin                             //Asynch reset                          
            state <= WEIGHT_PRELOAD;   

            s_reset_mac <= 4'b0001;
            s_reset_weight_counter <= 1'b1;
            s_reset_data_counter <= 1'b1;

            s_ack_weight <= 1'b1;
            s_ack_data <= 1'b0;
            s_ack_conv <= 1'b0;
        end 
        else  begin 

            s_weight_out_latch <= s_weight_out;
            s_data_out_latch <= s_data_out;

            s_reset_mac <= s_reset_mac >> 1;

            s_reset_weight_counter <= 1'b0;
            s_reset_data_counter <= 1'b0; 

            s_enable_mac <= 1'b1;
            s_enable_weight_counter <= 1'b0;
            s_enable_data_counter <= 1'b0;
             
            s_select_data_memory <= 1'b1;
            s_select_weight_memory <= 1'b1;
            
            case(i_WISH_VALID)
                1'b0    :   begin
                                s_weight_input <= i_SPI_DATA[DATA_WIDTH -1:0];
                                s_data_input <= i_SPI_DATA[DATA_WIDTH -1:0];
                            end
                default :   begin
                                s_weight_input <= i_WISH_DATA[DATA_WIDTH -1:0];
                                s_data_input <= i_WISH_DATA[DATA_WIDTH -1:0];
                            end
            endcase

            s_we_weight_memory <= 1'b0;
            s_we_data_memory <= 1'b0;

            case (state)
                WEIGHT_PRELOAD: begin
                    if(i_WISH_VALID || i_SPI_VALID) begin
                        s_ack_weight <= 1'b0;
                        state <= WEIGHT_WAIT;
                        s_we_weight_memory <= 1'b1;
                        s_enable_weight_counter <= 1'b1;
                    end
                end

                WEIGHT_WAIT: begin
                    s_ack_weight <= 1'b1;
                    state <= WEIGHT_PRELOAD;
                    s_we_weight_memory <= 1'b0;
                    s_enable_weight_counter <= 1'b0;

                    if(s_weight_rollover == 1'b1) begin
                        state <= DATA_PRELOAD;
                        s_ack_data <= 1'b1;
                    end
                end

                DATA_PRELOAD: begin
                    if(i_WISH_VALID || i_SPI_VALID) begin
                        s_ack_data <= 1'b0;
                        state <= DATA_WAIT;
                        s_we_data_memory <= 1'b1;
                        s_enable_data_counter <= 1'b1;
                    end
                end

                DATA_WAIT: begin
                    s_ack_data <= 1'b1;
                    state <= DATA_PRELOAD;
                    s_we_data_memory <= 1'b0;
                    s_enable_data_counter <= 1'b0;

                    if(s_data_rollover == 1'b1) begin
                        state <= CONV_LOAD;
                        s_ack_conv <= 1'b1;
                    end
                end
                
                
                CONV_LOAD: begin
                    if(i_WISH_VALID || i_SPI_VALID) begin
                        s_ack_conv <= 1'b0;
                        state <= CONV_EXEC;
                        s_we_data_memory <= 1'b1;
                        s_enable_data_counter <= 1'b1;

                        s_reset_mac <= 4'b1000;
                    end
                end

                CONV_EXEC: begin
                    s_we_data_memory <= 1'b0;
                    s_enable_weight_counter <= 1'b1;
                    s_enable_data_counter <= 1'b1;

                    if(s_weight_rollover == 1'b1) begin
                        state <= CONV_WAIT;
                        s_enable_weight_counter <= 1'b0;
                        s_enable_data_counter <= 1'b0;
                        s_delay <=3'b100;
                    end
                end


                CONV_WAIT: begin
                    if(s_delay == 3'b001) begin
                        s_accumulate_out_latch <= s_accumulate_out;
                        s_ack_conv <= 1'b1;
                        state <= CONV_LOAD;
                    end

                    s_delay <= s_delay >> 1;
                end

                default: begin
                end
            endcase
        end
    end

    assign o_WISH_DATA = s_accumulate_out_latch;
    assign o_SPI_DATA = s_accumulate_out_latch;

    assign o_WEIGHT_ACK  = s_ack_weight;
    assign o_DATA_ACK = s_ack_data;
    assign o_CONV_ACK = s_ack_conv;

    assign s_mask = 1'b1;

    assign s_weight_out = i_WEIGHT_OUT; 
    assign s_data_out = i_DATA_OUT;

    assign o_SELECT_WEIGHT_MEMORY = s_select_weight_memory;
    assign o_SELECT_DATA_MEMORY = s_select_data_memory;

    assign o_WE_WEIGHT_MEMORY = s_we_weight_memory;
    assign o_WE_DATA_MEMORY = s_we_data_memory;

    assign o_WEIGHT_ADDRESS = s_weight_address;
    assign o_DATA_ADDRESS = s_data_address;

    assign o_WEIGHT_INPUT = s_weight_address;
    assign o_DATA_INPUT = s_data_input;

    mac
    #()
    g_mac (
        .i_CLK          (i_CLK),
        .i_RST          (s_reset_mac[0:0]),
        .i_EN           (s_enable_mac),
        .i_WEIGHT       (s_weight_out_latch),
        .i_DATA         (s_data_out_latch),
        .o_ACCUMULATE   (s_accumulate_out)
    );

    up_counter 
	#(
		.COUNT_TARGET(1023), 
		.COUNT_WIDTH(10)
	) 
	g_weight_counter (
    	.i_CLK	(i_CLK), 		                //
    	.i_RST	(s_reset_weight_counter), 		//
    	.i_EN 	(s_enable_weight_counter),      //
    	.o_CNT	(s_weight_address), 		    //
    	.o_ROLL	(s_weight_rollover)	            //
    );

    up_counter 
	#(
		.COUNT_TARGET(1023), 
		.COUNT_WIDTH(10)
	) 
	g_data_counter (
    	.i_CLK	(i_CLK), 		                //
    	.i_RST	(s_reset_data_counter), 		//
    	.i_EN 	(s_enable_data_counter),  	    //
    	.o_CNT	(s_data_address), 	            //
    	.o_ROLL	(s_data_rollover)	            //
    );

    // sky130_sram_1kbyte_1rw1r_8x1024_8 
    // #(
    //     .VERBOSE(0)
    // )
    // g_weight_memory(

    //     `ifdef USE_POWER_PINS
	//         .vccd1(vccd1),	// User area 1 1.8V power
	//         .vssd1(vssd1),	// User area 1 digital ground
    //     `endif

    //     // rw
    //     .clk0(i_CLK),
    //     .csb0(~s_select_weight_memory),
    //     .web0(~s_we_weight_memory),
    //     .addr0(s_weight_address),
    //     .din0(s_weight_input),
    //     .dout0(s_weight_out),
    //     // r
    //     .clk1(i_CLK),
    //     .csb1(~s_select_weight_memory),
    //     .addr1(),
    //     .dout1()
    // );

    // sky130_sram_1kbyte_1rw1r_8x1024_8  
    // #(
    //     .VERBOSE(0)
    // )
    // g_data_memory(

    //     `ifdef USE_POWER_PINS
	//         .vccd1(vccd1),	// User area 1 1.8V power
	//         .vssd1(vssd1),	// User area 1 digital ground
    //     `endif

    //     // rw
    //     .clk0(i_CLK),
    //     .csb0(~s_select_data_memory),
    //     .web0(~s_we_data_memory),
    //     .addr0(s_data_address),
    //     .din0(s_data_input),
    //     .dout0(s_data_out),
    //     // r
    //     .clk1(i_CLK),
    //     .csb1(~s_select_data_memory),
    //     .addr1(),
    //     .dout1()
    // );



endmodule
`default_nettype wire