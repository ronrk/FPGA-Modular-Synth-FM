// voltage controlled oscillator , create the basic wave-shape + detune

module vco_module (
	input wire clk,
	input wire resetN,
	input wire [31:0] step_size_in,	 // base freq
	input wire [1:0] wave_sel,		 // wave shape select : 00 = sine wave || 01 = saw wave || 10 = square wave || 11 = mute(no sound)
	input wire detune_ena,			 // on\off detune switch
	input wire [31:0] detune_offset, // detune offset
	
	output wire [7:0] audio_out		// audio output
);

	wire [31:0] main_phase;
	wire [31:0] detune_phase;
	wire[7:0] sine_main;
	wire [7:0] sine_detune;
	
	
	// phase engines with phase_accumulator
	phase_accumulator main_nco (
		.clk(clk),
		.resetN(resetN),
		.step_size(step_size_in),
		.phase_out(main_phase)
	);
	
	phase_accumulator detune_nco (
		.clk(clk),
		.resetN(resetN),
		.step_size(step_size_in + detune_offset), // detune effect
		.phase_out(detune_phase)
	);
	// sine memory
	sine_rom rom_main(
		.clock(clk),
		.address(main_phase[31:24]),
		.q(sine_main)
	);
	sine_rom rom_detune (
		.clock(clk),
		.address(detune_phase[31:24]),
		.q(sine_detune)
	);
	
	
	// wave-selector mux
	reg[7:0] wave_main_raw;
	reg [7:0] wave_detune_raw;
	
	always @(*) begin
		case(wave_sel)
			2'b00 : begin // sine wave
				wave_main_raw = sine_main;
				wave_detune_raw = sine_detune;
			end
			2'b01 : begin // saw wave
				wave_main_raw = main_phase[31:24];
				wave_detune_raw = detune_phase[31:24];
			end
			2'b10 : begin // square wave
				wave_main_raw = main_phase[31] ? 8'd255 : 8'd0;
				wave_detune_raw = detune_phase[31] ? 8'd255 : 8'd0;
			end
			2'b11 : begin // mute
				wave_main_raw = 8'd0;
				wave_detune_raw = 8'd0;
			end
			default:begin
				wave_main_raw = 8'd0;
				wave_detune_raw = 8'd0;
			end
		endcase
	
	end
	
	// detune mixer
	// detune on : divide each signal by 2 and summing
	
	assign audio_out = detune_ena ? ((wave_main_raw >> 1) + (wave_detune_raw >> 1)) : wave_main_raw;

endmodule