####################################################################
#Vlog tb file
VLOG_TOP = tb.v

####################################################################
VLOG_INC_DIR = +incdir+./

VCS_PLI_OPTS += -P ${NOVAS_HOME}/share/PLI/vcsd/LINUX/vcsd.tab \
		${NOVAS_HOME}/share/PLI/vcsd/LINUX/pli.a +vcsd 

VCS_COMPILE_PARMS += -Mupdate -y ./ +libext+.v +v2k -sverilog -ntb_opts svp -lca

#From Make command line: test=NOTEST
ifndef test
 test = test1.sv ;
endif
####################################################################


####################################################################
#  Targets
####################################################################
run: simv
	./simv -l sim.log +seed=`date +%N` +test=${test}
#	vcs -cov_text_report _root.db

####################################################################
#-ntb_opts svp : allows you to declare classes globally
#so can be used in modules, else only in program blocks

simv: ${test} $(VLOG_TOP) 
	vcs -R $(VCS_COMPILE_PARMS) $(VCS_PLI_OPTS) $(VLOG_INC_DIR) $(VLOG_TOP) ${test}

####################################################################
deb:
#	verdi -f files.f -f vlog.f $(VLOG_TOP) $(VLOG_INC_DIR)
	verdi program.sv $(VLOG_TOP) $(VLOG_INC_DIR)

####################################################################
clean:
	rm -rf *.log
	rm -rf simv*.daidir
	rm -rf simv*
	rm -rf csrc*
	rm -rf core
	rm -rf *.bck
	rm -rf sim.log
	rm -rf *.fsdb
	rm -rf verdiLog
	rm -rf *.fsdb
####################################################################
