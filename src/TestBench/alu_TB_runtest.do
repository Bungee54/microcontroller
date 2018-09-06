SetActiveLib -work
comp -include "$dsn\src\alu.vhd" 
comp -include "$dsn\src\TestBench\alu_TB.vhd" 
asim +access +r TESTBENCH_FOR_alu 
wave 
wave -noreg A
wave -noreg B
wave -noreg OPCODE
wave -noreg Y
wave -noreg FLAG_CARRY
wave -noreg FLAG_OVERFLOW
wave -noreg FLAG_NEGATIVE
wave -noreg FLAG_ZERO
# The following lines can be used for timing simulation
# acom <backannotated_vhdl_file_name>
# comp -include "$dsn\src\TestBench\alu_TB_tim_cfg.vhd" 
# asim +access +r TIMING_FOR_alu 
