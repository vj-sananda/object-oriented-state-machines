#!/bin/csh -f
#------------------------------
# usage: run.csh <test_name>
#    eg: run.csh test1
#------------------------------
vcs +v2k -sverilog -R tb.v $1.sv -l $1.out
