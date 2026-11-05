#================================================================
# synth.tcl - Genus synthesis script
# Alvo: 500 MHz (período 2.0 ns)
# Projeto: memory_ctrl + booth_radix4 (tb_memory_mult)
#================================================================

#----------------------------------------------------------------
# 0. Variaveis de projeto (AJUSTE AQUI)
#----------------------------------------------------------------
set PROJECT      "mult_ctrl"
set TOP          "../tb/tb_memory_mult"    ;# ou o top real de sintese
set RTL_DIR      "../rtl"
set OUT_DIR      "./outputs"
set LIB_DIR      "/pdks/gpdk045_v_6_0/gsclib045_all_v4_4/gsclib045_lvt/timing"

# Lista de arquivos RTL (ordem importa: dependências primeiro)
set RTL_FILES [list \
    "$RTL_DIR/mem_ctrl.sv" \
    "$RTL_DIR/booth_radix4.sv" \
    "$RTL_DIR/tb_mem_mult.sv" \
]

# Bibliotecas de células (ajuste para sua tecnologia, ex.: 28nm, 65nm)
set LIB_FILES [list \
    "$LIB_DIR/fast_vdd1v0_basicCells_lvt.lib" \
    "$LIB_DIR/fast_vdd1v2_basicCells_lvt.lib" \
]
set LEAF_LIBS   [list "fast_vdd1v0_basicCells_lvt" "fast_vdd1v2_basicCells_lvt"]

#----------------------------------------------------------------
# 1. Setup do Genus
#----------------------------------------------------------------
set_db / .init_lib_search_path $LIB_DIR
set_db / .library $LIB_FILES
set_db / .lef_library {}          ;# preencha se for fazer P&R depois

# Modo de sintese
set_db / .syn_generic_effort    high
set_db / .syn_map_effort        high
set_db / .syn_opt_effort        high
set_db / .dp_analytical_opt     extreme

# Report settings
set_db / .report_timing_format  {instance arc cell load delay arrival slew required slack}
set_db / .max_cpus_per_server   8

#----------------------------------------------------------------
# 2. Ler RTL
#----------------------------------------------------------------
foreach f $RTL_FILES {
    read_hdl -sv $f
}

# Definir top
elaborate $TOP

# Checagens iniciais
check_design -unresolved

#----------------------------------------------------------------
# 3. Constraints SDC (500 MHz)
#----------------------------------------------------------------
# Clock principal: 2.0 ns = 500 MHz
create_clock -name clk -period 2.0 -waveform {0.0 1.0} [get_ports clk]

# Skew/jitter (ajuste conforme sua arvore de clock alvo)
set_clock_uncertainty -setup 0.10 [get_clocks clk]
set_clock_uncertainty -hold  0.05 [get_clocks clk]

# Latência de clock (se não for CTS ainda, deixe 0)
set_clock_latency -source 0.0 [get_clocks clk]
set_clock_latency         0.0 [get_clocks clk]

# Transition time
set_clock_transition 0.10 [get_clocks clk]

# I/O delays (ajuste conforme o ambiente do bloco)
set_input_delay  -clock clk -max 0.5 [remove_from_collection [all_inputs] [get_ports clk]]
set_input_delay  -clock clk -min 0.2 [remove_from_collection [all_inputs] [get_ports clk]]
set_output_delay -clock clk -max 0.5 [all_outputs]
set_output_delay -clock clk -min 0.2 [all_outputs]

# Driving cell / load (ajuste com sua biblioteca)
set_driving_cell -lib_cell BUF_X4 -pin Z [remove_from_collection [all_inputs] [get_ports clk]]
set_load 0.05 [all_outputs]

# Reset assíncrono (não é clock)
set_false_path -from [get_ports rstn]

# Se enb_a/enb_b são entradas de controle sem relação com clk (opcional)
# set_false_path -from [get_ports {enb_a enb_b}]

#----------------------------------------------------------------
# 4. Compilar
#----------------------------------------------------------------
syn_generic
syn_map
syn_opt

#----------------------------------------------------------------
# 5. Reports obrigatórios
#----------------------------------------------------------------
file mkdir $OUT_DIR

# Timing
report_timing -max_paths 20                 > $OUT_DIR/${PROJECT}_timing_max.rpt
report_timing -max_paths 20 -early          > $OUT_DIR/${PROJECT}_timing_min.rpt
report_timing -unconstrained -max_paths 20  > $OUT_DIR/${PROJECT}_timing_unconstrained.rpt
report_qor                                  > $OUT_DIR/${PROJECT}_qor.rpt
report_clock_gating -verbose                > $OUT_DIR/${PROJECT}_clock_gating.rpt

# Area / power
report_area                                 > $OUT_DIR/${PROJECT}_area.rpt
report_power                                > $OUT_DIR/${PROJECT}_power.rpt

# Constraints não satisfeitas
report_constraints -all_violators           > $OUT_DIR/${PROJECT}_violators.rpt

#----------------------------------------------------------------
# 6. Checagem de WNS (fail se não fechar 500 MHz)
#----------------------------------------------------------------
set wns [get_db [get_timing_paths -max_paths 1 -nworst 1] .slack]
puts "==============================================="
puts " WNS = $wns ns  (alvo: >= 0 para 500 MHz)"
puts "==============================================="
if {$wns < 0} {
    puts "WARNING: Timing NAO fecha 500 MHz. WNS = $wns ns"
    puts "Considere: pipeline no booth_radix4, relaxar clock, ou otimizar RTL."
} else {
    puts "OK: Timing fecha 500 MHz (WNS = $wns ns)"
}

#----------------------------------------------------------------
# 7. Escrever netlist + SDF + SDC para simulação pós-sintese
#----------------------------------------------------------------
write_hdl -mapped > $OUT_DIR/${PROJECT}_synth.v
write_sdf          > $OUT_DIR/${PROJECT}_synth.sdf
write_sdc          > $OUT_DIR/${PROJECT}_synth.sdc

# Opcional: netlist hierarquico para debug
write_hdl -mapped -hierarchical > $OUT_DIR/${PROJECT}_synth_hier.v

#----------------------------------------------------------------
# 8. Sair
#----------------------------------------------------------------
exit