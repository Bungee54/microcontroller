# 16-bit VHDL Toy Microcontroller

This was a small passion project I developed after learning about hardware design in a lab a couple 
of years ago - it's a 16-bit microcontroller written in VHDL using the Aldec Active-HDL software. 

Since I wrote this as one of my very first hardware design projects, I wrote it with two concepts in mind:
* *Simplicity* - both so I could write it, and so I could explain it to others starting out like me
* *Extensibility* - so that you can add your own stuff 
  * (There are seven bits in total to specify what kind of instruction to execute, and I didn't come close to using all of them!)

# Sections

This project is split into two main sections: 
* The **assembler** (see `Assembler/`), which is written in Python.
* The **microcontroller itself** (see `src/`), which is the actual VHDL design. 

Documentation for the assembler can be found in `Assembler/specifications/`.
Documentation for the microcontroller's instructions & ALU opcodes can be found in `overall_docs/`. 

