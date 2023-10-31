module nbit_adder #(
    parameter n = 4
)
(
    input [(n-1):0] A,
    input [(n-1):0] B,
    output [n:0] S
);

    assign S = A + B;

endmodule

module nbit_adder_with_sign_extend #(
    parameter n = 4
)
(
    input  [(n-1):0] A,
    input  [(n-1):0] B,
    output [(n-1):0] S
);

    assign S =  $signed(A + B);

endmodule
