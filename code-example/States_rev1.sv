//$Id: States_rev1.sv,v 1.1 2011/06/13 21:13:44 vsananda Exp $
/*
  Description:
  Represents the Finite State Machine used in
  Infiniband (Phy) Link training.

  The FSM relies on OOP polymorphism to build an implicit
  dispatch table.(We don't have ptrs to functions in Vera).
  For details on this technique refer to any paper on
  Object Oriented state machines.

  Relies on the Rx and Tx layer to actually drive the bytes
  on the wire. Therefore will work transparently with 1X,4X
  and 12X links.
 */

#define DEFAULT_POLLING_ACTIVE_TIMEOUT  4000
#define DEFAULT_POLLING_QUIET_TIMEOUT   4000
#define DEFAULT_CONFIG_IDLE_TIMEOUT    40000
#define DEFAULT_TIMEOUTCNT_LIMIT           4

typedef class  Polling_Active  ;
typedef class  Polling_Quiet   ;
typedef class  Config_Debounce ;
typedef class  Config_Rcvr     ;
typedef class  Config_Wait     ;
typedef class  Config_Idle     ;
typedef class  Linkup_State    ;
typedef class  Recovery_Retrain ;
typedef class  Recovery_Wait  ;

enum {OS_TS1,OS_TS2}  OSType ;

virtual class Base_State ;

OrderedSet_TS2     ts2 ;
OrderedSet_TS1     ts1 ;
OrderedSet         ts ;
    
OSType  TsTypeTx,TsTypeRx;
    
integer CmdLoop,TxCmd ;
integer StateCnt=0;
    
 string msg ;

 string StateDescr ;

  //Number of times state entered
  integer EntryCnt=0;

  //Number of times expect state to be entered
  //We dont expect a link to retrain.
  //Check active if value other than -1
  integer ExpectedEntryCnt=-1;
  
  integer Timeout ; //Time spent in a state (in ns)
  integer TimeoutCnt=0 ; //Number of times , timed out 
  integer TimeoutCntLimit=DEFAULT_TIMEOUTCNT_LIMIT ;//Limit to check against, before fatal error
  
  integer TransitionCnt ;
  integer CmdCnt = 1;

  integer LinkActive = FALSE ;

  //Reference to Phy
  Phy  PhyLink ;
  bit  PhyEndpoint ;

  Base_State NextState ;
  Base_State TimeoutState ;    
  
  task sendTS(OrderedSet ts) ;
      PhyLink.send(ts,PhyEndpoint);
   endtask

  virtual function Base_State processPkt();

  virtual task commands();

  virtual function integer loop () ;

  virtual function Base_State procTimeout ();

  task setTimeoutCntLimit(integer ival);
    TimeoutCntLimit = ival ;
  endtask // setTimeoutCntLimit

  task chkTimeoutCnt() ;
    if (TimeoutCnt > TimeoutCntLimit)
      $display("Endpoint%0d::%s, Timed out > %0d times",
	       PhyEndpoint,StateDescr,TimeoutCntLimit);
  endtask
  
  task display() ;
      $display("Endpoint%d::%s",PhyEndpoint,StateDescr);
  endtask

  task incEntryCnt() ;
    EntryCnt++;
    if ((ExpectedEntryCnt != EntryCnt) && (ExpectedEntryCnt != -1) )
      $display("Endpoint%0d::%s entered %0d times (Exp=%0d)",
               PhyEndpoint,StateDescr,EntryCnt,ExpectedEntryCnt);
  endtask
  
endclass

class TS_State extends Base_State ;

  task new(Phy _phy,
           OSType ts_type_tx,
           OSType ts_type_rx ) ;

    PhyLink = _phy ;
      
    CmdLoop=TRUE;

    TsTypeTx = ts_type_tx ;
    TsTypeRx = ts_type_rx ;    
    
    case (TsTypeTx) 
      OS_TS1: begin
	 ts1 = new ; ts =ts1;
      end
      
      OS_TS2: begin 
	 ts2 = new ; ts =ts2;
      end
      
    endcase

  endtask // new
      

  task commands() ;
      
    CmdLoop=TRUE;
    while(CmdLoop & TxCmd)
      repeat(CmdCnt)
        sendTS(ts);
      
  endtask
  
  function Base_State processPkt() ;

    Ordered_Set rx_ts ;
      
    StateCnt=0;
    while(1)
      if(PhyLink.get(rx_ts,PhyEndpoint))
	begin
           if (rx_ts.getType() == TsTypeTx ||
               rx_ts.getType() == TsTypeRx  ) StateCnt++;
           if (StateCnt == TransitionCnt) break ;
	end
      else
        StateCnt=0;

    //Transition to next state
    processPkt = NextState;
    NextState.incEntryCnt();
    CmdLoop = FALSE ;

  endfunction // Base_State

  function integer loop() ;
      
    loop=1;
    LinkActive=FALSE;
      
  endfunction

  //Can a system verilog function have time
  function Base_State procTimeout() ;

    repeat(Timeout) @(posedge clk);
