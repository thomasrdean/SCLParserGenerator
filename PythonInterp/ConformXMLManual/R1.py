#+
# File R1.py
# 
# This is the translation to pytyon
# of the coformacne code used to test
# the SCL parser generataor.
#
# This one tets all of the numeric types
# explicitly marked as little endian
#-

from struct import *

import sys
sys.path.append('../')
import parser.src.parser as SCLParser

if __name__ == '__main__':
    #build the byte array
    # all little endian
    # a - REAL 8 4.3
    # b - INT 8 (0xA1A2A3A4A5A6A7A8)
    # c - REAL 4 (45.5)
    # d - INT 4 (0xA1A2A3A4)
    # e - INT 2 (0xA1A2)
    # f - INT 1 (0xA1A2)
    data = pack('<d',4.3);
    data = data + pack('<Q',0xA1A2A3A4A5A6A7A8)
    data = data + pack('<f',45.4);
    data = data + pack('<I',0xA1A2A3A4)
    data = data + pack('<H',0xA1A2)
    data = data + pack('<B',0xA1)
    print ('packed data is <' + data.hex() +  '>')

    thePDU = SCLParser.PDU()
    thePDU.len = len(data)
    thePDU.data = data

    p = SCLParser.Parser('R1.xml')

    c = p.parse(thePDU,'PDU_R1')
    c.walk(0,sys.stdout)
    if c.members['a'].value != 4.3:
        print('a = ' + str(c.members['a'].value) + '(!= 4.3)')
    if c.members['b'].value != 0xA1A2A3A4A5A6A7A8:
        print('b = ' + hex(c.members['b'].value) + '(!= 0xA1A2A3A4A5A6A7A8)')
    if c.members['c'].value - 45.4 > 0.00001:
        print('c = ' + str(c.members['c'].value) + '(!= 45.4)')
    if c.members['d'].value != 0xA1A2A3A4:
        print('d = ' + hex(c.members['d'].value) + '(!= 0xA1A2A3A4)')
    if c.members['e'].value != 0xA1A2:
        print('e = ' + hex(c.members['e'].value) + '(!= 0xA1A2)')
    if c.members['f'].value != 0xA1:
        print('f = ' + hex(c.members['f'].value) + '(!= 0xA1)')
