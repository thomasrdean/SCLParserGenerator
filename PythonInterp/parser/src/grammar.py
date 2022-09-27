from enum import Enum,unique
from collections import OrderedDict
import struct 
import sys
import copy

from .enums import *
from .concrete import *
from .expr import *

# grammar definitions (should move to separate file)
# these are used to build a grammar tree which the parser
# walks while parsing the byte array that contains the message

#============================================================
# Class: GrmContext
#
# The context object is used to track parsing context
# information. The two elements are the current endianness
# and forward constraints
#============================================================


class GrmContext:
    # default values
    def __init__(self):
        self.endian = Endian.BIG
        self.fconstraints = []

#============================================================
# Class: Grm
#
# abstract base class of grammar nodes
# used to build grammar trees (really graphs since
# there may be cycles to handle recursion)
#
# members and methods common to all grammar classes
#
# parse is the initial entry point for parsing a
# PDU structure. It adds an extra paramert to call doRecursiveParse
# in the absract class since the root of a grammar graph
# might be a seq or an or. I suppose it could go to Container..
#
#============================================================

class Grm:
    # class varibles
    indent = 0;
    max_indent = 80
    traceStream = None #sys.stdout 

    def __init__(self, name):
        self.user_type = name

    def parse(self,thePDU,exportedName):
        # add empty forward constraints
       return self.doRecursiveParse(thePDU,exportedName,GrmContext())

    # tracing methods. If traceStream is a file object,
    # then these are used to build a parse trace
    def IN(self, gname, utype):
        if Grm.traceStream != None:
            print(" " * (Grm.indent if Grm.indent < Grm.max_indent else Gram.max_indent), file=Grm.traceStream, end='')
            print('->' + gname + ' (' + utype + ')')
            Grm.indent = Grm.indent + 1

    def FAIL(self,gname):
        if Grm.traceStream != None:
            Grm.indent = Grm.indent - 1
            print(" " * (Grm.indent if Grm.indent < Grm.max_indent else Gram.max_indent), file=Grm.traceStream, end='')
            print('<***' + gname )

    def SUCCEED(self,gname):
        if Grm.traceStream != None:
            Grm.indent = Grm.indent - 1
            print(" " * (Grm.indent if Grm.indent < Grm.max_indent else Gram.max_indent), file=Grm.traceStream, end='')
            print('<-' + gname )
    
    def TRACEIDNT(self):
        if Grm.traceStream != None:
            print(" " * (Grm.indent if Grm.indent < Grm.max_indent else Gram.max_indent), file=Grm.traceStream, end='')
        

#============================================================
# Class: GrmContainer
#
# abtract class for records (seq or set)
# and choice nodes. For records, the children
# represent the fields, for choice nodes
# they represent the alternatives. 
# the members of the list are GrmChild, which has
# a name and a pointer to another gram element.
#
# note in the Concrete classes, the children vector
# is called members, since GrmOr is not represented
# in the concrete form as the choice is made ad parse time.
# Concrete members also contain contrete nodes directly
#============================================================

class GrmContainer(Grm):
    def __init__(self, name):
        super().__init__(name)
        # While an ordered dicionary might work, we
        # need an independent link to the children for
        # updating the links after. So the intermediate
        # GrmChild class is used. Since
        # the children are only walked in order by
        # the parser it shouldn't matter.
        self.children = []

#============================================================
# Class: GrmChild
#
# Child node is used to provide a named grammar
# node that is a child of a container
#============================================================

class GrmChild:
    def __init__(self, name):
        self.name = name
        self.grm = None
        self.optional=False

#============================================================
# Class: GrmRec
#
# class for record (set or seq)
# subclass of container.
# record specific atributes are category (set or seq)
# and encoding (CUSTOM vs DER/BER)
#============================================================

class GrmRec(GrmContainer):

    def __init__(self, name):
        super().__init__(name)
        self.enc = Encoding.CUSTOM
        self.recCat = None
        self.endian = None
        self.back = None
        self.forward = None

    #----------------------------------------------
    # parse a pdu object 
    # 
    # name is the name from the invoication point. This
    # is the exported name if it is a goal, the name of the
    # choice if it is called from an Or, or the name
    # of the field if it is called from another record
    # forward constraints is the list of constraints that appy to this field.

    def doRecursiveParse(self,thePDU, name, context):
        self.IN(self.user_type, "GrmRec")
        saveBytePos = thePDU.curBytePos
        saveBitPos = thePDU.curBitPos

        # set up constraints
        result = None
        match self.recCat:
            case RecType.SEQ:
                result = ConSeq()
            case RecType.SET:
                # special case for parsing SET, allows out of order
                # items in DER/BER encodings.
                if self.enc != Encoding.CUSTOM:
                    print('SET for DER/BER not reimplmented yet');
                    return None
                result = ConSet()

        result.name = name
        result.user_type = self.user_type
        result.offset = thePDU.curBytePos

        # for now assume set and seq are the same,
        # disallowing out of order fields

        #TODO self.endian will create a new context
        # as will any forward constraints

        # as will any forward constraints
        backConstraints = []
        if (self.back != None):
            backConstraints = copy.deepcopy(self.back)

        for field in self.children:
            #print('trying to parse ' + field.name);
            #****************
            # forward constraints - do they apply to the next child
            #****************
            if (field.grm == None):
                print('xml file wrong for field ' + field.name)
                return None
            child = field.grm.doRecursiveParse(thePDU,field.name,context)
            if child == None:
                # handle optional?
                thePDU.curBytePos = saveBytePos
                thePDU.curBitPos = saveBitPos
                self.FAIL(self.user_type)
                return None
            result.members[field.name] = child;
            result.packetByteSize += child.packetByteSize
            result.packetBitSize += child.packetBitSize

            #****************
            # do backwards constraints
            #****************
            for i,expr in enumerate(backConstraints):
                # if the constraint is a ExprValue instance, then already
                # fully simplified.
                if not isinstance(backConstraints[i],ExprValue):
                    backConstraints[i] = expr.replaceAndSimplify(None,child,Grm.indent)
                    if Grm.traceStream != None:
                        self.TRACEIDNT()
                        backConstraints[i].print(Grm.traceStream)
                        print(file=Grm.traceStream)
                # TODO
                # if the constraint fails.
                # if it succeeds, need to remove.
                # how to remove from a list during enumeration?
                # if a dictionary, can we remove a key/value while enumeration?

        # after all chhildren have been mached
        # check all backsard consraints
        for i,expr in enumerate(backConstraints):
            if not isinstance(expr,ExprValue):
                thePDU.curBytePos = saveBytePos
                thePDU.curBitPos = saveBitPos
                self.FAIL(self.user_type)
                return None
            else: 
                # is a ExprValue insatnce
                if expr.value != 1:
                    thePDU.curBytePos = saveBytePos
                    thePDU.curBitPos = saveBitPos
                    self.FAIL(self.user_type)
                    return None
        self.SUCCEED(self.user_type)
        return result

