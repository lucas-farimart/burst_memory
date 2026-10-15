#=====================
# Variaveis
#=====================
FLAGS = -64bit -sv -access +rwc -timescale 1ns/1ps
FILES = *.sv

#=====================
# COMANDOS
#=====================
.PHONY: all burst burst-gui debug clean

all: burst

burst:
	clear
	xrun $(FLAGS) $(FILES)

burst-gui:
	clear
	xrun $(FLAGS) $(FILES) -gui

clean:
	@rm -rf xcelium.d xrun.log sim.log
	@echo "Tudo limpo chefia"

debug:
	@grep "*E," xrun.log > erros.log
	@code erros.log