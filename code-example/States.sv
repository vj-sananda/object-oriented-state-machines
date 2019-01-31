//---------------------------------------------------
// States.sv:
//-----------
// Class descriptions of all the states involved
// in link bring up. All these states derive from the
// Base_State class.
// The class definition for a specific state,
// implements the virtual tasks which define the
// behavior of the state machine in that state.
//---------------------------------------------------

`define TRUE  1
`define FALSE 0

`define  DEFAULT_TIMEOUT  2000

`define RX_DEBUG_INFO 	 $display($stime,"::Endpoint%d::%s::Receive(), Rx %s %s (%d)", \
        		  PhyEndpoint,StateDescr,ts_type.name(),rx_ts.LinkNum.name(),StateCnt);
	 
//List of States involved in Normal link bring up.
typedef class  Detect_State ;
typedef class  Polling_Active_State  ;
typedef class  Polling_Configuration_State   ;
typedef class  Configuration_LinkLane_State ;
typedef class  Configuration_Complete_State ;
typedef class  Configuration_Idle_State ;
typedef class  L0_State ;             

virtual class Base_State ;

 OrderedSet_TS2     ts2 ;
 OrderedSet_TS1     ts1 ;
 OrderedSet         ts ;
    
  int TransmitCnt ;
    
  string StateDescr ;

  int Timeout = `DEFAULT_TIMEOUT ; //Time spent in a state (in ns)
  
  int TransitionCnt ;
  int StateCnt ;

  //Reference to Phy
  Phy  PhyLink ;

  //Value for Upstream nodes (Root Complex, switches) = 0
  //Value for Target devices (downstream nodes) = 1
  bit  PhyEndpoint ;

  Base_State NextState ;
  Base_State TimeoutState ;    
  
  task send(OrderedSet ts) ;
      PhyLink.put(ts,PhyEndpoint);
   endtask

  virtual task updateLinkStatus( ref logic link_status );
      link_status = 0;
  endtask 

  virtual task Transmit ();
  endtask 

  virtual task Receive (ref Base_State _state);
  endtask 
      
  virtual task ReceiveTimeout (ref Base_State _state);

    repeat(Timeout) @(posedge clk);
      
    $display($stime,"::Endpoint%0d::%s Timeout",PhyEndpoint,StateDescr);    
    _state = TimeoutState;
      
  endtask 

  task display() ;
      $display($stime,"::Endpoint%d::%s",PhyEndpoint,StateDescr);
  endtask
  
endclass

//In this logical transactional model
//transition to next state once we
//know there is another endpoint connected.
class Detect_State extends Base_State ;

 function new (Phy _phy,
               bit _endpoint ) ;

    PhyLink     = _phy ;
    PhyEndpoint = _endpoint ;  
  
    PhyLink.setConnection(PhyEndpoint);

      StateDescr = "Detect" ;
      
 endfunction 

task Receive(ref Base_State _state);

    while(1)
      begin
	 @(posedge clk);

	 //Are both ends connected ?
	 if (PhyLink.Connection == 2'b11) break ;
      end
      
    _state = NextState;
      
endtask 

task Transmit();
      //No Ordered sets transmitted in this state
endtask 

endclass


class Polling_Active_State extends Base_State ;

 function new (Phy _phy,
               bit _endpoint ) ;

    PhyLink     = _phy ;
    PhyEndpoint = _endpoint ;  
  
    PhyLink.setConnection(PhyEndpoint);

    TransitionCnt  =    8 ;
    TransmitCnt = 1024 ;
    StateDescr = "Polling Active";
      
 endfunction 

task Receive(ref Base_State _state);

    OrderedSet rx_ts ;
    OSType ts_type ;
      
    StateCnt=0;

    while(1)
      begin
	 
	 @(posedge clk);

	 PhyLink.get(rx_ts,PhyEndpoint);	   
	 ts_type = rx_ts.getType();
	 
	 if ( (rx_ts.getType() == TS1 || rx_ts.getType() == TS2 ) && 
	      rx_ts.isLinkNumPAD() && rx_ts.isLaneNumPAD() )
	   StateCnt++;
	 else
	   //Have to get a continuous set	   
           StateCnt=0;

	 //`RX_DEBUG_INFO
	   
         if (StateCnt == TransitionCnt) break;
	 
      end // while (1)

    //Transition to next state
    _state = NextState;
      
