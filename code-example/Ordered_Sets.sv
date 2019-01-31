//---------------------------------------------
// Ordered_Sets.sv:
//------------------
// Class definition of Ordered sets, which
// are collection of symbols exchanged between
// the 2 PCIe devices for link bring up.
// Since only the interactions at the logical
// layer are of interest, we omit details of 
// the exact sequence of symbols making up each
// ordered set. Only the type of ordered set
// is relevant.
//---------------------------------------------

//OSType: Ordered Set Type
typedef enum {TS1,TS2,IDLE,OTHER}  OSType ;

//OSChar: Ordered Set Character
typedef enum {PAD,NUM}  OSChar ;

virtual class OrderedSet ;

OSChar LinkNum ;
OSChar LaneNum ;

virtual function OSType getType() ;
endfunction 

//Returns true if LinkNum field is PAD character
function logic isLinkNumPAD();
      return ( LinkNum == PAD );
endfunction 

//Returns true if LaneNum field is PAD character
function logic isLaneNumPAD();
      return ( LaneNum == PAD );
endfunction 

task setLinkNum (OSChar _linknum);
      LinkNum = _linknum;
endtask 

task setLaneNum (OSChar _lanenum);
      LaneNum = _lanenum;
endtask 
      
endclass
  
class OrderedSet_TS1 extends OrderedSet ;

 function OSType getType();
      return (TS1) ;
 endfunction
      
endclass
	
class OrderedSet_TS2 extends OrderedSet ;

 function OSType getType();
      return (TS2) ;
 endfunction
      
endclass

class Idle extends OrderedSet ;

 function OSType getType();
      return (IDLE) ;
 endfunction
      
endclass
  
