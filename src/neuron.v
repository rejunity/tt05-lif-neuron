
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

    wire signed [(n_stage+1):0] sum_post_synaptic_potential;
    wire signed [(n_stage+1):0] decayed_membrane_potential;

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

    wire signed [(n_stage+2):0] accumulated_membrane_potential;
    assign accumulated_membrane_potential = sum_post_synaptic_potential +
                                            decayed_membrane_potential;

    membrane_reset #(n_stage) membrane_reset (
        .u(accumulated_membrane_potential),
        .threshold(threshold),
        .was_spike(was_spike),
        .u_out(new_membrane)
    );

    assign is_spike = (new_membrane >= $signed(threshold));

endmodule
