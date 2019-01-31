//-------------------------------------------------------
// LTSSM.sv:
//----------
// The Link Training and Status State Machine class, which
// ties all the state definitions together.
// The main state machine loop is implemented in the run()
// method.
// The LTSSM class requires instantiations of each state,
// and setting of the NextState & TimeoutState member
// variables within each state.
//-------------------------------------------------------
class LTSSM ;

Base_State FsmState, NextFsmState ;

Detect_State                  Detect ;
Polling_Active_State          PollingActive ;
Polling_Configuration_State   PollingConfiguration ;
Configuration_LinkLane_State  ConfigurationLinkLane ;
Configuration_Complete_State  ConfigurationComplete;
Configuration_Idle_State      ConfigurationIdle ;
L0_State                      L0 ;
  
OrderedSet_TS1     ts1 ;
OrderedSet      ts ;

Phy   PhyLink ;

bit PhyEndpoint ;

int Enable = `TRUE ;

function new (Phy _phy, bit endpoint ) ;
      
      PhyLink = _phy;
      PhyEndpoint = endpoint ;
      
      Detect = new (_phy,endpoint);      
      PollingActive = new (_phy,endpoint);
      PollingConfiguration = new (_phy,endpoint);
      ConfigurationLinkLane  = new (_phy,endpoint);
      ConfigurationComplete  = new (_phy,endpoint);
      ConfigurationIdle = new (_phy,endpoint);
      L0 = new (_phy,endpoint);
      
      //Initial State 
      FsmState = Detect ;
      
      //Setup transitions
      Detect.NextState    = PollingActive ;
      Detect.TimeoutState = Detect   ;
      
      PollingActive.NextState    = PollingConfiguration ;
      PollingActive.TimeoutState = Detect   ;

      PollingConfiguration.NextState     = ConfigurationLinkLane ;
      PollingConfiguration.TimeoutState  = Detect  ;

      ConfigurationLinkLane.NextState      = ConfigurationComplete    ;
      ConfigurationLinkLane.TimeoutState   = Detect   ;

      ConfigurationComplete.NextState      = ConfigurationIdle    ;
      ConfigurationComplete.TimeoutState   = Detect   ;

      ConfigurationIdle.NextState      = L0 ;
      ConfigurationIdle.TimeoutState   = Detect   ;                  
      
      L0.NextState         = L0 ;
      L0.TimeoutState      = L0 ;
      
endfunction 

//Run FSM
task run () ;
      
      while( Enable ) 
	begin
	   
           fork
              
              FsmState.Transmit() ;
	      
              FsmState.display();
	      
	      begin
		 fork
		    FsmState.Receive(NextFsmState);
		    FsmState.ReceiveTimeout(NextFsmState);		 
		    join_any
		disable fork;
	     end
	      
           join

	 //Changing State, flush receive queue
	 //to prevent next state from using "remnants" in receive queue. 	    
	 PhyLink.flush(PhyEndpoint);
		    
         FsmState = NextFsmState ;
		    
       end
		 
 endtask 

function logic isLinkUp() ;
      logic linkup_status;
      FsmState.updateLinkStatus( linkup_status );
      return (linkup_status) ;
endfunction 

endclass
  

