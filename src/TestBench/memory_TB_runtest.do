SetActiveLib -work
comp -include "$dsn\src\memory.vhd" 
comp -include "$dsn\src\TestBench\memory_TB.vhd" 
asim +access +r TESTBENCH_FOR_memory 
wave 
wave -noreg i_clk
wave -noreg i_address
wave -noreg i_rw
wave -noreg io_data
# The following lines can be used for timing simulation
# acom <backannotated_vhdl_file_name>
# comp -include "$dsn\src\TestBench\memory_TB_tim_cfg.vhd" 
# asim +access +r TIMING_FOR_memory 
