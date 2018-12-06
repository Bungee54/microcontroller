import assembler
import sys

dbg = False

#%% Check console-specified arguments
assert (len(sys.argv) == 2), "Wrong arguments!\nFormat: %s filename" \
  % sys.argv[0]

with open(sys.argv[1]) as file:
  data = file.read()
  
#%% Assemble

if dbg:
  print("%s\n=========================\n" % data)

machine_code = assembler.assemble(data, debug=dbg)

#%% Reformat


def binary_to_hex_list(data, word_size):
  '''Converts a string of binary data into list of hex strings (using 
  uppercase characters and digits 0-9). `word_size` determines the number 
  of bits in a single word - must be a multple of 4. 
  `word_size / 4` hex characters per line to represent one word.
  '''
  assert (word_size % 4 == 0), \
    "!!! ERROR: `word_size` (%d) must be a multiple of 4." % word_size
  
  assert (len(data) % word_size == 0), \
    "!!! ERROR: binary data's length be a multiple of `word_size` (%d)" % \
    word_size
 
  # Splits data into a list of strings of bits, each of length word_size.
  data_binary_lines = [
      data[i:i+word_size] for i in range(0, len(data), word_size)]
  
  # Convert to hex (padded with '0's to uniform width)
  data_hex_lines = [
      "{0:0{length}X}".format(int(word, 2), length=word_size//4) 
       for word in data_binary_lines]
  
  return data_hex_lines


hex_list = binary_to_hex_list(machine_code, 16)
print("\n".join(hex_list))
