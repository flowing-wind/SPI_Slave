# SPI Slave testbench -- VCS + Verdi
# make lint | comp | run | wave | verdi | cov | regress | clean
# Everything is written under sim/<target>/ ; tb/ keeps only the sources.

# No trailing "# comment" on any assignment: make keeps the spaces before it.
SIM   := sim
# Paths as seen from sim/<target>/ , where every build runs.
SRCS  := ../../../rtl/spi_slave.v ../../tb_spi_slave.sv
TOP   := tb_spi_slave

TEST  ?= all
SEED  ?= 1
SEEDS ?= 1 2 3 4 5

# -timescale because rtl/spi_slave.v has none of its own.
VCS   := vcs -full64 -sverilog -timescale=1ns/1ps +warn=all
# Wave build only: full debug visibility slows simulation down.
DBG   := -debug_access+all
# fsm stays even though this design has no state machine: urg just warns
# "Fsm coverage shape is not there" and leaves the column blank.
CM    := -cm line+cond+fsm+tgl+branch+assert
CMC   := $(CM) -cm_hier cm_hier.cfg -cm_line contassign \
         -cm_cond allops+anywidth+event+tf -cm_tgl mda+structarr -cm_noconst
PLI   ?= -P $(VERDI_HOME)/share/PLI/VCS/LINUX64/novas.tab \
            $(VERDI_HOME)/share/PLI/VCS/LINUX64/pli.a

build = mkdir -p $(SIM)/$(1) && cd $(SIM)/$(1) && \
        $(VCS) $(2) $(SRCS) -o simv -Mdir=csrc -l comp.log

.PHONY: lint comp run wave verdi cov regress gls gls_all clean

lint:
	mkdir -p $(SIM)/lint && cd $(SIM)/lint && $(VCS) +lint=all,noVCDE \
	  -top spi_slave ../../../rtl/spi_slave.v -o lint.simv -Mdir=csrc -l lint.log

comp:
	$(call build,comp,)

run: comp
	mkdir -p $(SIM)/run && cd $(SIM)/run && ../comp/simv \
	  +TEST=$(TEST) +ntb_random_seed=$(SEED) -l run_$(TEST)_$(SEED).log
	@grep -E "checks =|coverage =" $(SIM)/run/run_$(TEST)_$(SEED).log
	@! grep -q FAIL $(SIM)/run/run_$(TEST)_$(SEED).log

wave:
	$(call build,wave,$(DBG) +define+FSDB_ON $(PLI))
	cd $(SIM)/wave && ./simv +TEST=wave +FSDB -l run.log

# -ssf alone leaves the hierarchy and source panes empty, hence -sverilog too.
verdi:
	cd $(SIM)/wave && verdi -sverilog $(SRCS) -ssf wave.fsdb &

# Design structure is written at compile time, test data at run time, both
# into simv.vdb -- passing -cm_dir on one side only splits them and urg then
# reports "Design not yet loaded".
cov:
	@mkdir -p $(SIM)/cov && echo "+tree $(TOP).dut" > $(SIM)/cov/cm_hier.cfg
	$(call build,cov,$(CMC))
	cd $(SIM)/cov && ./simv $(CM) -cm_name $(TEST)_$(SEED) \
	  +TEST=$(TEST) +ntb_random_seed=$(SEED) -l run.log
	cd $(SIM)/cov && urg -dir simv.vdb -report report -format both
	@echo "  report -> $(SIM)/cov/report/dashboard.html"

# One database, seeds told apart by -cm_name, so urg merges them.
regress:
	@mkdir -p $(SIM)/regress && echo "+tree $(TOP).dut" > $(SIM)/regress/cm_hier.cfg
	$(call build,regress,$(CMC))
	@rc=0; for s in $(SEEDS); do \
	  (cd $(SIM)/regress && ./simv $(CM) -cm_name seed_$$s \
	     +TEST=all +ntb_random_seed=$$s -l seed_$$s.log >/dev/null); \
	  if grep -q PASS $(SIM)/regress/seed_$$s.log; then echo "  seed $$s PASS"; \
	  else echo "  seed $$s FAIL -> $(SIM)/regress/seed_$$s.log"; rc=1; fi; \
	done; \
	cd $(SIM)/regress && urg -dir simv.vdb -report report -format both >/dev/null; \
	echo "  merged -> $(SIM)/regress/report/dashboard.html"; exit $$rc

# ---- Gate-level sim: Innovus netlist + SDF ----------------------------------
# spi_slave_lvs.v and spi_slave_minmax.sdf are copied from post/Innovus/outputs
# into tb/ ; paths below are as seen from sim/<target>/ like SRCS above.
# CORNER=max -> ss/125C/1.62V (setup side)   CORNER=min -> ff/0C/1.98V (hold side)
TSMC     ?= /home/yangh/project/PDK/TSMCHOME/digital
GATE_LIB := $(TSMC)/Front_End/verilog/tcb018gbwp7t_270a/tcb018gbwp7t.v
GATE_NET := ../../spi_slave_lvs.v
GATE_SDF := ../../spi_slave_minmax.sdf
GATE_TB  := ../../tb_spi_slave.sv
CORNER   ?= max
# -sdf      : annotate at compile time, no $sdf_annotate needed in the TB
# +neg_tchk : keep the negative setup/recovery limits instead of clamping to 0
GLS_OPT  := +neg_tchk -sdf $(CORNER):$(TOP).dut:$(GATE_SDF)
GLS_LOG  := $(SIM)/gls_$(CORNER)/run_$(TEST)_$(SEED).log

gls:
	mkdir -p $(SIM)/gls_$(CORNER) && cd $(SIM)/gls_$(CORNER) && \
	  $(VCS) $(GLS_OPT) -v $(GATE_LIB) $(GATE_NET) $(GATE_TB) \
	    -o simv -Mdir=csrc -l comp.log && \
	  ./simv +TEST=$(TEST) +ntb_random_seed=$(SEED) -l run_$(TEST)_$(SEED).log
	@grep -E "checks =" $(GLS_LOG)
	@echo "  timing violations = $$(grep -c 'Timing violation' $(GLS_LOG))"
	@! grep -q -E "FAIL|Timing violation" $(GLS_LOG)

gls_all:
	$(MAKE) gls CORNER=max
	$(MAKE) gls CORNER=min
	
clean:
	rm -rf $(SIM)
