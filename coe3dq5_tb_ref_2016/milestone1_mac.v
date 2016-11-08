`timescale 1ns/100ps
`default_nettype none

module milestone1_mac (
	input logic Clock_50,
	input logic Resetn,
	
	input logic [31:0] value, reset_parameter,
	input logic enable_ffn, use_default, subtract,
	output logic [31:0] result
);

always_ff @ (posedge Clock_50 or negedge Resetn) begin
	if(Resetn == 1'b0) begin
		result <= 1'b0;
	end else begin
		if(enable_ffn == 1'b0) begin
			if(use_default) begin
				result <= reset_parameter;
			end else begin
				if (subtract) result <= result - value; else
				result <= result + value;
			end
		end
	end
end

endmodule
