CXXFLAGS=-g -O0 -std=c++11
all: scl testScanner

testscanner: testScanner.o SCLScanner.o
	c++ $(CFLAGS) -o $@ $^

scl: scl.o SCLParser.o SCLScanner.o
	c++ $(CFLAGS) -o scl scl.o SCLParser.o SCLScanner.o
	
scl.o: scl.cpp SCLParser.h
SCLParser.o: SCLParser.cpp SCL.sst.c SCL.sst.h
SCLScanner.o: SCLScanner.h SCLParser.h SCL.sst.h

SCL.sst.c SCL.sst.h: SCL.ssl
	ssl -n SCLParser::sslTable SCL.ssl
