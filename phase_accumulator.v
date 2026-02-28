module phase_accumulator (
	input clk,
	input resetN,
	input [31:0] step_size,
	output reg [31:0] phase_out	
);

	always @(posedge clk) begin
		if (!resetN) begin
			phase_out <= 32'd0;
		end else begin
			phase_out <= phase_out + step_size;
		end
	end

endmodule