//    delay(Timeout);
      
    $display("Endpoint%0d::%s Timeout",Endpoint,StateDescr);    
    procTimeout = TimeoutState;
    CmdLoop = FALSE ;
    TimeoutCnt++;
    chkTimeoutCnt();

  endfunction // Base_State
      
endclass

  class Polling_Active extends TS_State ;
      
      task new(Phy _phy) ;
      super.new(_phy,OS_TS1,OS_TS2);
      Timeout = DEFAULT_POLLING_ACTIVE_TIMEOUT ;
      TransitionCnt = 16;
      TxCmd=TRUE;
      CmdCnt = 16;
      StateDescr = "Polling Active";
      endtask // new
      
  endclass
    

 class Polling_Quiet  extends TS_State ;

  task new(Phy _phy) ;
      
    super.new(_phy,OS_TS1,OS_TS2);
    Timeout = DEFAULT_POLLING_QUIET_TIMEOUT ;
    TransitionCnt = 16;
    TxCmd=FALSE;
    StateDescr = "Polling Quiet";    
  endtask // new
 endclass
	

 class Config_Debounce extends TS_State ;
 
   task new(Phy _phy) ;
    super.new(_phy,OS_TS1,OS_TS2);
    Timeout = DEFAULT_POLLING_QUIET_TIMEOUT ;
    TransitionCnt = 16;
    TxCmd=TRUE;
    CmdCnt = 16;    
    StateDescr = "Config Debounce";        
  endtask // new
 endclass

 class Config_Rcvr extends TS_State ;
 
  task new(Phy _phy) ;
      
    super.new(_phy,OS_TS1,OS_TS2);
    Timeout = DEFAULT_POLLING_QUIET_TIMEOUT ;
    TransitionCnt = 16;
    TxCmd=TRUE;
    CmdCnt = 16;    
    StateDescr = "Config Rcvr";    

  endtask // new
 endclass
	
 class Recovery_Retrain extends Config_Rcvr ;
      
   task new(Phy _phy) ;
    super.new(_phy);
    StateDescr = "Recovery Retrain";
    TransitionCnt = 8;    
   endtask // new
 endclass

 class Config_Wait extends TS_State ;
      
   task new(Phy _phy) ;
      
    super.new(_phy,OS_TS2,OS_TS2);
    CmdCnt = 32 ;
    Timeout = DEFAULT_POLLING_QUIET_TIMEOUT ;
    TransitionCnt = 16;
    TxCmd=TRUE;
    CmdCnt = 16;    
    StateDescr = "Config Wait";    
   endtask // new
 endclass

class Recovery_Wait extends Config_Wait ;
      
  task new(Phy _phy) ;
      
    super.new(_phy);
    StateDescr = "Recovery Wait";
    TransitionCnt = 8;    
  endtask // new
endclass

class Config_Idle extends Base_State ;

  task new(Phy _phy) ;
      
    PhyLink = _phy ;
    TransitionCnt = 16 ;
    StateDescr = "Config Idle";
    TxCmd = TRUE ;
    Timeout = DEFAULT_CONFIG_IDLE_TIMEOUT ;
    CmdCnt = 16 ;
  endtask

  task commands();
      
    CmdLoop=TRUE;
    while(CmdLoop & TxCmd)
      repeat(CmdCnt*4)
        @(posedge clk);
      
  endtask

  function Base_State processPkt() ;
      
   OrderedSet rx_ts ;
				    
    while(1) {

//       fork
//         if(RxLayer.dqOSPkt(rpkt,LaneId))  {
//           if (rpkt.getOtype() == OS_TS1)  {
//             sprintf(msg,"Lane%0d:*** Got TS1 Ordered Set in IdleDetect state",
//                  LaneId);
//             rpt.WRN(msg);
//           }
//         }
//       @(posedge CLOCK);
//       join any
//       terminate;

      if (PhyLink.get(rx_ts) > TransitionCnt) break ;
      @(posedge clk);
    }//while

    while(RxLayer.dqOSPkt(rpkt,LaneId,TRUE)) {
      //      printf("*** Draining OS Pkt Queue ***\n");
    } //Drain OS pkt Q
    processPkt = NextState ;
    NextState.incEntryCnt();
    CmdLoop = FALSE ;
  }//function    

  function integer loop() {
    loop=1;
  }
  
  function Base_State procTimeout() {
    delay(Timeout);
    sprintf(msg,"Lane%0d:%s Timeout",LaneId,StateDescr);
    rpt.WRN(msg);
    procTimeout = TimeoutState ;
    CmdLoop = FALSE ;
    TimeoutCnt++;
    chkTimeoutCnt();
  }//function

}//class