endtask 

task Transmit();

    //Transmit 1024 TS1 with Link and Lane Num set to PAD
      ts1 = new ;
      ts1.setLinkNum(PAD);
      ts1.setLaneNum(PAD);
      
      repeat (TransmitCnt)
	begin
           send(ts1);
	   @(posedge clk);
	end
      
endtask 

endclass  


class Polling_Configuration_State extends Base_State ;

 function new (Phy _phy,
               bit _endpoint ) ;

    PhyLink     = _phy ;
    PhyEndpoint = _endpoint ;  
  
    PhyLink.setConnection(PhyEndpoint);

    TransitionCnt  =    8 ;
    TransmitCnt = 16 ;

      StateDescr = "Polling Configuration";
      
 endfunction 

task Receive(ref Base_State _state);

    OrderedSet rx_ts ;
    OSType ts_type ;
      
    StateCnt=0;

    while(1)
      begin
	 @(posedge clk);

	 PhyLink.get(rx_ts,PhyEndpoint);	   
	 ts_type = rx_ts.getType();
	 
	 if ( (rx_ts.getType() == TS2 ) && 
	      rx_ts.isLinkNumPAD() && rx_ts.isLaneNumPAD() )
	    begin
	       StateCnt++;
	       //After every TS2 Received, Transmit N TS2s
	       //as per specification N=16
	       Transmit();
	    end
	 else
	   //Have to get a continuous set	   
           StateCnt=0;

	 //`RX_DEBUG_INFO
	 
         if (StateCnt == TransitionCnt) break ;

      end // while (1)

    //Transition to next state
    _state = NextState;
      
endtask 

task Transmit();

      ts2 = new ;
      ts2.setLinkNum(PAD);
      ts2.setLaneNum(PAD);
      
      repeat (TransmitCnt)
	begin
           send(ts2);
	   @(posedge clk);
	end
      
endtask 

endclass  

class Configuration_LinkLane_State extends Base_State ;

 function new (Phy _phy,
               bit _endpoint ) ;

    PhyLink     = _phy ;
    PhyEndpoint = _endpoint ;  
  
    PhyLink.setConnection(PhyEndpoint);

    TransitionCnt  =    2 ;
    TransmitCnt    =   16 ;

    StateDescr = "Configuration LinkLane" ;
      
 endfunction 

task Receive(ref Base_State _state);

    OrderedSet rx_ts ;
    OSType ts_type ;
      
    StateCnt=0;

    while(1)
      begin
	 @(posedge clk);

	 PhyLink.get(rx_ts,PhyEndpoint);	   
	 ts_type = rx_ts.getType();
	 
	 if ( (rx_ts.getType() == TS1 ) && 
	      ~rx_ts.isLinkNumPAD() && ~rx_ts.isLaneNumPAD() )
	   StateCnt++;
	 else
	   //Have to get a continuous set	   
           StateCnt=0;

	 //`RX_DEBUG_INFO
	 
         if (StateCnt == TransitionCnt) break ;

      end // while (1)

    //Transition to next state
    _state = NextState;
      
endtask 

task Transmit();

      ts1 = new ;
      ts1.setLinkNum(NUM);
      ts1.setLaneNum(NUM);
      
      repeat (TransmitCnt)
	begin
           send(ts1);
	   @(posedge clk);
	end
      
endtask 

endclass  

