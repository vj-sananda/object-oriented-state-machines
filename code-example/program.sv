program test( input clk );

typedef enum {TS1,TS2,IDLE,OTHER}  OSType ;
typedef enum {PAD,NUM}  OSChar ;

`include "Ordered_Sets.sv"
`include "Phy.sv"
`include "States.sv"
`include "Link_FSM.sv"

   initial
     begin
        
	//Instantiate Phy
	Phy phy_inst = new ;
	
	//Instantiate LinkFSM1 & 2 & pass ref to Phy, define endpoints
	LinkFSM design = new(phy_inst,0);
	LinkFSM model  = new(phy_inst,1);	

	fork
	   design.run();
	   model.run();
	join_none
	
	fork

	   //Wait for link to come up
	   while( ~model.isLinkUp() )
	     begin
		@(posedge clk);
	     end

	   //Time out counter
	   begin
	      repeat(50000) @(posedge clk);
	      $display($stime,"::ERROR:Link Failed to come up");
	   end

	join_any
        disable fork;

	$finish;
	  
     end

endprogram
