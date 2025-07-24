module mesh(
	input clk,
	input img,
	output img_out
);
	wire [3:0] proc_in [3:0];
	wire [3:0] proc_out [3:0];

	assign proc_in[0][0] = img;
	assign img_out = proc_out[3][3];
	
	genvar i, j;
	
	generate
		for (i = 0; i < 4; i = i + 1) begin : lines
			for (j = 0; j < 4; j = j + 1) begin : columns
				if ((i + j) % 2 == 0) begin
					erosao proc_e ( 
						.clk (clk),
						.img (proc_in[i][j]),
						.img_out (proc_out[i][j])
					);
				end else begin
					dilatacao proc_d (
						.clk(clk),
						.img(proc_in[i][j]),
						.img_out(proc_out[i][j])
					);
				end
			end
		end
	endgenerate

	// Tabela de roteamento
	assign proc_in[1][0] = proc_out[0][0];
	assign proc_in[1][1] = proc_out[1][0];
	assign proc_in[1][2] = proc_out[1][1];
	assign proc_in[2][2] = proc_out[1][2];
	assign proc_in[2][3] = proc_out[2][2];
	assign proc_in[3][3] = proc_out[2][3];
	
endmodule