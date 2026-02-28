// Delay and Echo

module delay_fx_module (
	input wire clk,
	input wire resetN,
	input wire delay_ena,
	input wire [7:0] audio_in,
	input wire [14:0] delay_time_in,	// delay time
	input wire [3:0] delay_fb_in,		// delay feedback [0-8]
	
	output wire [7:0] audio_out
);

	wire [7:0] delayed_audio;	// wet audio
	reg [10:0] sample_counter;	// counter to slow the sample time
	reg [14:0] write_ptr;		// "record head"
	reg [14:0] current_delay_time;
	
	wire [14:0] read_ptr = write_ptr - current_delay_time;
	wire sample_tick = (sample_counter == 11'd1600);
	
	// tape glide
	always @(posedge clk or negedge resetN) begin
		if(!resetN) begin
			sample_counter <= 11'd0;
			write_ptr <= 15'd0;
			current_delay_time <= 15'd16000;
		end else begin
			if(sample_tick) begin
				sample_counter <= 11'd0;
				write_ptr <= write_ptr + 15'd1;		// moving the recording head
				
				// to avoid clicks on sound when changing parameters
				if (current_delay_time < delay_time_in) begin
					current_delay_time <= current_delay_time + 15'd1;				
				end else if(current_delay_time > delay_time_in) begin
					current_delay_time <= current_delay_time - 15'd1;
				end
			end else begin
				sample_counter <= sample_counter + 11'd1;
			end
		end
	end

	// feedback and send mixer
	wire signed [8:0] dry_c = $signed({1'b0, audio_in}) - 9'sd128;
	wire signed [8:0] echo_c = $signed({1'b0 , delayed_audio}) - 9'sd128;
	
	// calculate feedback
	wire signed [13:0] echo_scaled = echo_c * $signed({1'b0, delay_fb_in});
	wire signed [8:0] echo_fb = echo_scaled / 8;
	// if delay is on : 50% dry + 50% wet, else entered only feedback for continuity
	wire signed [9:0] ram_in_mix = delay_ena ? ((dry_c / 2) + echo_fb) : echo_fb;
	// saturatio defense
	wire signed [9:0] ram_in_sat = (ram_in_mix > 10'sd127) ? 10'sd127 :
								   (ram_in_mix < -10'sd128) ? -10'sd128 :
								   ram_in_mix;
	// back to positive to save in memory
	wire [7:0] ram_data_in = ram_in_sat[7:0] + 8'd128;
	// physical memory
	delay_ram delay_inst (
		.clock(clk),			
		.data(ram_data_in),		// record sound
		.rdaddress(read_ptr),	// where we read from
		.wraddress(write_ptr),	// where to write
		.wren(sample_tick),		// record period: once at 1600 clock periods
		.q(delayed_audio)		// what been reading
	);
	
	// clean master out
	wire signed [9:0] final_mix_c = (dry_c /2) + (echo_c /2);
	wire [7:0] final_out = (final_mix_c > 10'sd127) ? 8'd255 :
						   (final_mix_c < -10'sd128) ? 8'd0 :
						   (final_mix_c[7:0] + 8'd128);
						   
	assign audio_out = final_out;

endmodule