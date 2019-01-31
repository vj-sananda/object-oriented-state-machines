module hello ;


   reg a ,b , c;

   wire r_w = a ? b : c ;
   reg 	r ;
   
   always_comb
     if ( a )
       r = b ;
     else
       r = c ;

   initial
     begin
	b = 1 ;
	c = 0 ;
	#100 ;

	$display ( "r_w = %x", r_w );

	$display ( "r = %x", r );
	
	$finish;
     end // initial begin

endmodule // hello


   
   
