#!/bin/bash
# Relies on this script being in the [ROOT]/src/ directory, and the python file being in the [ROOT]/Assembler/ directory.

if [ "$#" != 2 ]
then 
	echo "Incorrect arguments."
	echo "Format: $0 assembly_file destination_file"
else
	python3 ../Assembler/main.py "../src/$1" > "$2"
fi	
