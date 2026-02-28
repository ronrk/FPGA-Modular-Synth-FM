module button_controller (
	input wire clk,
	input wire resetN,
	input wire button_in,
	output reg short_pulse,
	output reg long_pulse
);


// Metastability registers to sync button
reg sync_0, sync_1, sync_2;
// counter for pressing duration
reg [26:0] press_count;

localparam LONG_PRESS_DUR = 27'd25_000_000; // .5 sec

always @(posedge clk or negedge resetN) begin
	if(!resetN) begin
		sync_0 <= 1'b1;
		sync_1 <= 1'b1;
		sync_2 <= 1'b1;
		short_pulse <= 1'b0;
		long_pulse <= 1'b0;
		press_count <= 27'd0;
	end else begin
		// syncronize button input
		sync_0 <= button_in;  // button sample
		sync_1 <= sync_0;	// syncronize sample
		sync_2 <= sync_1;	// last sample
		
		short_pulse <= 1'b0;
		long_pulse <= 1'b0;
		
		if (sync_1 == 1'b0) begin
			// button is presseds
			if(press_count < LONG_PRESS_DUR ) begin
				// didnt pass 2 sec
				press_count <= press_count + 27'd1;
			end
			
			// trigger long pulse at 2 sec
			if(press_count == LONG_PRESS_DUR - 27'd1) begin 
				long_pulse <= 1'b1;
			end
			
		end else begin 
			// button is released
			// check for release edge (was pressed, now released)
			if(sync_2 == 1'b0) begin 
				// validate shot press
				if(press_count > 27'd1000 && press_count < LONG_PRESS_DUR) begin 
					short_pulse <= 1'b1;
				end
			end
			// initialize press time counter
			press_count <= 27'd0;
		end
	end	
end

endmodule