class Recovery_Idle extends Config_Idle {

  task new(DWORD portid) {
    super.new(portid);
    StateDescr = "Recovery Idle";
  }//new       
}//class

class Linkup_State extends Base_State {

  integer DummySemId;
  
  task new(DWORD portid) {
    this.PortId = portid;
    LaneId=32'h0000_000f & portid;
    StateDescr = "Link Up";
    DummySemId = alloc(SEMAPHORE,0,1,0);
  }
  
  task commands(Base_Tx_Layer TxLayer ) { }

  function Base_State processPkt(Base_Rx_Layer RxLayer) {
    Base_Pkt rpkt;
    
    while(1)
      if(RxLayer.dqOSPkt(rpkt,LaneId))  {
        if (rpkt.getOtype() == OS_TS1 ||
            rpkt.getOtype() == OS_TS2  ) 
        break ;
      }

    //Transition to next state
    processPkt = NextState;
    NextState.incEntryCnt();
    CmdLoop = FALSE ;
    
  }//function    

  function integer loop() {
    loop=2;
    LinkActive=TRUE;
  }//function loop
  
  function Base_State procTimeout() { semaphore_get(WAIT,DummySemId,1); }
    
}//class

class Link_FSM {

  Base_Rx_Layer RxLayer;
  Base_Tx_Layer TxLayer;
  
  Base_State FsmState ;
  
  Polling_Active  PollingActive ;
  Polling_Quiet   PollingQuiet ;
  Config_Debounce ConfigDebounce;
  Config_Rcvr     ConfigRcvr ;
  Config_Wait     ConfigWait ;
  Config_Idle     ConfigIdle ;
  Linkup_State    LinkUp ;
  Recovery_Retrain RecoveryRetrain;
  Recovery_Wait    RecoveryWait ;
  Recovery_Idle    RecoveryIdle ;
  
  OrderedSet_TS1_Pkt     ts1 =new;
  OrderedSet_TS_Pkt      ts ;
  event LinkUpEvent ;
  integer PortId ;
  integer Enable = TRUE ;
  integer StateChangeCnt=0;//Increments with every state transition
  
  task setTxLayer(Base_Tx_Layer ilayer) {TxLayer = ilayer;}
  task setRxLayer(Base_Rx_Layer ilayer) {RxLayer = ilayer;}
    
  task new (DWORD portid) {

    PollingActive = new (portid);
    PollingQuiet  = new (portid);
    ConfigDebounce= new (portid);
    ConfigRcvr    = new (portid);
    ConfigWait    = new (portid);
    ConfigIdle    = new (portid);
    LinkUp        = new (portid);
    RecoveryRetrain= new (portid);
    RecoveryWait= new (portid);
    RecoveryIdle= new (portid);
    
    PortId = portid;
    
    //Initial State 
    FsmState = PollingActive ;

    //Setup transitions
    PollingActive.NextState    = ConfigDebounce ;
    PollingActive.TimeoutState = PollingQuiet   ;

    PollingQuiet.NextState     = ConfigDebounce ;
    PollingQuiet.TimeoutState  = PollingActive  ;

    ConfigDebounce.NextState   = ConfigRcvr     ;
    ConfigDebounce.TimeoutState= ConfigRcvr     ;

    ConfigRcvr.NextState       = ConfigWait     ;
    ConfigRcvr.TimeoutState    = PollingActive  ;

    ConfigWait.NextState       = ConfigIdle     ;
    ConfigWait.TimeoutState    = PollingActive  ;

    ConfigIdle.NextState       = LinkUp         ;
    ConfigIdle.TimeoutState    = PollingActive  ;

    LinkUp.NextState           = RecoveryRetrain  ;
    LinkUp.TimeoutState        = LinkUp         ;

    RecoveryRetrain.NextState  = RecoveryWait ;
    RecoveryRetrain.TimeoutState  = PollingActive  ;
    
    RecoveryWait.NextState  = RecoveryIdle ;
    RecoveryWait.TimeoutState  = PollingActive  ;
    
    RecoveryIdle.NextState  = LinkUp ;
    RecoveryIdle.TimeoutState  = PollingActive  ;
    
  }//task

