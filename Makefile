#=====================
# Variaveis
#=====================
FLAGS = -64bit -sv -access +rwc -timescale 1ns/1ns
BURST_FILES = -f run_burst.f
MULT_FILES  = -f run_mult.f

#=====================
# COMANDOS
#=====================
.PHONY: all elaborate burst burst-gui burst-mult debug clean

all: clean burst

elaborate:
	clear
	xrun -elaborate $(FLAGS) $(BURST_FILES)

burst:
	clear
	xrun $(FLAGS) $(BURST_FILES)

burst-gui:
	clear
	xrun $(FLAGS) $(BURST_FILES) -gui

burst-mult:
	clear
	xrun $(FLAGS) $(MULT_FILES) -gui

clean:
	@rm -rf xcelium.d xrun.log sim.log
	@echo "Tudo limpo chefia"

debug:
	@grep "*E," xrun.log > erros.log
	@code erros.log