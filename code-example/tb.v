//----------------------------------
// tb.v:
//------
// Top level verilog module
// instantiating test program and
// defining clock
//----------------------------------
`timescale 1ns/1ns 

module tb ;

   logic clk ;

   test test_program( clk ) ;

   //clk gen
   initial clk = 0;
   always  #5 clk = ~clk ;
   
endmodule // tb
