module pitch_mixer (
	input wire [31:0] base_step,		// original freq
	input wire vib_ena,				
	input wire [11:0] vib_wave,			// wave fro lfo
	output wire [31:0] modulated_step	// final freq
);

	// centered the signal [-2048 - 2047]
	wire signed [12:0] centered_vib = $signed({1'b0, vib_wave}) - 13'sd2048;
	// double the effect
	wire signed [32:0] full_step = $signed({1'b0, base_step}) + (centered_vib <<< 1);
	assign modulated_step = vib_ena ? full_step[31:0] : base_step; 

endmodule