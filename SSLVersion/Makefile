CXXFLAGS=-g -O0 -std=c++11

all: bin/testscanner bin/scl

bin/testscanner: testScanner.o SCLScanner.o tokenNames.o
	c++ $(CFLAGS) -o $@ $^

bin/scl: scl.o SCLParser.o SCLScanner.o tokenNames.o tokenNames.o
	c++ $(CFLAGS) -o $@ $^
	

tokenNames.cpp: SCL.tokens.h tokenNames.sed
	sed -f tokenNames.sed SCL.tokens.h > tokenNames.cpp

scl.o: scl.cpp SCLParser.h SCL.sst.h SCL.tokens.h
SCLParser.o: SCLParser.cpp SCL.sst.h 
SCLScanner.o: SCLScanner.h SCLParser.h SCL.sst.h

SCL.sst.h SCL.sst.c SCL.tokens.h: SCL.ssl
	ssl -n SCLParser::sslTable SCL.ssl

clean:
	-rm SCL.sst.h SCL.sst.c SCL.tokens.h tokenNames.cpp *.o bin/scl bin/testscanner
