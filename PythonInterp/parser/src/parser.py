from enum import Enum
from collections import OrderedDict
import xml.etree.ElementTree as ET

# how to use a file from the same package?
# this is freaking ugly.
#import sys,os
#sys.path.insert(0,os.path.dirname(os.path.abspath(__file__)))
# solution is to prefix file name with . to signify current directory.

# grammar nodes are used to build grammar graphs (trees with cycles)
from .grammar import *
from .expr import *

class Header:
    def __init__(self):
        self.srcPort = 0
        self.dstPort = 0
class PDU:
    def __init__(self):
        self.data = None
        self.len = 0
        self.curBytePos = 0
        self.curBitPos = 0
        self.Header = None
        self.watermark = 0

class Parser:
    # __init__(self,fileName)
    # create a grammar tree from the XML file that can be used to
    # build a concrete from a byte array.
    #
    # Since the XML file is generated from a checked SCL specification
    # there shouldn't be any wierd erorrs, but we insersk
    def __init__(self,fileName):
        self.fileName = fileName

        # nodes contain references to all of the nodes as they are parsed
        # they are indexed by their name, which is unique (done by unique naming)
        self.nodes = {} 

        # self.roots are the nodes that are exported. They are the objects that can be parsed
        self.exports = {}

        # dictionary to map childrenTypes to children instances
        # a child will have a short name and the name of the user type
        # for example, it may have the name 'type' and the type of the field may
        # be named HEADER_RTPS. The user-type-decl for HEADER_RTPS may not be 
        # read yet, so this will map the name HEADER_RTPS to the field instance
        # that contains
        childList = []


        # convert the xml file to a set of grammar trees
        tree =  ET.parse(fileName)
        grammar = tree.getroot()

        # grammar has a name
        nameNode=grammar.find('name');
        self.name=nameNode.text
        #print('Name of Grammar is ' + self.name);

        # process the exports
        exports=grammar.find('exports');
        for exportedType in exports:
            #print('exported type is ' + exportedType.text);
            # insert placeholder in exports that will be later bound to the node
            self.exports[exportedType.text] = None

        # do imports here when we implement them
        # have a dictionary that refers to parser objects.

        # read types
        # for all practical purposes, most of the top level types are sequences
        # there may be some rename types in the future, but those are not yet implemented in SCL (I think)

        for user_type in grammar.findall('user-type-decl'):
            # debugging - check for child existance?
            # should only be one child
            # print('user type is ' + user_type[0].tag);
            typeElement = user_type[0]
            match typeElement.tag:
                case 'record':
                    recTypeName = typeElement.find('name').text
                    #print('record type name is ' + recTypeName)
                    # create grammar node and added to nodes dictionary
                    record = GrmRec(recTypeName);
                    self.nodes[recTypeName] = record
                    # record level attributes
                    record.enc = Encoding[typeElement.find('encoding').text]
                    record.recCat = RecType[typeElement.find('recordCat').text]
                    #endian for nesting
                    endian = typeElement.find('endian')
                    if (endian != None):
                        record.endian = Endian.from_str(endian.text)

                    # read the fields
                    fieldList = typeElement.find('fields')
                    for field in fieldList:
                        fieldName = field.find('name').text
                        #print('Field named ' + fieldName)
                        child = GrmChild(fieldName);
                        record.children.append(child)
                        # store the created node under the type of the
                        # field. Then we can link it once all of the fields are processed
                        childList.append((field.find('type').text,child))

                    # read the constraints
                    # back firsrt
                    backConstraints = typeElement.find('back-constraints')
                    if backConstraints != None:
                        record.back = []
                        for back in backConstraints:
                            # back is a <back-constraint>
                            # that contains a single expression
                            backExpr = Expr.convert(back[0])
                            #backExpr.print(sys.stdout)
                            #print()
                            record.back.append(backExpr)

                case 'decision':
                    decTypeName = typeElement.find('name').text
                    decision = GrmOr(decTypeName)
                    self.nodes[decTypeName] = decision
                    choiceList = typeElement.find('choices')
                    for choice in choiceList:
                        choiceName = choice.find('name').text
                        child = GrmChild(choiceName);
                        decision.children.append(child)
                        childList.append((choice.find('type').text,child))


                case 'token':
                    tokTypeName = typeElement.find('name').text
                    #print('token type name is ' + tokTypeName)
                    # create grammar node and added to nodes dictionary
                    token = GrmToken(tokTypeName)
                    self.nodes[tokTypeName] = token
                    # fill in values
                    # convert primitive type name to enumerated type
                    tokeType = typeElement.find('type').text
                    token.type = BaseType.from_str(tokeType);
                    # byte and bit size
                    byteSize = typeElement.find('byte-size')
                    if (byteSize != None):
                        token.byteSize = int(byteSize.text)
                    bitSize = typeElement.find('bit-size')
                    if (bitSize != None):
                        token.bitSize = int(bitSize.text)
                    #encoding
                    endian = typeElement.find('endian')
                    if (endian != None):
                        token.endian = Endian.from_str(endian.text)
                    # texrep
                    text = typeElement.find('text')
                    if (text != None):
                        token.text = TextRep[text.text]

        # link the graph together
        for (typeName,child) in childList:
            #print ('Trying to find used type' + typeName)
            if not typeName in self.nodes:
                print ('** Type ' + typeName + ' not defined')
            else:
                #print ('** Type ' + childType + ' is defined')
               child.grm = self.nodes[typeName]


        # link the exports
        for exportType in self.exports:
            #print ('Trying to find exported type ' + exportType)
            if self.nodes[exportType] == None:
                print ('** Type ' + exportType + ' not defined')
            else:
                #print ('** Type ' + exportType + ' is defined')
                self.exports[exportType] = self.nodes[exportType]

        #self.dumpExports()
        #self.dumpNodes()

    def dumpExports(self):
        print ('The exported types are:')
        for key,n in self.exports.items():
            print(key, end='')
            match n:
                case GrmToken():
                    print(' is a token')
                case GrmRec():
                    print(' is a record')

    def dumpNodes(self):
        # dump the nodes
        print ('The grammar nodes are:')
        for key,n in self.nodes.items():
            print('node name' + key);
            if (n == None):
                print('**no definition yet')
            # otherwise it is a grm node
            match n:
               case GrmToken():
                    print('    is a token')
                    print('    has type ' + str(n.type))
                    print('    has byte size ' + str(n.byteSize))
                    print('    has bit size ' + str(n.bitSize))
                    print('    has text representation ' + str(n.text))
                    print('    has endian' + str(n.endian))

               case GrmRec():
                    print('    is a record')
                    print('    encoding is ' + str(n.enc))
                    print('    record category is ' + str(n.recCat))
                    print('    Fields: ')
                    # TODO add endian for nesting
                    for field in n.children:
                        print('      ' + field.name + ' type ' + field.grm.user_type)

               case GrmOr():
                    print('    is a choice')
                    print('    Choices: ')
                    # TODO add endian for nesting
                    for choice in n.children:
                        print('      ' + choice.name + ' type ' + choice.grm.user_type)

    def parse(self,thePDU,exportedName):
        if not exportedName in self.exports.keys():
            print('Type ' + exportedName + ' not avaiable from grammar module ' + self.name)
            return None
        rootNode = self.exports[exportedName]
        return rootNode.parse(thePDU,exportedName)
