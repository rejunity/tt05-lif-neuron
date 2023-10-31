`default_nettype none

module tt_um_rejunity_lif #( parameter N_STAGES = 3 ) (
    input  wire [7:0] ui_in,    // Dedicated inputs - connected to the input switches
    output wire [7:0] uo_out,   // Dedicated outputs - connected to the 7 segment display
    input  wire [7:0] uio_in,   // IOs: Bidirectional Input path
    output wire [7:0] uio_out,  // IOs: Bidirectional Output path
    output wire [7:0] uio_oe,   // IOs: Bidirectional Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // will go high when the design is enabled
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

    assign uio_oe[7:0] = 8'b0000_0000; // all BIDIRECTIONAL pins in INPUT mode
    assign uio_out[7:0] = 8'b0000_0000;
    assign uo_out[7:1] = 7'b000_0000;


    wire reset = !rst_n;
    wire input_weights = uio_in[0];

    wire spike;

    localparam INPUTS = 2**N_STAGES;
    localparam WEIGHTS = INPUTS;
    localparam OUTPUT_PRECISION = N_STAGES+2;

    wire [OUTPUT_PRECISION-1:0] u_out;

    reg [INPUTS-1: 0] x;                            // inputs
    reg [WEIGHTS-1:0] w;                            // weights
    reg [OUTPUT_PRECISION-1:0] previus_u;
    reg [OUTPUT_PRECISION-1:0] minus_threshold;
    reg [2:0] shift;
    reg was_spike;

    neuron #(.n_stage(N_STAGES)) neuron (
        .w(w),
        .x(x),
        .shift(shift),
        .previus_u(previus_u),
        .minus_teta(minus_threshold),
        .was_spike(was_spike),
        .u_out(u_out),
        .is_spike(spike)
    );

    always @(posedge clk) begin
        if (reset) begin
            w <= {WEIGHTS{1'b1}};                  // intialise all weights to +1
            x <= 0;
            shift <= 0;
            minus_threshold <= -5;
            previus_u <= 0;
            was_spike <= 0;
        end else begin
            was_spike <= spike;
            previus_u <= u_out;

            if (input_weights) begin
                if (WEIGHTS > 8)
                    w <= { w[0 +: WEIGHTS-8], ui_in[7:0] };
                else 
                    w <= ui_in[7:0];
            end else begin
                if (INPUTS > 8)
                    x <= { x[0 +: INPUTS-8], ui_in[7:0] };
                else
                    x <= ui_in[7:0];
            end
        end
    end

    assign uo_out[0] = spike;

endmodule
