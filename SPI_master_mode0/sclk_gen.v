
module sclk_gen
    #(
	parameter EVEN_DIV_CNT_VALUE = 4
	)
	(
	input		sys_clk,
	input		rst_n,
	input		clkgen_en,
	output reg  spi_clk,
	output    	spi_neg_clk
	);
	reg	[log2(EVEN_DIV_CNT_VALUE-1):0]	even_div_cnt;
	
    reg   clkgen_en_delay1;
    reg   clkgen_en_delay2;
    
    always@(posedge sys_clk )begin
        clkgen_en_delay1<= clkgen_en;
        clkgen_en_delay2<= clkgen_en_delay1;
	end
	always@(posedge sys_clk or negedge rst_n)begin
		if(!rst_n)
			even_div_cnt <= { log2(EVEN_DIV_CNT_VALUE){1'b0}};
		else if(clkgen_en == 1'b1)
			begin
				if(even_div_cnt == (EVEN_DIV_CNT_VALUE-1))
					even_div_cnt <= { log2(EVEN_DIV_CNT_VALUE){1'b0}};
				else
					even_div_cnt <= even_div_cnt + 1;
			end
		else
			even_div_cnt <= { log2(EVEN_DIV_CNT_VALUE){1'b0}};
	end
	

	always@(posedge sys_clk or negedge rst_n)begin
		if(!rst_n)
			spi_clk <= 1'b0;
		else if(even_div_cnt == (EVEN_DIV_CNT_VALUE-1))
			spi_clk <= ~spi_clk;
		else
			;
	end 
	

	assign spi_neg_clk =(clkgen_en /*|| clkgen_en_delay2*/)? ~spi_clk:1'b0;  
	
	function integer log2;
		input  [31:0] size;
		integer		  i;
		begin
			log2 = 1;
			for(i=0;2**i < size;i=i+1)
				log2 = i+1;
		end 	
	endfunction
	
endmodule