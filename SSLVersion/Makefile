CXXFLAGS=-g -O0 -std=c++11
all: scl testScanner

testscanner: testScanner.o SCLScanner.o tokenNames.o
	c++ $(CFLAGS) -o $@ $^

scl: scl.o SCLParser.o SCLScanner.o tokenNames.o
	c++ $(CFLAGS) -o scl scl.o SCLParser.o SCLScanner.o
	
scl.o: scl.cpp SCLParser.h
SCLParser.o: SCLParser.cpp SCL.sst.c SCL.sst.h
SCLScanner.o: SCLScanner.h SCLParser.h SCL.sst.h

tokenNames.cpp: SCL.sst.h tokenNames.sed
	sed -f tokenNames.sed SCL.sst.h > tokenNames.cpp
	
SCL.sst.c SCL.sst.h: SCL.ssl
	ssl -n SCLParser::sslTable SCL.ssl
