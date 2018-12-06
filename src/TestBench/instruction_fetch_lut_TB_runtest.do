SetActiveLib -work
comp -include "$dsn\src\instruction_fetch_LUT.vhd" 
comp -include "$dsn\src\TestBench\instruction_fetch_lut_TB.vhd" 
asim +access +r TESTBENCH_FOR_instruction_fetch_lut 
wave 
wave -noreg i_opcode7
wave -noreg o_num_fetches
# The following lines can be used for timing simulation
# acom <backannotated_vhdl_file_name>
# comp -include "$dsn\src\TestBench\instruction_fetch_lut_TB_tim_cfg.vhd" 
# asim +access +r TIMING_FOR_instruction_fetch_lut 
