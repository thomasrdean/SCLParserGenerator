#+
# File: concrete.py
#
# Classes that represent the parsed (i.e. concrete) version of a message.
#-

import sys
from collections import OrderedDict
from .enums import *

#=========================================
# class Concrete
#
# - abstract base type that represents all concrete
# objects. Contains fields and methods common to all concrete 
# objects, but should never be intiated itself.
#
# TODO - can we check that in __init__?
#=========================================

class Concrete:
    def __init__(self):
        self.name = None
        self.user_type = ""
        self.packetByteSize = 0
        self.packetBitSize = 0
        self.offset = 0
    def indent(self,l,f):
        print(' ' * l, end='',file=f)

#=========================================
# class ConRec
#
# abstract class for all record type objects
# i.e. SEQ and SET. Has notion of members
# and a method to walk the members
#=========================================

class ConRec(Concrete):
    def __init__(self):
        super().__init__()
        self.members = OrderedDict()

    def walk(self,l,f):
        for m,n in self.members.items():
            #print('key is ' + m)
            n.walk(l,f)

#=========================================
# class ConSeq
#
# concrete class for sequence types
#=========================================

class ConSeq(ConRec):
    def __init__(self):
        super().__init__()

    def walk(self,l,f):
        self.indent(l,f)
        if self.name != None:
            if self.user_type == None:
               self.user_type = ''
            print(self.name + ' : ', end='', file=f)
            print(str(self.offset) + " " + str(self.packetByteSize) + ": ",end='',file=f)
            print(self.user_type + ' ', end='', file=f)
        print('SEQUENCE {', file=f)

        super().walk(l+4,f)

        self.indent(l,f)
        print('}', file=f)

#=========================================
# class ConSet
#
# concrete class for sequence types
#=========================================

class ConSet(ConRec):
    def __init__(self):
        super().__init__()

    def walk(self,l,f):
        self.indent(l,f)
        if self.name != None:
            if self.user_type == None:
               self.user_type = ''
            print(self.name + ' : ', end='', file=f)
            print(str(self.offset) + " " + str(self.packetByteSize) + ": ",end='',file=f)
            print(self.user_type + ' ', end='', file=f)
        print('SET {', file=f)

        super().walk(l+4,f)

        self.indent(l,f)
        print('}', file=f)

#=========================================
# class ConToken
#
# concrete class for primitive fields
#=========================================

class ConToken(Concrete):
    
    def __init__(self):
        super().__init__()
        self.value=0
        self.baseType = None

    def walk(self,l,f):
        self.indent(l,f)
        print(self.name + ':' + str(self.offset) + ' ' + str(self.packetByteSize), end='',file=f)
        match self.baseType:
            case BaseType.INTEGER:
                print(': INTEGER (' + hex(self.value) + ')',file=f)
            case BaseType.REAL:
                print(': REAL (' + str(self.value) + ')', file=f)
            case BaseType.OCTET_STRING:
                print(': OCTET STRING (' + str(self.value) + ')', file=f)
