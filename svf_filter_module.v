// svf filter , low pass and resonance

module svf_filter_module (
	input wire clk,
	input wire resetN,
	input wire lpf_ena,
	input wire [7:0] audio_in,
	input wire [3:0] filter_shift_in,
	input wire [3:0] res_shift_in,
	
	output wire [7:0] audio_out
);

	// fixed-point math
	wire signed [8:0] audio_centered = $signed({1'b0, audio_in}) - 9'sd128;
	// expand to 30 bits : 5 for sign, 9 audio bits, 16 bits for fractions and force concatenation to be signed
	wire signed [29:0] raw_audio = $signed({{5{audio_centered[8]}}, audio_centered, 16'b0});
	
	// attenuate input by 4 to give headrom for resonance
	wire signed [29:0] svf_in = raw_audio >>> 2;
	
	// state registers
	reg signed [29:0] lpf_reg;
	reg signed [29:0] bp_reg; // uses to calculate resosance
	
	// calculate resosnace and highpass, and force to remain signed
	wire signed [29:0] hp = svf_in - lpf_reg - $signed(bp_reg >>> res_shift_in);
	// calculate bp next state, and force to remain signed
	wire signed [29:0] next_bp = bp_reg + $signed(hp >>> filter_shift_in);
	
	// sample rate engine 
	reg [10:0] sample_counter;
	wire sample_tick = (sample_counter == 11'd1600);
	
	

	always @(posedge clk or negedge resetN) begin
		if(!resetN) begin
			lpf_reg <= 30'd0;
			bp_reg <= 30'd0;
			sample_counter <= 11'd0;
		end else begin
			if(sample_tick) begin
				sample_counter <= 11'd0;
				if(lpf_ena) begin
					bp_reg <= next_bp;
					lpf_reg <= lpf_reg + (next_bp >>> filter_shift_in);
				end else begin
					// bypass
					lpf_reg <= raw_audio;
					bp_reg <= 30'sd0;
				end
			end else begin
				sample_counter <= sample_counter + 11'd1;
			end
		end
	end
	
	// make-up gain take bits [26:13] multiplies volume by 4
	wire signed [13:0] lpf_int = $signed(lpf_reg[27:14]);
	
	// soft-clipping overdrive
	// piecewise approximatio to round off the harsh corners of the waveform
	wire signed [13:0] soft_clip =
		(lpf_int > 14'sd191) ? 14'sd127 :						// hard knee max
		(lpf_int > 14'sd63) ? ((lpf_int + 14'sd63) >>> 1) :		// soft knee	// 1/2 slppe soft knee
		(lpf_int < -14'sd192) ? -14'sd128 :						// hard knee min
		(lpf_int < -14'sd64) ? ((lpf_int- 14'sd64) >>> 1) :		// soft knee 
		lpf_int;												// linear zone clean
			
			
	// shift back to unsigned 8-bit for audio [0 255]
	wire [7:0] filtered_safe = soft_clip[7:0] + 8'd128;
							   
	assign audio_out = filtered_safe;

endmodule