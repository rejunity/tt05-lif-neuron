module multiplier (
    input xi,
    input wi,
    output [1:0] y
);

    // x * w 
    //
    // x:0 ->  0
    // x:1 ->  1
    // w:0      -> -1
    // w:1      ->  1
    //
    // 0 * 0 = 0 * -1 =  0 = 00
    // 0 * 1 = 0 *  1 =  0 = 00
    // 1 * 0 = 1 * -1 = -1 = 11
    // 1 * 1 = 1 *  1 =  1 = 01

    //       _ 
    // xw    wx   y10 
    // 00 => 10 => 00
    // 01 => 00 => 00
    // 10 => 11 => 11
    // 11 => 01 => 01

    assign y[0] = xi;
    assign y[1] = xi & (~wi);

endmodule
