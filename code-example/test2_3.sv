//------------------------------------------
// test2_1.sv:
//------------
// Link bring up test after changing the
// number of ordered sets transmitted by the
// model LTSSM in Polling Active state
//------------------------------------------

program test( input clk );

`include "Ordered_Sets.sv"
`include "Phy.sv"
`include "States.sv"
`include "LTSSM.sv"
bit success;
int TransmitCnt ;

   initial
     begin
        
	//Instantiate Phy
	Phy phy_inst = new ;
	
	//Instantiate LinkFSM1 & 2 & pass ref to Phy, define endpoints
	LTSSM  design = new(phy_inst,0);
	LTSSM  model  = new(phy_inst,1);	
	
	std::randomize(TransmitCnt) with {TransmitCnt inside { 16, 15 }; } ; //Change from 1024
	
	model.PollingActive.TransmitCnt = TransmitCnt ;
	$display ("model.PollingActive.TransmitCnt = %d", TransmitCnt);

	
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
