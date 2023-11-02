// module membrane_reset #(parameter n_stage = 6) (
//     input signed [(n_stage+1):0] u,
//     input [n_stage:0] threshold,
//     input spike,
//     output signed [(n_stage+1):0] u_out
// );
//     wire signed [(n_stage+1):0] u_after_reset = u - $signed({1'b0, threshold});

//     // Reset membane if spike happened
//     assign u_out = spike ? u_after_reset : u;

// endmodule


module batch_normalization #(parameter n_stage = 6) (
    // input signed [(n_stage+1):0] u,
    // output signed [(n_stage+1):0] u_out
    input [(n_stage+1):0] u,
    input [3:0] BN_factor,
    input [(n_stage+1):0] BN_addend,
    output [(n_stage+1):0] u_out
);

    wire [(n_stage+1):0] shift_1_out, shift_2_out, adder2_in;
    wire [(n_stage+2):0] adder1_out, adder2_out;

    assign shift_1_out =    (BN_factor[1:0] == 2'b01) ? u >> 1 :
                            (BN_factor[1:0] == 2'b10) ? u << 1 :
                            (BN_factor[1:0] == 2'b11) ? u << 3 :
                            0;


    assign shift_2_out =    (BN_factor[3:2] == 2'b01) ? u :
                            (BN_factor[3:2] == 2'b10) ? u >> 2 :
                            (BN_factor[3:2] == 2'b11) ? u << 2 :
                            0;

    assign adder1_out = shift_1_out + shift_2_out;
    // // Calculate adder_1: shift_1_out + shift_2_out
    // nbit_adder #(n_stage+2) adder_1 (
    //     .A(shift_1_out),
    //     .B(shift_2_out),
    //     .S(adder1_out)
    // );
    assign adder2_in = adder1_out[(n_stage+1):0];

    assign adder2_out = BN_addend + adder2_in;
    // // Calculate adder_2: BN_addend + adder2_in
    // nbit_adder #(n_stage+2) adder_2 (
    //     .A(BN_addend),
    //     .B(adder2_in),
    //     .S(adder2_out)
    // );
    assign u_out = adder2_out[(n_stage+1):0];

endmodule

