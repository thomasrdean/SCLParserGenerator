This directory contains the source for a C version of the S/SL processor
and a skeletal S/SL walker.  This S/SL processor implements the third
version of S/SL, which includes the input lookahead choice ("[*") and fast
absolute branch code.


S/SL was originally done at U of T.
I found this C source on a usenet message board a long time ago.
I have made some small changes to it for generating C++.


Changes January 2021 Thomas Dean
1. Fixed include files for modern C compilers

2. Changed names of enumerated types to singular.
  - this is purly a personal style issue. When you declare
  a variable that contains an input token. The declaration
  now reads

    InputToken aToken;

3. Added Support for C++ in the directory cpp
  - My project is using ssl for parsing multiple network
  tcp streams at once for an IDS, so a library is used to reassemble the
  packets back into multiple streams for the connections between the clients and
  servers on the network. So we need a separate instance of the parser for
  each of the streams. Thus a class for the parser, and multiple instances
  of the parser for each stream. The changes are:
  a) new ssl walker template consisting of a header (SskSkelParser.h) and
     implementation file (SskSkelParser.cpp)
  b) a new flag for ssl, -n which specifies the name for the walker table
     in sslskel.sst.c. This allows the name of the table to be a C++ class
     variable that can be included in the SslSkelParser.cpp file.
     For example: "ssl -n SslSkelParser::sslTable sslskel.ssl"
  c) initialization of fields in C++ requires -std=c++11 flag (See example Makefile)
