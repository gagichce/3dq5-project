`timescale 1ns/100ps
`default_nettype none

module clipper (
	input logic Resetn,
	
	input logic [15:0] value,
	output logic [7:0] clipped
);

logic [7:0] upper, lower;

assign upper = value [15:8];
assign lower = value [7:0];

always_comb begin
	if(Resetn == 1'b0) begin
		clipped <= 1'b0;
	end else begin
		clipped <= lower;
		if(upper) begin
			clipped <= upper[7] ? 8'h00 : 8'hff;
		end
	end
end

endmodule
