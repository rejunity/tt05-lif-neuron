
module neuron #(parameter n_stage = 2) (
    input wire [((2**n_stage)-1):0] inputs,
    input wire [((2**n_stage)-1):0] weights,
    input wire [2:0] shift,
    input wire signed [(n_stage+1):0] last_membrane,
    input wire [(n_stage+1):0] threshold,
    input wire was_spike,
    // input wire [3:0] BN_factor,
    // input wire [(n_stage+1):0] BN_addend,
    output wire signed [(n_stage+1):0] new_membrane,
    output wire is_spike
);

    wire signed [(n_stage+1):0] y_out;
    wire signed [(n_stage+1):0] beta_u;

    mulplier_accumulator #(n_stage) multiplier_accumulator (
        .w(weights),
        .x(inputs),
        .y_out(y_out)
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
    // beta_u = u - gamma_u
    decay_potential #(n_stage) decay_potential (
        .u(last_membrane),
        .shift(shift),
        .beta_u(beta_u)
    );

    mem_potential_acc #(n_stage) mem_potential_acc (
        .beta_u(beta_u),
        .sum_wx(y_out),
        .threshold(threshold),
        .was_spike(was_spike),
        .u_out(new_membrane)
    );

    assign is_spike = (new_membrane >= $signed(threshold));

endmodule
