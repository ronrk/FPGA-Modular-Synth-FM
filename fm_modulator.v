module fm_modulator (
	input wire clk,
	input wire resetN,
	input wire [7:0] audio_in,
	output reg fm_out
);

// accumulator register 32bit
reg [31:0] phase_acc;

// carrier freq const 11mhz
localparam [31:0] BASE_STEP = 32'd944892805; // 11MHz Base -> Creates massive Alias at 89.0MHz

always @(posedge clk) begin
	if (!resetN) begin
		phase_acc <= 32'b0;
		fm_out <= 1'b0;
	end else begin 
		//Freq modulation: Base Freq + Audio deviation
		phase_acc <= phase_acc + BASE_STEP + ((audio_in - 32'd128) << 14);
		//Output the MSB to generate the square wave
		fm_out <= phase_acc[31];
	end
	
end

endmodule
