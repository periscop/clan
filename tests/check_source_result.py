#!/usr/bin/python 


import sys
import os
import subprocess
import string


# Check arguments
if (len(sys.argv) < 3):
	print 'Usage:', sys.argv[0], 'source.c source.c.scop [clan_path]'
	sys.exit(2)

# Get arguments
source_filename = sys.argv[1]
scop_filename = sys.argv[2]
	
# Display arguments
print sys.argv[0], source_filename, scop_filename

# Check if source_filename and scop_filename exist
if (os.path.exists(source_filename) == False):
	print 'Error:', source_filename, ' file does not exist'
	sys.exit(3)
if (os.path.exists(scop_filename) == False):
	print 'Error:', scop_filename, ' file does not exist'
	sys.exit(4)

# Custom clan
clan = ""
if (len(sys.argv) >= 4 and os.path.exists(sys.argv[3]) and os.access(sys.argv[3], os.X_OK)):
	clan = sys.argv[3]
else:
	clan = "clan"


# Get scop form clan
clan_output,error = subprocess.Popen([clan, source_filename], stdout = subprocess.PIPE).communicate()
#print clan_output

# Get scop
scop_file = open(scop_filename, 'r')
scop = ""
for line in scop_file:
	#sys.stdout.write(line)
	scop += line
scop_file.close()


# Compare clan_output and scop
s0 = ""
s1 = ""
# Remove empty line
skip_next_line = False
for line in string.split(clan_output, '\n'):
	if (skip_next_line):
		skip_next_line = False
		continue
	if (line == '# File name'): skip_next_line = True
	if line != '' and (string.find(line, 'enerated by') == -1): s0 += line + '\n'
for line in string.split(scop, '\n'):
	if (skip_next_line):
		skip_next_line = False
		continue
	if (line == '# File name'): skip_next_line = True
	if line != '' and (string.find(line, 'enerated by') == -1): s1 += line + '\n'
# Print
print s0
print s1
# Result
if (s0 != s1):
	print 'Result:', '"clan', source_filename + '"', 'and', '"' + scop_filename + '"', 'are different'
	sys.exit(1)
else:
	print 'Result:', '"clan', source_filename + '"', 'and', '"' + scop_filename + '"', 'have no difference'

# End
sys.exit(0)