class Configuration_Complete_State extends Base_State ;

 function new (Phy _phy,
               bit _endpoint ) ;

    PhyLink     = _phy ;
    PhyEndpoint = _endpoint ;  
  
    PhyLink.setConnection(PhyEndpoint);

    TransitionCnt  =    8 ;
    TransmitCnt = 16 ;

      StateDescr = "Configuration Complete" ;

 endfunction 

task Receive(ref Base_State _state);

    OrderedSet rx_ts ;
    OSType ts_type ;
      
    StateCnt=0;

    while(1)
      begin
	 @(posedge clk);

	 PhyLink.get(rx_ts,PhyEndpoint);	   
	 ts_type = rx_ts.getType();
	 
	 if ( (rx_ts.getType() == TS2 ) && 
	      ~rx_ts.isLinkNumPAD() && ~rx_ts.isLaneNumPAD() )
	   StateCnt++;
	 else
	   //Have to get a continuous set	   
           StateCnt=0;

	 
         if (StateCnt == TransitionCnt) break ;

      end // while (1)

    //Transition to next state
    _state = NextState;
      
endtask 

task Transmit();

      //Behavior is different if you are an upstream
      //or downstream node.
      //Upstream node initiates setting LinkWidth by
      //setting a numeric value in the LinkNum field
      ts2 = new ;
      ts2.setLinkNum(NUM);
      ts2.setLaneNum(NUM);
      
      repeat (TransmitCnt)
	begin
           send(ts2);
	   @(posedge clk);
	end
      
endtask 

endclass  
  

class Configuration_Idle_State extends Base_State ;

 function new (Phy _phy,
               bit _endpoint ) ;

    PhyLink     = _phy ;
    PhyEndpoint = _endpoint ;  
  
    PhyLink.setConnection(PhyEndpoint);

    TransitionCnt  =    2 ;
    TransmitCnt = 16 ;

      StateDescr = "Configuration Idle" ;
      
 endfunction 

task Receive(ref Base_State _state);

    OrderedSet rx_ts ;
    OSType ts_type ;
      
    StateCnt=0;

    while(1)
      begin
	 @(posedge clk);

	 PhyLink.get(rx_ts,PhyEndpoint);	   
	 ts_type = rx_ts.getType();
	 
	 if  (rx_ts.getType() == IDLE )
	   StateCnt++;
	 else
	   //Have to get a continuous set	   
           StateCnt=0;

         if (StateCnt == TransitionCnt) break ;

      end // while (1)

    //Transition to next state
    _state = NextState;
      
endtask 

task Transmit();

      Idle idle = new ;
      
      repeat (TransmitCnt)
	begin
           send(idle);
	   @(posedge clk);
	end
      
endtask 

endclass  
  
class L0_State extends Base_State ;

 function new (Phy _phy,
               bit _endpoint ) ;

    PhyLink     = _phy ;
    PhyEndpoint = _endpoint ;  
  
    PhyLink.setConnection(PhyEndpoint);

    TransitionCnt  =    2 ;
    TransmitCnt = 16 ;

      StateDescr = "L0" ;
      
 endfunction 

task Receive(ref Base_State _state);

    OrderedSet rx_ts ;
    OSType ts_type ;
      
    StateCnt=0;

    while(1)
      begin
	 @(posedge clk);

	 PhyLink.get(rx_ts,PhyEndpoint);	   
	 ts_type = rx_ts.getType();
	 
      end // while (1)

    //Transition to next state
    _state = NextState;
      
endtask 

task Transmit();

      Idle idle = new ;
      
      repeat (TransmitCnt)
	begin
           send(idle);
	   @(posedge clk);
	end
      
endtask 

task ReceiveTimeout (ref Base_State _state);
endtask 

task updateLinkStatus( ref logic link_status );
      $display($stime,"::Endpoint%d::L0 , Link up",PhyEndpoint);      
      link_status = 1'b1;
endtask 

endclass  
  

