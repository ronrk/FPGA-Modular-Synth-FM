// LFO module, Triangle wave
	
module lfo_module (
	input wire clk,
	input wire resetN,
	input wire [31:0] step_size, // wave speed
	
	output wire [11:0] wave_out // wave-out output [0 - 4095]
);

	// internal wire thats transfer the phase from the accumulator
	wire [31:0] phase;

	// calling the phase_accumulator module
	phase_accumulator lfo_nco(
		.clk(clk),
		.resetN(resetN),
		.step_size(step_size),
		.phase_out(phase)
	);
	
	// truns the saw wave to triangle wave
	// phase[31] left bit MSB
	// phase[30:19] remains 12 bitsﬂ
	// if we on the second half of the period turn the numbers
	assign wave_out = phase[31] ? ~phase[30:19] : phase[30:19];
endmodule