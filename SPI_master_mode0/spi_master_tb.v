`timescale 1ns/1ps
module spi_master_tb;

reg 		sys_clk  	  ;
reg 		rst_n    	  ;
reg     	spi_start	  ;
reg [7:0]	data_in  	  ;

wire   		data_recv_vld ;
wire		spi_clk       ;
reg   		spi_miso      ;
wire   		spi_mosi      ;
wire   		spi_csn       ;

always
     #50 sys_clk = ~sys_clk; 

initial begin
	sys_clk = 1'b0;
	rst_n  = 1'b0;
	#100 rst_n = 1'b1;
end 

initial begin
	data_in = 8'h55;
end 


initial begin
	spi_start = 1'b0;
	#160 spi_start = 1'b1;
	#100 spi_start = 1'b0;
	#4500 spi_start = 1'b1;
	#100 spi_start = 1'b0;
end

initial begin
	spi_miso = 1;
	#4760 spi_miso = 0;
end 




 spi_master
    #(
	 .CLK_DIV_CNT_value(4), 
	 .DATA_WIDTH(8)
	 ) u0_spi_master
	(
	.sys_clk          ( sys_clk        )    ,
	.rst_n            ( rst_n       )       ,
	.spi_start        ( spi_start      )    ,
	.data_in          ( data_in        )    ,
	.data_recv_vld    ( data_recv_vld  )    ,
											
	.spi_clk          ( spi_clk        )    ,
    .spi_miso         ( spi_miso       )    ,
    .spi_mosi         ( spi_mosi       )    ,
    .spi_csn          ( spi_csn        )			    
	 
	);












endmodule