module mem_potential_acc #(parameter n_stage = 6) (
    input signed [(n_stage+1):0] beta_u,
    input signed [(n_stage+1):0] sum_wx,
    input [(n_stage+1):0] threshold,
    input was_spike,
    output signed [(n_stage+1):0] u_out
);

    wire signed [(n_stage+2):0] accumulated_potential, reset_membrane;

    // // Calculate Adder1 = beta*u(t-1) + sum[w*x(t)]
    // nbit_adder #(n_stage+2) Adder_1 (
    //     .A(beta_u),
    //     .B(sum_wx),
    //     .S(accumulated_potential)
    // );

    // // Calculate Adder2 = beta*u(t-1) + sum[w*x(t)] + minus_teta
    // nbit_adder #(n_stage+2) Adder_2 (
    //     .A(accumulated_potential[(n_stage+1):0]),
    //     .B(minus_teta),
    //     .S(reset_membrane)
    // );

    assign accumulated_potential = beta_u + sum_wx;
    assign reset_membrane = accumulated_potential[(n_stage+1):0] - threshold;

    // Assign u_out based on was_spike
    assign u_out = (was_spike ?
        reset_membrane[(n_stage+1):0] :
        accumulated_potential[(n_stage+1):0]);

endmodule
