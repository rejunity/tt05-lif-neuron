
module batch_normalization #(parameter WIDTH = 6, parameter ADDEND_WIDTH = WIDTH-1) (
    // input signed [(n_stage+1):0] u,
    // output signed [(n_stage+1):0] u_out
    input signed [WIDTH-1:0] u,
    input signed [WIDTH-1:0] z,
    input [3:0] BN_factor,
    input signed [ADDEND_WIDTH-1:0] BN_addend,
    output signed [WIDTH-1:0] u_out
);
    localparam MAX_VALUE = {1'b0, {(WIDTH-1){1'b1}}};
    localparam MIN_VALUE = {1'b1, {(WIDTH-1){1'b0}}};

    // IMPORTANT:
    //    BN_factor can not be higher than 8
    // if BN_factor == 8, BN_addend must be 0
    wire [WIDTH+3-1:0] adder_out;
    assign adder_out =  u +                     // based on the above limits
                        z_shift_1 + z_shift_2 + // the strong assumption of this addition
                        BN_addend;              // is that the sign will NOT flip
                                                // even when the overflow of WIDTH bit happens

    // bulldoze the precision down
    wire sign = adder_out[WIDTH+3-1];
    wire [3:0] overflow = adder_out[WIDTH+3-1 -: 4];
    assign u_out = (overflow == 4'b0000 | overflow == 4'b1111) ? adder_out[WIDTH-1:0] :
                                                   (sign == 0) ? MAX_VALUE :
                                                                 MIN_VALUE;

    wire signed [WIDTH+3-1:0] z_shift_1;
    wire signed [WIDTH+2-1:0] z_shift_2;


    // 0.25 = 1000 = z/4     
    // 0.5  = 0001 = z/2     
    // 0.75 = 1001 = z/4 + z/2
    // 1    = 0100 = z
    // 1.5  = 0101 = z   + z/2  
    // 2    = 0010 = z*2     
    // 2.25 = 1010 = z/4 + z*2
    // 3    = 0110 = z   + z*2  
    // 4    = 1100 = z*4     
    // 4.5  = 1101 = z*4 + z/2
    // 6    = 1110 = z*4 + z*2
    // 8    = 0011 = z*8     


    // [3:2]
    // 0100 = 1 pass-through
    // 1000 = /4        = 0.25
    // 1100 = *4        = 4

    // [1:0]
    // 0001 = /2        = 0.5
    // 0010 = *2        = 2
    // 0011 = *8        = 8

    // 
    // 0101 = z+z/2     = 1.5
    // 0110 = z+z*2     = 3

    // 1001 = z/4+z/2   = 0.75
    // 1010 = z/4+z*2   = 2.25
    // 1101 = z*4+z/2   = 4.5
    // 1110 = z*4+z*2   = 6

    // invalid > 8 
    // 0000 = 0 makes little sense
    // 0111 = z+z*8 = *9  invalid
    // 1011 = z/4+z*8 = *8.25  invalid
    // 1111 = z*4+z*8 = *12  invalid


    assign z_shift_1 =  (BN_factor[1:0] == 2'b01) ? z >> 1 :
                        (BN_factor[1:0] == 2'b10) ? z << 1 :
                        (BN_factor[1:0] == 2'b11) ? z << 3 :
                        0;


    assign z_shift_2 =  (BN_factor[3:2] == 2'b01) ? z :
                        (BN_factor[3:2] == 2'b10) ? z >> 2 :
                        (BN_factor[3:2] == 2'b11) ? z << 2 :
                        0;

endmodule