#============================================================
# Class: GrmOR
#
# class for parsing choices
#============================================================

class GrmOr(GrmContainer):
    def __init__(self, name):
        super().__init__(name)

    def doRecursiveParse(self,thePDU, name, context):
        self.IN(self.user_type, "GrmOR")
        childName = name
        result = None
        for choice in self.children:
            if (name == None):
                childName = choice.name
            result = choice.grm.doRecursiveParse(thePDU,childName,context)
            if result != None:
                self.SUCCEED(self.user_type)
                return result

        self.SUCCEED(self.user_type)
        return None

#============================================================
# Class: GrmToken
#
# repreents a germinal in gramar tree
# always a priitivie type
#============================================================

class GrmToken(Grm):
    def __init__(self, name):
        super().__init__(name)
        self.byteSize = 0
        self.bitSize = 0
        self.text = TextRep.Octet
        self.type = None

        # this should be part of context
        self.endian = None

    def doRecursiveParse(self,thePDU, name, context):
        self.IN(self.user_type, "GrmToken")
        if self.byteSize == 0:
            print('Bit Fields not Implemented Yet', file=sys.stderr);
            self.FAIL(self.user_type)
            return None
        if self.bitSize != 0:
            print('Bit Fields not Implemented Yet', file=sys.stderr);
            self.FAIL(self.user_type)
            return None
        if self.byteSize != 0 and self.bitSize == 0:
            result = ConToken()
            result.name = name
            result.user_type = self.user_type
            result.packetByteSize = self.byteSize
            result.offset = thePDU.curBytePos;
            result.baseType = self.type
            if (thePDU.curBytePos + self.byteSize) > thePDU.len:
                #print('not enough bytes to read field ' + self.user_type)
                return None

            # TODO have to test if struct works correctly with non integral sizes

            # endiannes
            # if the grammar node specifies the endiannes, then that overrides
            # the parsing context. Otherwise the endianness is derived from
            # the parsing context. Defaults (in the initial call do doRecursiveParse
            # from parse) to Big Endian
            if self.endian == Endian.LITTLE:
                fmt='<'
            elif self.endian == Endian.BIG: 
                fmt='>'
            elif context.endian == Endian.LITTLE:
                fmt='<'
            else:
                fmt='>'

            match self.type:
                case BaseType.INTEGER:
                    match self.byteSize:
                        case 1:
                            (result.value,*Rest) = struct.unpack_from('B',thePDU.data,result.offset)
                        case 2:
                            (result.value,*Rest) = struct.unpack_from(fmt+'H',thePDU.data,result.offset)
                        case 4:
                            (result.value,*Rest) = struct.unpack_from(fmt+'L',thePDU.data,result.offset)
                        case 8:
                            (result.value,*Rest) = struct.unpack_from(fmt+'Q',thePDU.data,result.offset)
                        case _:
                            print('non integral integer sizes not yet implemented')
                            self.FAIL(self.user_type)
                            return None
                case BaseType.REAL:
                    # TODO - also store original bytes since Python doesn't know about floats
                    match self.byteSize:
                        case 4:
                            (result.value,*Rest) = struct.unpack_from(fmt+'f',thePDU.data,result.offset)
                            pass
                        case 8:
                            (result.value,*Rest) = struct.unpack_from(fmt+'d',thePDU.data,result.offset)
                            pass
                        case _:
                            print('non integral real sizes not yet implemented')
                            self.FAIL(self.user_type)
                            return None
                case BaseType.OCTET_STRING:
                    # octet string still needed...
                    print('octet strings not iimplemented yet')
                    self.FAIL(self.user_type)
                    return None
            thePDU.curBytePos += self.byteSize
            self.SUCCEED(self.user_type)
            return result

        # not reached??
        self.FAIL(self.user_type)
        return None