  task resetTimeoutCnts() {
    PollingActive.TimeoutCnt = 0;
    PollingQuiet.TimeoutCnt = 0;
    ConfigDebounce.TimeoutCnt = 0;
    ConfigRcvr.TimeoutCnt = 0;
    ConfigWait.TimeoutCnt = 0;
    ConfigIdle.TimeoutCnt = 0;
    LinkUp.TimeoutCnt = 0;
    RecoveryRetrain.TimeoutCnt = 0;
    RecoveryWait.TimeoutCnt = 0;
    RecoveryIdle.TimeoutCnt = 0;    
  }//end task
  
  //Run FSM
  task run () {
    Base_Pkt bpkt;

      while(FsmState.loop() && Enable ) {

        fork
          
        FsmState.commands(TxLayer) ;

        FsmState.display();

        if (FsmState.loop() == 2) {
          resetTimeoutCnts();
          trigger(ONE_BLAST,LinkUpEvent);
        }
        
        {
        fork
          FsmState =  FsmState.processPkt(RxLayer);
          FsmState =  FsmState.procTimeout();
        join any
         disable fork ;
        }

        StateChangeCnt++;
        
        join
           
      }//end while

  }//end task

  function integer getLinkActive() {
    getLinkActive = FsmState.LinkActive ;
  }

  function integer getStateChangeCnt() {
    getStateChangeCnt=StateChangeCnt;
  }
  
  task retrain() {
    ts=ts1 ;
    ts.setInPort(32'h0000_000f&PortId);
    FsmState.sendTS(TxLayer,ts);
  }
  
}//end class

#endif

//$Log: States_rev1.sv,v $
//Revision 1.1  2011/06/13 21:13:44  vsananda
//Initial revision
//
//Revision 1.36  2002/10/04 22:46:22  vsananda
//added description header
//
//Revision 1.35  2002/10/04 22:43:54  vsananda
//added description header
//
//Revision 1.34  2002/08/09 03:38:07  vsananda
//added Recovery states
//
//Revision 1.33  2002/07/23 21:49:46  vsananda
//transition count between states changed to 16
//
//Revision 1.32  2002/07/23 20:09:46  vsananda
//added property StateChangeCnt, which increments with each state change
//
//Revision 1.31  2002/07/22 22:20:24  vsananda
//added timeout limit check. If any state times out more than TimeoutCntLimit,
//before reaching LinkUp. Fatal error signalled.
//
//Revision 1.30  2002/06/18 19:39:07  vsananda
//sync link up event changed from HAND_SHAKE to ONE_BLAST.
//Tx 64 idle cycles before linkup
//
//Revision 1.29  2002/06/03 22:18:01  vsananda
//support checking number of times a particular state is entered
//
//Revision 1.28  2002/04/22 16:07:46  vsananda
//added Enable property to allow shutting down of
//constant link monitoring
//
//Revision 1.27  2002/04/16 22:54:07  vsananda
//debug printfs
//
//Revision 1.26  2002/04/09 16:39:52  vsananda
//cleanup
//
//Revision 1.25  2002/04/09 16:26:37  vsananda
//moved Port_FSM class to a separate file
//
//Revision 1.24  2002/01/18 19:24:57  vsananda
//moved rsv and free link calls to send() method of Tx_Layer
//
//Revision 1.23  2002/01/07 22:21:54  pallen
//Changed Ordered Set in IdleDetect state check to only check for TS1.
//
//Revision 1.22  2001/12/11 23:07:04  vsananda
//in all the WaitTS1 states, it
//is really wait for TS1 or TS2
//as per the IB spec
//
//Revision 1.21  2001/12/11 22:48:05  vsananda
//fixed bugs in transition from timeout states
//
//Revision 1.20  2001/12/11 18:21:40  vsananda
//cleanup
//
//Revision 1.19  2001/12/11 17:38:04  vsananda
//added states without breaking anything
//
//Revision 1.17  2001/11/29 23:18:13  vsananda
//chkpt
//
//Revision 1.16  2001/11/29 16:40:47  vsananda
//fix for drv conflict between Skp send loop and link training
//
//Revision 1.15  2001/11/29 00:07:08  vsananda
//chkpt
//
//Revision 1.14  2001/11/13 21:49:26  vsananda
//reduced number of idle cycles from 100 to 25, before linkup
//
//Revision 1.13  2001/10/15 16:09:53  vsananda
//cleanup
//
//Revision 1.12  2001/10/10 15:00:41  vsananda
//updates for bringing up links on both Quills
//
//Revision 1.11  2001/10/09 21:30:58  vsananda
//work with idle count code in Rx layer
//
//Revision 1.10  2001/10/09 21:03:51  vsananda
//idle cnt functionality moved to Rx Layer
//
//Revision 1.9  2001/10/09 19:32:16  vsananda
//new Link FSM with Rx and Tx layer handles as interface

