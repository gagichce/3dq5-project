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
		if(upper == 8'hFF) begin
			if(lower >= 8'b11111100) begin
				clipped <= 0;
			end
		end else if (upper == 8'h01) begin
			if(lower <= 8'd4) begin
				clipped <= 8'hFF;
			end
		end
	end
end

endmodule
