'''MyMicroAssembly Assembler
MyMicroAssembly (MMA) functions on 16-bit words. 
Each instruction is a word plus an (optional) extension word
to fit more data. 

Instruction Template
╔═════════╤═══╤═════╤═════╤═════╗
║ OPCODE  │FLG│ rA  │ rB  │ rC  ║   (16 bits = 1 word)
╟─┬─┬─┬─┬─┼─┬─┼─┬─┬─┼─┬─┬─┼─┬─┬─╢
║1│1│1│1│1│1│9│8│7│6│5│4│3│2│1│0║
║5│4│3│2│1│0│ │ │ │ │ │ │ │ │ │ ║
╚═╧═╧═╧═╧═╧═╧═╧═╧═╧═╧═╧═╧═╧═╧═╧═╝

Extension Template
╔═══════════════════════════════╗
║           MISC. DATA          ║
╟─┬─┬─┬─┬─┬─┬─┬─┬─┬─┬─┬─┬─┬─┬─┬─╢
║1│1│1│1│1│1│9│8│7│6│5│4│3│2│1│0║
║5│4│3│2│1│0│ │ │ │ │ │ │ │ │ │ ║
╚═╧═╧═╧═╧═╧═╧═╧═╧═╧═╧═╧═╧═╧═╧═╧═╝

In the above templates, the OPCODE section stores a 5-bit
code that tells the CPU what instruction to execute. The 
2 FLG (flag) bits specify what version of the instruction to
use - this is useful for instructions that can take different
sets of operands (like a register and register versus a 
register and number). rA, rB, and rC are spaces to place
different register operands (3 bits for 8 possible registers).

If the instruction is one that requires a 16-bit immediate 
address or other data that cannot fit into the given space 
in the 16-bit instruction word, the instruction shall be 
followed by an extension template with the relevant data.
The processor will know to look for an extension word if the 
opcode and flag bits require it (for example, the processor
would know that the LDI instruction would need an immediate
address operand and thus use an extension word). 

Assembly Steps:
1. Preprocessing (!! NOT IMPLEMENTED YET !!)
2. Main assembly (instructions -> machine code)
3. Postprocessing (label resolution, final output, etc.)
'''

import asm_parser
from asm_info import opcode_dict, instruction_aliases


# Will be filled with the assembly code.
data = ''

# Dictionary holding the positions of any labels defined
# in the assembly. 
# Will have key-value pairs of the form {label_name : pos},
# where `label_name` is a string and `pos` is an integer 
# representing its offset in words from the beginning of the 
# assembled program. 
#
# Modified later. 
label_positions = {}

def getMachineCodeInstruction(line, label_positions):
  '''Returns a string of '0's and '1's that represent the
  given InstructionLine `line` as machine code.
  '''
  string = ''

  ### ------------------------
  ### BASE INSTRUCTION WORD
  ### ------------------------

  # Add first five bits to specify instruction type.
  string += opcode_dict[line.instruction_name][0]

  # Add two flag bits depending on operands.
  operand_names = tuple([operand.name for 
                         operand in line.operand_list])
  try:
    # Look up list of operand types in the dictionary and use the corresponding
    # value as the flag bits. 
    string += opcode_dict[line.instruction_name][1][operand_names]
  except: 
    print("!!! ERROR: Unknown operand combination %s for instruction `%s`" % (str(operand_names), line.instruction_name))
    raise

  # Add register bits (3 bits per registers; there is 
  # space for 3 registers in the instruction). 
  for operand in line.operand_list:
    if operand.name == 'REGISTER':
      string += "{0:03b}".format(operand.value)
  
  # Pad string so that it fills out a 16-bit word.
  string = string.ljust(16, '0')

  ### -----------------
  ### EXTENSION WORDS
  ### -----------------

  for operand in line.operand_list:
    if operand.name == 'NUMBER':
      string += "{0:016b}".format(operand.value)
    elif operand.name == "LABEL_REF":
      string += "{0:016b}".format(label_positions[operand.value])
  
  return string


def getInstructionPositions(instruction_lines):
  '''Returns a list of tuples, each of the form `(position, i_line)`
  where `position` is the offset of the first word in the
  instruction line from the beginning of the program and `i_line`
  is the InstructionLine object itself.
  '''
  positions = []
  current_pos = 0
  for line in instruction_lines:
    positions.append((current_pos, line))
    current_pos += line.getInstructionLength()
  return positions


def createLabelPositionDict(instruction_positions):
  '''Returns a dictionary with string-valued keys representing
  the names of each label and integer values representing their
  corresponding positions.
  `instruction_positions` must be a list of tuples as described in 
  `getInstructionPositions`:
  --> each tuple of the form `(position, i_line)`
  '''
  label_dict = {}
  for instr_pos in instruction_positions:
    position, line = instr_pos
    if line.label_name is not None:
      label_dict.update({line.label_name : position})
  return label_dict


def resolveAliases(instruction_lines):
  for line in instruction_lines:
    if line.instruction_name in instruction_aliases:
      line.instruction_name = instruction_aliases[line.instruction_name]
  return instruction_lines


def assemble(data, debug=False):
  # List of instruction lines that contain information about
  # each instruction and its operands. 
  instruction_lines = asm_parser.parse_data(data)
  
  # Preprocessing
  instruction_lines = resolveAliases(instruction_lines)

  # Position calculation
  instruction_positions = getInstructionPositions(instruction_lines)
  label_positions = createLabelPositionDict(instruction_positions)

  if (debug):
    for line in instruction_lines:
      print(line)
      print(" --> %s" % getMachineCodeInstruction(line, label_positions))
    print()
    print("=============================")
    print()

  output = '' 

  # Assembly 
  for line in instruction_lines:
    output += getMachineCodeInstruction(line, label_positions)

  # Final output
  return output