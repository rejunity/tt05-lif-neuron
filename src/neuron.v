module signed_adder_with_clamp #(parameter WIDTH = 8) (
    input wire signed [WIDTH-1:0] a,
    input wire signed [WIDTH-1:0] b,
    output wire signed [WIDTH-1:0] out
);
    localparam MAX_VALUE = {1'b0, {(WIDTH-1){1'b1}}};
    localparam MIN_VALUE = {1'b1, {(WIDTH-1){1'b0}}};

    wire signed [WIDTH-1:0] a_plus_b = a + b;

    wire is_a_positive = a[WIDTH-1] == 0;
    wire is_sum_positive = a_plus_b[WIDTH-1] == 0;
    wire overflow = (a[WIDTH-1] == b[WIDTH-1]) & (is_a_positive != is_sum_positive);

    assign out = overflow ? (is_a_positive ? MAX_VALUE : MIN_VALUE) :
                            a_plus_b;

endmodule

//  7+1 = 0111 + 0001 = overflow     1000   0^0=0
// -8-1 = 1000 + 1111 = underflow (1)0111   1^1=0


module neuron #(
    parameter n_stage = 3,
    parameter n_membrane = n_stage + 2,
    parameter n_threshold = n_membrane - 1
) (
    input wire [((2**n_stage)-1):0] inputs,
    input wire [((2**n_stage)-1):0] weights,
    input wire [2:0] shift,
    input wire signed [n_membrane-1:0] last_membrane,
    input wire [n_threshold-1:0] threshold,
    input wire was_spike,
    // input wire [3:0] BN_factor,
    // input wire [(n_stage+1):0] BN_addend,
    output wire signed [n_membrane-1:0] new_membrane,
    output wire is_spike
);

    wire signed [n_membrane-1:0] sum_post_synaptic_potential;
    wire signed [n_membrane-1:0] decayed_membrane_potential;

    // range: -(2**n_stage) .. 0 .. (2**n_stage)
    // case n_stages == 2:
    // -4..4   1100..0100
    //         ^^^^ - 4 bits membrane
    mulplier_accumulator #(n_stage) multiplier_accumulator (
        .w(weights),
        .x(inputs),
        .y_out(sum_post_synaptic_potential)
    );

    // --    beta |  shift   -- gamma=1-beta
    // --  1      |    0
    // -- 0.5     |    1
    // -- 0.75    |    2
    // -- 0.875   |    3
    // -- 0.9375  |    4
    // -- 0.96875 |    5
    // -- 0.98438 |    6
    // -- 0.99219 |    7
    //
    // decayed_potential = u - gamma
    membrane_decay #(n_stage) membrane_decay (
        .u(last_membrane),
        .shift(shift),
        .beta_u(decayed_membrane_potential)
    );


    // wire signed [(n_stage+1):0] accumulated_membrane_potential = decayed_membrane_potential + sum_post_synaptic_potential;
    wire signed [n_membrane-1:0] accumulated_membrane_potential;
    signed_adder_with_clamp #(.WIDTH(n_membrane)) signed_adder_with_clamp(
        .a(decayed_membrane_potential),
        .b(sum_post_synaptic_potential),
        .out(accumulated_membrane_potential)
    );

    // membrane_reset #(n_stage) membrane_reset (
    //     .u(accumulated_membrane_potential),
    //     .threshold(threshold),
    //     .spike(was_spike),
    //     .u_out(new_membrane)
    // );

    // assign is_spike = (new_membrane >= $signed({1'b0, threshold}));

    membrane_reset #(n_stage) membrane_reset (
        .u(accumulated_membrane_potential),
        .threshold(threshold),
        .spike(is_spike),
        .u_out(new_membrane)
    );

    assign is_spike = (accumulated_membrane_potential >= $signed({1'b0, threshold}));

endmodule
