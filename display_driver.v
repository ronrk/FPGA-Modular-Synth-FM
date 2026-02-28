module display_driver (
	input wire [15:0] freq_hz_in,
	output wire [6:0] thousands_out,
	output wire [6:0] hundreds_out,
	output wire [6:0] tens_out,
	output wire [6:0] ones_out
);

wire [3:0] th, hu, te ,on;

// Binary to BCD convert
assign th = (freq_hz_in / 1000) % 10;
assign hu = (freq_hz_in / 100) % 10;
assign te = (freq_hz_in / 10) % 10;
assign on = freq_hz_in % 10;

// 7-seg decoders

bcd_to_7seg dec_th (.bcd(th), .seg(thousands_out));
bcd_to_7seg dec_hu (.bcd(hu), .seg(hundreds_out));
bcd_to_7seg dec_te (.bcd(te), .seg(tens_out));
bcd_to_7seg dec_on (.bcd(on), .seg(ones_out));

endmodule


// Take a 4-bit number and turns the correct segments
module bcd_to_7seg (
	input wire [3:0] bcd,
	output reg [6:0] seg
);

	always @(*) begin
		case(bcd)
			4'd0: seg = 7'b1000000;
            4'd1: seg = 7'b1111001;
            4'd2: seg = 7'b0100100;
            4'd3: seg = 7'b0110000;
            4'd4: seg = 7'b0011001;
            4'd5: seg = 7'b0010010;
            4'd6: seg = 7'b0000010;
            4'd7: seg = 7'b1111000;
            4'd8: seg = 7'b0000000;
            4'd9: seg = 7'b0010000;
            default: seg = 7'b1111111;
         endcase
     end
       
endmodule
