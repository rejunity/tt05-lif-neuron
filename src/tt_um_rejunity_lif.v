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
    // silence linter unused warnings
    wire _unused_ok = &{1'b0,
                        ena,
                        uio_in[7:2],
                        1'b0};

    assign uio_oe[7:0]  = 8'b11_1_0_000_0;
    assign uio_out[7:0] = 8'b0000_0000;
    assign uo_out[7:2]  = 6'b0000_00;

    wire reset = !rst_n;
    wire [7:0] data_in = ui_in;
    wire execute = uio_in[0];
    wire [2:0] setup_control = uio_in[3:1];
    wire setup_sync = uio_in[4];

    wire setup_sync_posedge;
    signal_edge sync_edge (
        .clk(clk),
        .reset(reset),
        .signal(setup_sync),
        .on_posedge(setup_sync_posedge)
    );
    wire setup_enable = setup_sync_posedge | (setup_control == 3'b101); // streaming input mode

    localparam INPUTS = 2**N_STAGES;
    localparam WEIGHTS = INPUTS;
    localparam THRESHOLD_BITS = N_STAGES+1;
    localparam BIAS_BITS      = N_STAGES+2;

    localparam WEIGHT_INIT = {WEIGHTS{1'b1}}; // on reset intialise all weights to +1

    reg [INPUTS-1: 0] inputs;
    reg [WEIGHTS-1:0] weights;
    reg [THRESHOLD_BITS-1:0] threshold;
    reg signed [BIAS_BITS-1:0] bias;
    reg [2:0] shift;

    wire spike_lif;
    neuron_lif #(.SYNAPSES(WEIGHTS), .THRESHOLD_BITS(THRESHOLD_BITS)) neuron_lif (
        .clk(clk),
        .reset(reset),
        .enable(execute),
        .inputs(inputs),
        .weights(weights),
        .shift(shift),
        .threshold(threshold),
        .is_spike(spike_lif)
    );

    wire spike_pwm;
    neuron_pwm #(.SYNAPSES(WEIGHTS)) neuron_pwm (
        .clk(clk),
        .reset(reset),
        .enable(execute),
        .inputs(inputs),
        .weights(weights),
        .shift(shift+1'b1),
        .bias(bias),
        .is_spike(spike_pwm)
    );

    generate
    wire [INPUTS-1: 0] new_inputs;
    wire [WEIGHTS-1:0] new_weights;
    wire [THRESHOLD_BITS-1:0] new_threshold;
    wire signed [BIAS_BITS-1:0] new_bias;
    wire [2:0] new_shift;

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
    if (THRESHOLD_BITS > 8) begin
        assign new_threshold = { threshold[0 +: THRESHOLD_BITS-8], data_in };
    end else begin
        assign new_threshold = data_in[THRESHOLD_BITS-1:0];
    end
    if (BIAS_BITS > 8) begin
        assign new_bias = { bias[0 +: BIAS_BITS-8], data_in };
    end else begin
        assign new_bias = data_in[BIAS_BITS-1:0];
    end
    assign new_shift = data_in[2:0];
    endgenerate

    always @(posedge clk) begin
        if (reset) begin
            weights <= WEIGHT_INIT;
            inputs <= 0;
            shift <= 0;
            threshold <= 5;
            bias <= 0;
        end else begin
            if (setup_enable) begin
                case(setup_control)
                3'b001: weights <= new_weights;
                3'b010: threshold <= new_threshold;
                3'b011: bias <= new_bias;
                3'b100: shift <= new_shift;
                default:
                        inputs <= new_inputs;
                endcase
            end
        end
    end

    assign uo_out[0] = spike_lif;
    assign uo_out[1] = spike_pwm;

endmodule


