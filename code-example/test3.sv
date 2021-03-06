//------------------------------------------
// test3.sv:
//----------
// Link bring after test sets up a
// non-compliant state transition for the
// model. Link bring up failure is detected
// and the state transition is corrected.
//------------------------------------------

program test( input clk );

`include "Ordered_Sets.sv"
`include "Phy.sv"
`include "States.sv"
`include "LTSSM.sv"

   initial
     begin
        
	//Instantiate Phy
	Phy phy_inst = new ;
	
	//Instantiate LinkFSM1 & 2 & pass ref to Phy, define endpoints
	LTSSM  design = new(phy_inst,0);
	LTSSM  model  = new(phy_inst,1);	
	
	model.PollingConfiguration.NextState = model.ConfigurationIdle;
	
	fork
	   design.run();
	   model.run();
	join_none

	begin
	   fork

	      //Wait for link to come up
	      while( ~model.isLinkUp() )
		begin
		   @(posedge clk);
		end
	      
	      //Time out counter
	      begin
		 repeat(5000) @(posedge clk);
		 $display($stime,"::Link up Failed => wrong Nextstate transition,Fixing..");	           
		 model.PollingConfiguration.NextState = model.ConfigurationLinkLane;
	      end
	      
	   join_any
	   disable fork;
       end // fork branch
	   
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
