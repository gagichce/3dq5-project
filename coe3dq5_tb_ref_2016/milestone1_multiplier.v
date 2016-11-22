`timescale 1ns/100ps
`default_nettype none

module milestone1_multiplier (
	input logic Resetn,
	
	input logic [31:0] value00, value01, value10, value11,
	input logic select,
	output logic [31:0] result
);

logic [31:0] op1, op2;

logic signed [63:0] result_calculation_long;

assign result = result_calculation_long[31:0];
assign result_calculation_long = {{32{op1[31]}},op1} * {{32{op2[31]}},op2}; //sign extention on the operands

always_comb begin
	if(Resetn == 1'b0) begin
		op1 <= 1'b0;
		op2 <= 1'b0;

	end else begin
		if(select) begin
			op1 <= value10;
			op2 <= value11;
		end else begin
			op1 <= value00;
			op2 <= value01;
		end
	end
end

endmodule
