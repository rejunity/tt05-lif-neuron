// module spike_generator #(parameter n_stage = 2) (
//     input signed [(n_stage+1):0] u,
//     input signed [(n_stage+1):0] minus_teta,
//     output is_spike
// );
//     wire [(n_stage+2):0] s_out;

//     // Calculate Adder_1 = u + minus_teta
//     // nbit_adder #(n_stage+2) Adder_1 (
//     //     .A(u),
//     //     .B(minus_teta),
//     //     .S(s_out)
//     // );

//     assign s_out = u + minus_teta;

//     // Assign is_spike based on s_out
//     assign is_spike = s_out[(n_stage+2)];

// endmodule
