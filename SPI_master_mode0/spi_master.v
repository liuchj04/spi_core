
///////////////////////////////////////////////////////////////////////////////
//Function : implemention of spi mode 0 
//Authour:   liuchj
//Description: SPI (Serial Peripheral Interface) Master
//             support: 
//                    1. single chip-select capability,
//                    2. use SPI mode0
//                    3. arbitrary length byte transfers.
//                    //4. Big_Endian or Little_Endian select
//Parameters:  CLK_DIV_CNT_VALUE - set the value of the SPI clock generate counter  
//             DATA_WIDTH - input data,output data and trans data length
//                   
// Note:       1. If multiple CS signals are needed, will need to use different module, 
//                OR multiplex the CS from this at a higher level.
//             2. SPI CLK is even divided by sys_clk
// version: 1.0            
///////////////////////////////////////////////////////////////////////////////

module spi_master
    #(
	  parameter CLK_DIV_CNT_VALUE = 2,
	  parameter DATA_WIDTH = 8
	 )
	(
	 input      				    sys_clk,
	 input 						    rst_n,
	 input      				    spi_start,
	 input      [DATA_WIDTH-1:0]  	data_in,
	 output reg [DATA_WIDTH-1:0]  	data_recv,
	 output	reg				        data_recv_vld,
	   
	 output                     spi_clk,
     input                      spi_miso,
     output     reg             spi_mosi,
     output     reg             spi_csn
			    
	 
	);
	
	parameter IDLE  = 2'd0;
	parameter START = 2'd1;
	parameter TRANS = 2'd2;
	parameter END   = 2'd3;
	 
    reg    [1:0]   c_state;
    reg	   [1:0]   n_state;
	wire 	       idle2start_flag ;
	wire	       trans2end_flag;
	wire	       end2idle_flag;
	
	reg    clkgen_en;
	 
	 
    //--------------- spi_clk generate ---------------//
always@(posedge sys_clk or negedge rst_n)begin
    if(!rst_n)
        clkgen_en<=1'b0;
    else if(c_state == END)
        clkgen_en <= 1'b0;
    else if(c_state == START)
        clkgen_en <= 1'b1;
end


	wire		spi_neg_clk; 
    sclk_gen 
		#(
		.EVEN_DIV_CNT_VALUE(CLK_DIV_CNT_VALUE)
		)
		u0_sclk_gen(
		.sys_clk(sys_clk),
		.rst_n(rst_n),
		.clkgen_en(clkgen_en),
		.spi_clk(spi_clk),
		.spi_neg_clk(spi_neg_clk)
		);

     //-------------- spi master state machine ------------//
    always@(posedge sys_clk or negedge rst_n)begin
	    if(!rst_n)
	 	   c_state <= IDLE;
	    else
	 	   c_state <=n_state;
    end
   
   
    always@(*)begin
		case(c_state)
			IDLE:
				begin
					if(idle2start_flag == 1'b1 )
						n_state = START;
					else 
						n_state = c_state;		
				end
			START:
				begin
					if(1)
						n_state = TRANS;
					else 
						n_state = c_state;		
				end
			TRANS:
				begin
					if(trans2end_flag ==1'b1 )
						n_state = END;
					else 
						n_state = c_state;		
				end			
			END:
				begin
					if(end2idle_flag )
						n_state = IDLE; 
					else 
						n_state = c_state;		
				end			
			default: n_state = IDLE;
		endcase
    end
	

	reg 	spi_start_delay;
	reg [log2(DATA_WIDTH-1):0] trans_cnt;
	reg [log2(DATA_WIDTH-1):0] spiclk_cnt;
	always@(posedge sys_clk or negedge rst_n)begin
		if(!rst_n)
			spi_start_delay <= 1'b0;
		else
			spi_start_delay <= spi_start;
	end 
	assign idle2start_flag =  ((~spi_start) && spi_start_delay) && (c_state == IDLE);
	assign trans2end_flag = spiclk_cnt == 4'd9 && c_state == TRANS;
	assign end2idle_flag  =  spiclk_cnt == 4'd9 && (c_state == END);
	
	reg 	spi_busy;
	always@(posedge sys_clk or negedge rst_n)begin
		if(!rst_n)
			spi_busy <= 1'b0;
		else if(c_state != IDLE )
			spi_busy <= 1'b1;
		else
			spi_busy <= 1'b0;
	end
	   
	always@(posedge sys_clk or negedge rst_n)begin
		if(!rst_n)
			spi_csn <= 1'b1;
		else if(c_state == START)
			spi_csn <= 1'b0;	
		else if(c_state == END)
			spi_csn <= 1'b1;
	end	
	
	always@(posedge spi_neg_clk or negedge rst_n)begin
		if(!rst_n)
			trans_cnt <= {log2(DATA_WIDTH){1'b0}};	
		else if(c_state == TRANS && trans_cnt < DATA_WIDTH)
			trans_cnt <= trans_cnt + 1;	
		else if(trans_cnt == DATA_WIDTH )
			trans_cnt <= {log2(DATA_WIDTH){1'b0}};
	end	
	
	reg  spi_neg_clk_delay1;
	
   always@(posedge sys_clk or negedge rst_n)begin
		if(!rst_n)
			spi_neg_clk_delay1 <= 1'b0;	
    	else if(clkgen_en == 1 )
		   spi_neg_clk_delay1 <= spi_neg_clk;	
	end	
	
	
	
    always@(posedge sys_clk or negedge rst_n)begin
		if(!rst_n)
			spiclk_cnt <= {log2(DATA_WIDTH){1'b0}};	
    	else if(clkgen_en == 1)
	       begin
		   if( (~spi_neg_clk_delay1 && spi_neg_clk))
		        spiclk_cnt <= spiclk_cnt + 1;
		   end	
		 else
		    spiclk_cnt <= {log2(DATA_WIDTH){1'b0}};
	end	
	
	reg [DATA_WIDTH-1:0] spi_data;	
	always@(posedge sys_clk or negedge rst_n )begin	
		if(!rst_n)
			spi_data <= {DATA_WIDTH{1'b0}};
		else if(idle2start_flag)
		    spi_data <= data_in;
		else
			;
	end 
	

		
	always@(posedge spi_neg_clk or negedge rst_n )begin	
		if(!rst_n)
			spi_mosi <= 1'b0;
		else if(c_state == TRANS)
		    spi_mosi <= spi_data[DATA_WIDTH - trans_cnt -1] ;
		else
			spi_mosi <= 1'b0;
	end 
	
	
	always@(posedge spi_clk or negedge rst_n )begin	
		if(!rst_n)
			data_recv <= {log2(DATA_WIDTH){1'b0}};
		else if(c_state == TRANS)
		    data_recv <= {spi_miso,data_recv[DATA_WIDTH-1:1]};
	end 
	
	
	always@(posedge sys_clk or negedge rst_n )begin	
		if(!rst_n)
			data_recv_vld <= 1'b0;
		else if(c_state == START)
			data_recv_vld <= 1'b0;
		else if(c_state == END)
		    data_recv_vld <= 1'b1;

	end 
	
	
	
	
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