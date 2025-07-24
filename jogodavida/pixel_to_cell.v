module pixel_to_cell(
	input [9:0] row,
	input [9:0] column,
	output [5:0] c_row,
	output [5:0] c_column
);
	assign c_row = row / 10;
	assign c_column = column / 10;
endmodule