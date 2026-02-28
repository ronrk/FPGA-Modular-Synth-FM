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
	// expand to 30 bits : 5 for sign, 9 audio bits, 16 bits for fractions
	wire signed [29:0] svf_in = {{5{audio_centered[8]}}, audio_centered, 16'b0};
	
	// state registers
	reg signed [29:0] lpf_reg;
	reg signed [29:0] bp_reg; // uses to calculate resosance
	
	// calculate resosnace and highpass
	wire signed [29:0] hp = svf_in - lpf_reg -(bp_reg >>> res_shift_in);
	// calculate bp next state
	wire signed [29:0] next_bp = bp_reg + (hp >>> filter_shift_in);

	always @(posedge clk or negedge resetN) begin
		if(!resetN) begin
			lpf_reg <= 30'd0;
			bp_reg <= 30'd0;
		end else if(lpf_ena) begin
			bp_reg <= next_bp;
			lpf_reg <= lpf_reg + (next_bp >>> filter_shift_in);
		
		end else begin
		// bypass
			lpf_reg <= svf_in;
			bp_reg <= 30'd0;	
		end
	end
	
	// saturation defense 
	// taking back only the integers from the 30 bits
	wire signed [13:0] lpf_int = lpf_reg[29:16];
	wire [7:0] filtered_safe = (lpf_int > 14'sd127) ? 8'd255 :
							   (lpf_int < -14'sd128) ? 8'd0 :
							   (lpf_int[7:0] + 8'd128);
	assign audio_out = filtered_safe;

endmodule