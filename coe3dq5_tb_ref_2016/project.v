/*
Copyright by Henry Ko and Nicola Nicolici
Developed for the Digital Systems Design course (COE3DQ4)
Department of Electrical and Computer Engineering
McMaster University
Ontario, Canada
*/

`timescale 1ns/100ps
`default_nettype none

`include "define_state.h"

// This is the top module
// It connects the SRAM and VGA together
// It will first write RGB data of an image with 8x8 rectangles of size 40x30 pixels into the SRAM
// The VGA will then read the SRAM and display the image
module project (
		/////// board clocks                      ////////////
		input logic CLOCK_50_I,                   // 50 MHz clock

		/////// pushbuttons/switches              ////////////
		input logic[3:0] PUSH_BUTTON_I,           // pushbuttons
		input logic[17:0] SWITCH_I,               // toggle switches

		/////// VGA interface                     ////////////
		output logic VGA_CLOCK_O,                 // VGA clock
		output logic VGA_HSYNC_O,                 // VGA H_SYNC
		output logic VGA_VSYNC_O,                 // VGA V_SYNC
		output logic VGA_BLANK_O,                 // VGA BLANK
		output logic VGA_SYNC_O,                  // VGA SYNC
		output logic[9:0] VGA_RED_O,              // VGA red
		output logic[9:0] VGA_GREEN_O,            // VGA green
		output logic[9:0] VGA_BLUE_O,             // VGA blue
		
		/////// SRAM Interface                    ////////////
		inout wire[15:0] SRAM_DATA_IO,            // SRAM data bus 16 bits
		output logic[17:0] SRAM_ADDRESS_O,        // SRAM address bus 18 bits
		output logic SRAM_UB_N_O,                 // SRAM high-byte data mask 
		output logic SRAM_LB_N_O,                 // SRAM low-byte data mask 
		output logic SRAM_WE_N_O,                 // SRAM write enable
		output logic SRAM_CE_N_O,                 // SRAM chip enable
		output logic SRAM_OE_N_O                  // SRAM output logic enable
);

parameter NUM_ROW_RECTANGLE = 8,
		  NUM_COL_RECTANGLE = 8,
		  RECT_WIDTH = 40,
		  RECT_HEIGHT = 30,
		  VIEW_AREA_LEFT = 160,
		  VIEW_AREA_RIGHT = 480,
		  VIEW_AREA_TOP = 120,
		  VIEW_AREA_BOTTOM = 360;

parameter Y_OFFSET = 0, U_OFFSET = 18'd38400, V_OFFSET = 18'd57600, RGB_OFFSET = 18'd146944;

// Define the offset for Green and Blue data in the memory		
parameter RED_OFFSET = 18'd146944,
	  GREEN_EVEN_OFFSET = 18'd185344,
	  GREEN_ODD_OFFSET = 18'd204544,
	  BLUE_EVEN_OFFSET = 18'd223744,
	  BLUE_ODD_OFFSET = 18'd242944;

parameter U_21_CONSTANT = 32'd21, U_52_CONSTANT = 32'd52, U_159_CONSTANT = 32'd159;
parameter R_76284_CONSTANT = 32'd76284, R_25624_CONSTANT = 32'hFFFF9BE8, R_132251_CONSTANT = 32'd132251, R_104595_CONSTANT = 32'd104595, R_53281_CONSTANT = 32'hFFFF2FDF;

parameter ROW_LENGTH = 16'd320, COLUMN_LENGTH = 16'd240;

// Data counter for getting RGB data of a pixel
logic [17:0] data_counter;
state_top state;
logic done;

//keep track of whether or not we are working on an even collumn.
logic even_counter;

assign even_counter = ~data_counter[0];

logic [2:0] S_IDLE_WAIT;
// For Push button
logic [3:0] PB_pushed;

// For VGA
logic [9:0] VGA_red, VGA_green, VGA_blue;
logic [9:0] pixel_X_pos;
logic [9:0] pixel_Y_pos;

logic resetn;

// For SRAM
logic [17:0] SRAM_address;
logic [15:0] SRAM_write_data;
logic SRAM_we_n;
logic [15:0] SRAM_read_data;
logic [7:0] SRAM_read_high_byte, SRAM_read_low_byte;
logic SRAM_ready;

assign SRAM_read_high_byte = SRAM_read_data[15:8];
assign SRAM_read_low_byte = SRAM_read_data[7:0];

logic [31:0] DPRAM_write_data, DPRAM_read_data;
logic [8:0] DPRAM_write_address, DPRAM_read_address;
logic DPRAM_wen;

// For Colorspace conversion
logic [31:0] RED, GREEN, BLUE, Y_ODD, Y_EVEN, U_ODD, U_EVEN, V_ODD, V_EVEN, Y_multi_EVEN, U_multi_EVEN, V_multi_EVEN, Y_multi_ODD, U_multi_ODD, V_multi_ODD;

logic [31:0] U_21, U_52, U_159, V_21, V_52, V_159;

logic [31:0] R_result_EVEN, G_result_EVEN, B_result_EVEN, R_result_ODD, G_result_ODD, B_result_ODD;

logic [7:0] R_writable_even, G_writable_even, B_writable_even, R_writable_odd, G_writable_odd, B_writable_odd;

logic [15:0] R_0, R_1, R_2;

logic [7:0] row_offset, column_offset;

assign R_0 = {R_writable_even, G_writable_even};
assign R_1 = {B_writable_even, R_writable_odd};
assign R_2 = {G_writable_odd, B_writable_odd};

logic [17:0] RGB_OFFSET_ADDRESS;

logic [8:0] U_N [7:0];
logic [8:0] V_N [7:0];

assign U_21 = U_N[5] + U_N[0];
assign U_52 = U_N[4] + U_N[1];
assign U_159 = U_N[3] + U_N[2];

assign V_21 = V_N[5] + V_N[0];
assign V_52 = V_N[4] + V_N[1];
assign V_159 = V_N[3] + V_N[2];

assign Y_multi_EVEN = Y_EVEN - 8'd16;
assign U_multi_EVEN = U_EVEN - 8'd128;
assign V_multi_EVEN = V_EVEN - 8'd128;

assign Y_multi_ODD = Y_ODD - 8'd16;
assign U_multi_ODD = U_ODD[31:8] - 8'd128;
assign V_multi_ODD = V_ODD[31:8] - 8'd128;

logic [31:0] mul0_op1, mul0_op2, mul0_result;
logic [31:0] mul1_op1, mul1_op2, mul1_result;
logic [31:0] mul2_op1, mul2_op2, mul2_result;

logic [2:0] rect_row_count;	// Number of rectangles in a row
logic [2:0] rect_col_count;	// Number of rectangles in a column
logic [5:0] rect_width_count;	// Width of each rectangle
logic [4:0] rect_height_count;	// Height of each rectangle
logic [2:0] color;

logic [15:0] VGA_sram_data [2:0];

logic [7:0] Red_buf, G2_buf, B2_buf;

logic RED_second_word;

assign resetn = ~SWITCH_I[17] && SRAM_ready;


logic start_row;
logic end_row;

assign end_row = (data_counter % 160) >= 156;


// Each rectangle will have different color
assign color = rect_col_count + rect_row_count;

always_ff @ (posedge CLOCK_50_I or negedge resetn) begin
	if (resetn == 1'b0) begin
		state <= S_IDLE_TOP;
		S_IDLE_WAIT <= 2'b00;
		rect_row_count <= 3'd0;
		rect_col_count <= 3'd0;
		rect_width_count <= 6'd0;
		rect_height_count <= 5'd0;
		
		VGA_red <= 10'd0;
		VGA_green <= 10'd0;
		VGA_blue <= 10'd0;				
		
		SRAM_we_n <= 1'b1;
		SRAM_write_data <= 16'd0;
		SRAM_address <= 18'd0;

		DPRAM_wen <= 1'b0;
		DPRAM_write_data <= 16'b0;
		DPRAM_write_address <= 9'b0;
		DPRAM_read_address <= 9'b0;
		
		data_counter <= 18'd0;
		RED_second_word <= 1'b0;

		Y_ODD <= 1'b0;
		Y_EVEN <= 1'b0;
		U_ODD <= 1'b0;
		U_EVEN <= 1'b0;
		V_ODD <= 1'b0;
		V_EVEN <= 1'b0;
 		
 		U_N[0] <= 1'b0; U_N[1] <= 1'b0; U_N[2] <= 1'b0; U_N[3] <= 1'b0; U_N[4] <= 1'b0; U_N[5] <= 1'b0; U_N[6] <= 1'b0; U_N[7] <= 1'b0;
		V_N[0] <= 1'b0; V_N[1] <= 1'b0; V_N[2] <= 1'b0; V_N[3] <= 1'b0; V_N[4] <= 1'b0; V_N[5] <= 1'b0; V_N[6] <= 1'b0; V_N[7] <= 1'b0;

		R_result_EVEN <= 1'b0;
		G_result_EVEN <= 1'b0;
		B_result_EVEN <= 1'b0;

		R_result_ODD <= 1'b0;
		G_result_ODD <= 1'b0;
		B_result_ODD <= 1'b0;
		start_row <= 1'b0;
		
		RGB_OFFSET_ADDRESS <= 1'b0;
		row_offset <= 1'b0;

	end else begin
		case (state)
		S_IDLE_TOP: begin
			S_IDLE_WAIT <= S_IDLE_WAIT + 1'b1;
			if (S_IDLE_WAIT == 2'b1) begin
				S_IDLE_WAIT <= 1'b0;
				state <= S_DP_TEST_0;
				//state <= S_READ_U_0;
				//SRAM_address <= data_counter[17:1] + U_OFFSET;
			end
			done <= 1'b1;
		end

		S_DP_TEST_0: begin
			state <= S_DP_TEST_1;
			DPRAM_write_address <= 1'b0;
			DPRAM_read_address <= 1'b1;
			DPRAM_write_data <= 16'd666;
			DPRAM_wen <= 1'b1;
		end

		S_DP_TEST_1: begin
			state <= S_DP_TEST_2;
			DPRAM_wen <= 1'b0;		
			DPRAM_read_address <= 1'b0;	
		end

		S_DP_TEST_2: begin
			state <= S_DP_TEST_3;
		end

		S_DP_TEST_3: begin
			state <= S_IDLE_TOP;
		end

		S_READ_U_0: begin
			state <= S_READ_U_1;
			SRAM_address <= data_counter[17:1] + U_OFFSET + 1; 
		end

		S_READ_U_1: begin
			state <= S_READ_V_0;
			SRAM_address <= data_counter[17:1] + V_OFFSET; 
		end

		S_READ_V_0: begin
			SRAM_address <= data_counter[17:1] + V_OFFSET + 1; 
			U_EVEN <= SRAM_read_high_byte;
			U_N[0] <= SRAM_read_high_byte;
			U_N[1] <= SRAM_read_high_byte;
			U_N[2] <= SRAM_read_high_byte;
			U_N[3] <= SRAM_read_low_byte;
			state <= S_READ_V_1;

		end
		
		S_READ_V_1: begin
			SRAM_address <= data_counter + Y_OFFSET;
			U_N[4] <= SRAM_read_high_byte;
			U_N[5] <= SRAM_read_low_byte;
			state <= S_READ_Y;
		end

		S_READ_Y: begin
			V_EVEN <= SRAM_read_high_byte;
			V_N[0] <= SRAM_read_high_byte;
			V_N[1] <= SRAM_read_high_byte;
			V_N[2] <= SRAM_read_high_byte;
			V_N[3] <= SRAM_read_low_byte;
			state <= S_START_ROW;
		end
		S_START_ROW: begin
			V_N[4] <= SRAM_read_high_byte;
			V_N[5] <= SRAM_read_low_byte;
			
			start_row <= 1'b1;

			state <= S_CALC_U;
		end
		S_CALC_U: begin
			if(~start_row) begin
				SRAM_write_data <= R_1;
				SRAM_address <= RGB_OFFSET_ADDRESS + 2'b01;
				SRAM_we_n <= 1'b0;
				G_result_ODD <= G_result_ODD + mul2_result;
				B_result_ODD <= B_result_ODD + mul1_result;

				V_N[0] <= V_N[1];
				V_N[1] <= V_N[2];
				V_N[2] <= V_N[3];
				V_N[3] <= V_N[4];
				V_N[4] <= V_N[5];

				V_EVEN <= V_N[3];
				
				if(data_counter[0] && (~end_row)) begin
					V_N[5] <= SRAM_read_high_byte;
					V_N[6] <= SRAM_read_low_byte;
				end else begin
					V_N[5] <= V_N[6];
				end
			end

			mul0_op1 <= U_21;
			mul0_op2 <= U_21_CONSTANT;
			mul1_op1 <= U_52;
			mul1_op2 <= U_52_CONSTANT;
			mul2_op1 <= U_159;
			mul2_op2 <= U_159_CONSTANT;

			state <= S_CALC_V;
		end
		S_CALC_V: begin

			if(~start_row) begin
				SRAM_write_data <= R_2;
				SRAM_address <= RGB_OFFSET_ADDRESS + 2'b10;
				SRAM_we_n <= 1'b0;
			end

			U_ODD <= mul0_result - mul1_result + mul2_result + 128;

			mul0_op1 <= V_21;
			mul0_op2 <= U_21_CONSTANT;
			mul1_op1 <= V_52;
			mul1_op2 <= U_52_CONSTANT;
			mul2_op1 <= V_159;
			mul2_op2 <= U_159_CONSTANT;

			//load Y
			Y_EVEN <= SRAM_read_high_byte;
			Y_ODD <= SRAM_read_low_byte;
			
			state <= S_CALC_R00;
		end

		S_CALC_R00: begin

			SRAM_we_n <= 1'b1; //stop writing to SRAM

			SRAM_address <= U_OFFSET + data_counter[17:1] + 2;

			V_ODD <= mul0_result - mul1_result + mul2_result + 128;

			mul0_op1 <= Y_multi_EVEN;
			mul0_op2 <= R_76284_CONSTANT;

			mul1_op1 <= U_multi_EVEN;
			mul1_op2 <= R_25624_CONSTANT;

			mul2_op1 <= V_multi_EVEN;
			mul2_op2 <= R_104595_CONSTANT;

			state <= S_CALC_R01;

			if((data_counter % 160 == 0) && ~start_row) state <= S_END_ROW;
		end

		S_CALC_R01: begin

			SRAM_address <= V_OFFSET + data_counter[17:1] + 2;

			
			R_result_EVEN <= mul0_result + mul2_result;
			G_result_EVEN <= mul0_result + mul1_result;
			B_result_EVEN <= mul0_result;

			mul0_op1 <= 32'b11;
			mul0_op2 <= data_counter;

			mul1_op2 <= R_132251_CONSTANT;

			mul2_op2 <= R_53281_CONSTANT;
			
			state <= S_CALC_R10;
		end


		S_CALC_R10: begin
			RGB_OFFSET_ADDRESS <= RGB_OFFSET + mul0_result; //calculate the next offset to be used in the next round
			
			SRAM_address <= Y_OFFSET + data_counter + 1;

			G_result_EVEN <= G_result_EVEN + mul2_result;
			B_result_EVEN <= B_result_EVEN + mul1_result;
			
			
			mul0_op1 <= Y_multi_ODD;
			mul0_op2 <= R_76284_CONSTANT;

			mul1_op1 <= U_multi_ODD;
			mul1_op2 <= R_25624_CONSTANT;

			mul2_op1 <= V_multi_ODD;
			mul2_op2 <= R_104595_CONSTANT;
			
			state <= S_CALC_R11;
			start_row <= 1'b0;
		end

		S_CALC_R11: begin

			if(~start_row) begin
				SRAM_write_data <= R_0;
				SRAM_address <= RGB_OFFSET_ADDRESS;
				SRAM_we_n <= 1'b0;
			end
			
			U_N[0] <= U_N[1];
			U_N[1] <= U_N[2];
			U_N[2] <= U_N[3];
			U_N[3] <= U_N[4];
			U_N[4] <= U_N[5];

			U_EVEN <= U_N[3];

			if(~data_counter[0] && (~end_row)) begin
				U_N[5] <= SRAM_read_high_byte;
				U_N[6] <= SRAM_read_low_byte;
			end else begin
				U_N[5] <= U_N[6];
			end

			//U_N[7] = SRAM_read_low_byte;

			R_result_ODD <= mul0_result + mul2_result;
			G_result_ODD <= mul0_result + mul1_result;
			B_result_ODD <= mul0_result;

			mul0_op1 <= 0;
			mul0_op2 <= 0;

			mul1_op2 <= R_132251_CONSTANT;

			mul2_op2 <= R_53281_CONSTANT;
			
			state <= S_CALC_U;
			data_counter <= data_counter + 1'b1;
		end

		S_END_ROW: begin
			//check if last row
			if(data_counter >= 38400) begin state <= S_IDLE_TOP; end else begin			
				SRAM_address <= data_counter[17:1] + U_OFFSET;
				state <= S_READ_U_0;
			end
		end

		default: state <= S_IDLE_TOP;
		endcase
	end
end

dual_port_ram0 ram_inst (
	.clock(CLOCK_50_I),
	.data(DPRAM_write_data),
	.rdaddress(DPRAM_read_address),
	.wraddress(DPRAM_write_address),
	.q(DPRAM_read_data),
	.wren(DPRAM_wen)
);

// Push Button unit
PB_Controller PB_unit (
	.Clock_50(CLOCK_50_I),
	.Resetn(resetn),
	.PB_signal(PUSH_BUTTON_I),	
	.PB_pushed(PB_pushed)
);
clipper clipper_r_odd(
	.Resetn(resetn),
	.value(R_result_ODD[31:16]),
	.clipped(R_writable_odd)
);
clipper clipper_r_even(
	.Resetn(resetn),
	.value(R_result_EVEN[31:16]),
	.clipped(R_writable_even)
);
clipper clipper_g_even(
	.Resetn(resetn),
	.value(G_result_EVEN[31:16]),
	.clipped(G_writable_even)
);
clipper clipper_g_odd(
	.Resetn(resetn),
	.value(G_result_ODD[31:16]),
	.clipped(G_writable_odd)
);
clipper clipper_b_even(
	.Resetn(resetn),
	.value(B_result_EVEN[31:16]),
	.clipped(B_writable_even)
);
clipper clipper_b_odd(
	.Resetn(resetn),
	.value(B_result_ODD[31:16]),
	.clipped(B_writable_odd)
);

// SRAM unit
SRAM_Controller SRAM_unit (
	.Clock_50(CLOCK_50_I),
	.Resetn(~SWITCH_I[17]),
	.SRAM_address(SRAM_address),
	.SRAM_write_data(SRAM_write_data),
	.SRAM_we_n(SRAM_we_n),
	.SRAM_read_data(SRAM_read_data),		
	.SRAM_ready(SRAM_ready),
		
	// To the SRAM pins
	.SRAM_DATA_IO(SRAM_DATA_IO),
	.SRAM_ADDRESS_O(SRAM_ADDRESS_O),
	.SRAM_UB_N_O(SRAM_UB_N_O),
	.SRAM_LB_N_O(SRAM_LB_N_O),
	.SRAM_WE_N_O(SRAM_WE_N_O),
	.SRAM_CE_N_O(SRAM_CE_N_O),
	.SRAM_OE_N_O(SRAM_OE_N_O)
);

// VGA unit
VGA_Controller VGA_unit(
	.Clock(CLOCK_50_I),
	.Resetn(resetn),

	.iRed(VGA_red),
	.iGreen(VGA_green),
	.iBlue(VGA_blue),
	.oCoord_X(pixel_X_pos),
	.oCoord_Y(pixel_Y_pos),
	
	//	VGA Side
	.oVGA_R(VGA_RED_O),
	.oVGA_G(VGA_GREEN_O),
	.oVGA_B(VGA_BLUE_O),
	.oVGA_H_SYNC(VGA_HSYNC_O),
	.oVGA_V_SYNC(VGA_VSYNC_O),
	.oVGA_SYNC(VGA_SYNC_O),
	.oVGA_BLANK(VGA_BLANK_O),
	.oVGA_CLOCK(VGA_CLOCK_O)
);

milestone1_multiplier mul0 (
	.Resetn(resetn),
	.value00(mul0_op1),
	.value01(mul0_op2),
	.select(1'b0),
	.result(mul0_result)
);

milestone1_multiplier mul1 (
	.Resetn(resetn),
	.value00(mul1_op1),
	.value01(mul1_op2),
	.select(1'b0),
	.result(mul1_result)
);

milestone1_multiplier mul2 (
	.Resetn(resetn),
	.value00(mul2_op1),
	.value01(mul2_op2),
	.select(1'b0),
	.result(mul2_result)
);

endmodule
