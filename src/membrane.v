module membrane_decay #(parameter n_stage = 6) (
    input signed [(n_stage+1):0] u,
    input [2:0] shift,
    output signed [(n_stage+1):0] beta_u
);

    wire signed [(n_stage+1):0] gamma_u;

    // Assign gamma_u based on shift
    assign gamma_u = (shift == 3'b001) ? u >> 1 :
                     (shift == 3'b010) ? u >> 2 :
                     (shift == 3'b011) ? u >> 3 :
                     (shift == 3'b100) ? u >> 4 :
                     (shift == 3'b101) ? u >> 5 :
                     (shift == 3'b110) ? u >> 6 :
                     (shift == 3'b111) ? u >> 7 :
                     0; // no decay

    assign beta_u = u - gamma_u;

endmodule


module membrane_reset #(parameter n_stage = 6) (
    input signed [(n_stage+1):0] u,
    input [n_stage:0] threshold,
    input spike,
    output signed [(n_stage+1):0] u_out
);
    wire signed [(n_stage+1):0] u_after_reset = u - $signed({1'b0, threshold});

    // Reset membane if spike happened
    assign u_out = spike ? u_after_reset : u;

endmodule
