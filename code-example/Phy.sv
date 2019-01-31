//-----------------------------------------------
//Phy.sv:
//-------
//Abstract model of a physical connection
//between 2 PCI-express endpoints
//
//The endpoints have IDs of 0 & 1.
//Queues are used to exchange PCI-e packets.
//Transmitting a packet on the link
//is equivalent to putting it on a Queue.
//The receiver pops (or gets) the packet from
//the Queue. Set of 2 Queues indexed by the
//Endpoint ID (0,1) for each Endpoint to
//transmit and receive. 
//
//Endpoint 0 pushes to Q[0] and pulls from Q[1].
//Endpoint 1 pushes to Q[1] and pulls from Q[0]. 
//-----------------------------------------------

class Phy ;

//Connection status, will be 2'b11
//when both Endpoints connected
logic [1:0] Connection ;

//Transmit & Receive Queues
mailbox Q[2] ;

function new ;
      //Queues have unbounded depth,
      //reason for 0 in constructor.
      Q[0] = new(0) ;
      Q[1] = new(0) ;
      Connection = 2'b0;
endfunction

task setConnection ( bit _endpoint ) ;
      Connection[_endpoint] = 1'b1;
endtask 

task put (OrderedSet ts, bit _endpoint) ;
      Q[_endpoint].try_put(ts);
endtask 

task get (ref OrderedSet ts, bit _endpoint) ;
      Q[~_endpoint].get(ts);
endtask

//Flush receive Q
task flush (bit _endpoint);
      int j;
      OrderedSet ts;

      for (j=0;j<Q[~_endpoint].num();j++)
	Q[~_endpoint].get(ts);
      
endtask 

endclass
  
