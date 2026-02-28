// Arrpeggiator module, major chord

module arpeggiator_module (
	input wire clk,
	input wire resetN,
	input wire arp_ena,					// on/off switch
	input wire [31:0] arp_speed_step,	// run speed
	input wire [31:0] base_step,		// input freq
	
	output wire [31:0] arp_out_step,		// output updated freq
	output wire [1:0] arp_note_out
);
	
	wire [31:0] arp_phase;
	// calling phase accumulator module, uses only for metronome
	phase_accumulator arp_nco (
		.clk(clk),
		.resetN(resetN),
		.step_size(arp_speed_step),
		.phase_out(arp_phase)
	);
	
	// take the two left bits to count
	assign arp_note_out = arp_phase[31:30];
	// if the arppggiator off, pass the original frequency, else multiply the freq to get musical notes
	assign arp_out_step = (!arp_ena) ? base_step :
						  (arp_note_out == 2'd0) ? base_step :
						  (arp_note_out == 2'd1) ? base_step + (base_step >> 2) :
						  (arp_note_out == 2'd2) ? base_step + (base_step >> 1) :
											(base_step << 1);

endmodule