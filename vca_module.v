// VCA, voltage controlled amplifier, and envelope
	
module vca_module (
	input wire clk,
	input wire resetN,
	input wire [7:0] audio_in,
	input wire tremolo_ena,
	input wire [11:0] trem_wave_in,
	input wire pluck_ena,
	input wire arp_ena,
	input wire [1:0] arp_note_in,
	
	output wire [7:0] audio_out
);
	// pluck envelope
	reg[1:0] last_arp_note;
	reg[7:0] pluck_env;
	reg[14:0] decay_timer;
	
	always @(posedge clk or negedge resetN) begin
		if(!resetN) begin
			last_arp_note <= 2'b0;
			pluck_env <= 8'd0;
			decay_timer <= 15'd0;
		end else begin
			last_arp_note <= arp_note_in;
			decay_timer <= decay_timer + 15'd1;
			// attack : when arp move to new note, max volume
			if( arp_ena && (arp_note_in != last_arp_note)) begin
				pluck_env <= 8'd255;
			end
			// decay : if timer is 0, volume down the signal
			else if (decay_timer == 15'd0 && pluck_env > 8'd0) begin
				pluck_env <= pluck_env - 8'd1;
			end
		end
	end

	// volume mux
	wire [7:0] trem_envelope = trem_wave_in[11:4];
	wire [7:0] current_volume = (pluck_ena && arp_ena) ? pluck_env :
								(tremolo_ena) ? trem_envelope :
								8'd255; 
	
	// AM modulation
	// centered the audio to 0, to avoid dc noise than multiply in volume, and returns to 0-255
	wire signed [8:0] audio_centered = $signed({1'b0, audio_in}) - 9'sd128;
	wire signed [17:0] mixed_signed = audio_centered * $signed ({1'b0 ,current_volume});
	
	// take the 8 relevant bits 
	wire signed [8:0] audio_out_centered = mixed_signed [16:8];
	assign audio_out = audio_out_centered[7:0] + 8'd128;
endmodule