`default_nettype none

module tt_um_rejunity_lif #(parameter N_STAGES = 5) (
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
    wire [7:0] data_in = ui_in;
    wire input_weights = uio_in[0];
    wire input_mode =   !uio_in[1];

    localparam INPUTS = 2**N_STAGES;
    localparam WEIGHTS = INPUTS;
    localparam MEMBRANE_BITS = N_STAGES+2;
    localparam THRESHOLD_BITS = MEMBRANE_BITS-1;

    localparam WEIGHT_INIT = {WEIGHTS{1'b1}}; // on reset intialise all weights to +1


    reg [INPUTS-1: 0] inputs;
    reg [WEIGHTS-1:0] weights;
    wire signed [MEMBRANE_BITS-1:0] new_membrane;
    reg signed [MEMBRANE_BITS-1:0] last_membrane;
    reg [THRESHOLD_BITS-1:0] threshold;
    reg [2:0] shift;

    wire spike;
    neuron #(.n_stage(N_STAGES), .n_membrane(MEMBRANE_BITS), .n_threshold(THRESHOLD_BITS)) neuron (
        .inputs(inputs),
        .weights(weights),
        .shift(shift),
        .last_membrane(last_membrane),
        .threshold(threshold),
        .new_membrane(new_membrane),
        .is_spike(spike)
    );

    generate
    wire [INPUTS-1: 0] new_inputs;
    wire [WEIGHTS-1:0] new_weights;
    if (WEIGHTS > 8) begin
        assign new_weights = { weights[0 +: WEIGHTS-8], data_in };
    end else begin
        assign new_weights = data_in[WEIGHTS-1:0];
    end
    if (INPUTS > 8) begin
        assign new_inputs = { inputs[0 +: INPUTS-8], data_in };
    end else begin
        assign new_inputs = data_in[INPUTS-1:0];
    end
    endgenerate

    always @(posedge clk) begin
        if (reset) begin
            weights <= WEIGHT_INIT;
            inputs <= 0;
            shift <= 0;
            threshold <= 5;
            last_membrane <= 0;
        end else begin
            if (input_mode) begin
                if (input_weights)
                    weights <= new_weights;
                else
                    inputs <= new_inputs;

            end else begin
                last_membrane <= new_membrane;
            end
        end
    end

    assign uo_out[0] = spike;

endmodule


