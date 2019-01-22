# MyMicroAssembly Lexer
import ply.lex
from asm_info import instruction_aliases

instructions = [
  'ADD', 'SUB', 'NEG', 'INC',
  'DEC', 'AND', 'OR',  'XOR',
  'NOT', 'LSL', 'LSR', 'ASR', 
  'CMP', 'AJMP','AJE', 'AJNE',
  'AJL', 'AJLE','AJG', 'AJGE',
  'LDI', 'STO',
  'MOV', 'RET', 'HALT'
]

valid_instruction_tokens = instructions + \
                           list(instruction_aliases.keys())

# No reserved words yet, but might be some later
# TODO: IMPLEMENT !!!
reserved_words = []

tokens = [
  # Instructions
  'COMMA',
  'REGISTER',
  'NUMBER',
  'INSTRUCTION',
  'LABEL_DEF',  # Ends in ':', used for placing labels
  'LABEL_REF'   # _Does not_ end in ':', used for referencing labels
 ] + reserved_words

t_COMMA = r'\,'
t_ignore = ' \t' # Necessary, DO NOT remove

# To look for instructions
# Examples: `ADD`, `SUB`
# NONExamples: `ADD5`
# Regex explanation (without re.MULTILINE):
# -----------------------------------------
# `[A-Za-z]+` matches the instruction text.
# `(?!([A-Za-z]+)?[0-9:])` ensures no numbers are appended to the
# instruction and that the instruction is not a label. 
# *** May match text written in the wrong place for an instruction,  
# but if this occurs the parser will throw an error later on. 
def t_INSTRUCTION(t):
  r'[A-Z]+(?!([A-Z]+)?[0-9:])'
  t.value = t.value.strip()     # Remove beginning whitespace
  if (t.value not in valid_instruction_tokens):
    print ("!!! ERROR: Illegal token '%s' @ line %d" % (t.value, t.lexer.lineno))
  t.type = 'INSTRUCTION'
  return t
  
# Seeks labels that begin with a letter and continue with
# letters and/or numbers (or '_'), ending in a colon ':'. Must be
# the first token of a line. 
# All label letters must be lowercase, and cannot begin with
# 'r' and a digit (to prevent naming collisions with registers).
def t_LABEL_DEF(t):
  r'(^|\n)(?!r[0-9])[a-z_]([a-z0-9_]+)?:'
  t.value = t.value[:-1].strip()
  return t

# Similar to t_LABEL_DEF, but has a slightly different syntax
# to look for labels found as operands that reference labels
# defined elsewhere throughout the program via the t_LABEL_DEF
# syntax. 
# Same syntax as t_LABEL_DEF but has no ':' at the end and must
# be surrounded in '<' and '>' brackets. 
def t_LABEL_REF(t):
  r'<(?!r[0-9])[a-z_]([a-z0-9_]+)?>'
  t.value = t.value[1:-1].strip()
  return t
  
# Examples: `r1`, `r4`
#
def t_REGISTER(t):
  r'r[0-9]+(?![^\s\,])'
  t.value = int(t.value[1:]) # Grab register number
  return t

# Allows both hex and decimal input. 
def t_NUMBER(t):
  r'(?P<hex>0x)?(?(hex)[A-Fa-f0-9]|[0-9])+'
  if (t.value[0:2] == "0x"):
    t.value = int(t.value, 16)
  else:
    t.value = int(t.value, 10)
  return t

# Necessary to allow line number tracking in the lexer, since it
# has no internal mechanism to track the line number. 
def t_newline(t):
  r'\n+'
  t.lexer.lineno += len(t.value)

def t_error(t):
  print("!!! ERROR: Illegal character '%s' @ line %d" % (t.value[0], t.lineno))
  t.lexer.skip(1)

lexer = ply.lex.lex()   # Build lexer

def get_tokens(data):
  '''Passes the data through the lexer and returns the tokens.'''
  lextokens = []
  lexer.input(data)
  for tok in lexer:
    lextokens.append(tok)
  return lextokens

def get_lexer():
  '''Returns the full lexer object for use in parsing, etc.'''
  return lexer


