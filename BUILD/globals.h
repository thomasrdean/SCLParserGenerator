/*+
 * File:	globals.h
 *
 * Purpose:	All global declarations go here.
 *
 * Revision History:
 *
 * 1.0	- Thomas R. Dean - June 2004
 *	- Initial Version
 * 1.1  - Thomas Dean April 2015
 *	- clean up of includes
-*/
#ifndef _GLOBALS_H_
#define  _GLOBALS_H_

#include <stdint.h>
#include <stdio.h>

#include <netinet/in.h>

#define true 1
#define false 0

typedef int bool;

extern char * progname;

extern FILE * traceFileParser;
extern FILE * traceFileCons;
extern FILE * traceFileAppParser;
extern FILE * traceFileAppCons;
extern FILE * rdfFile;

extern unsigned long long pduCount;
extern unsigned long long pduFailed;
extern unsigned long long pduTtotal;

extern char * traceFileParserName;
extern char * traceFileConsName;
extern char * traceFileAppParserName;
extern char * traceFileAppConsName;
extern char * pcapFileName;
extern char * RDFFileName;
extern char * envDirectory;

extern int record;
extern int debugLevel;



struct HeaderInfo {
    uint8_t ip_v; // version 4 or 6, detemines interpretation of srcIP and dstIP
    union {
        uint32_t v4;
        uint8_t v6[16];
    } srcIP;
    union {
        uint32_t v4;
        uint8_t v6[16];
    } dstIP;
	uint16_t srcPort;
	uint16_t dstPort;
	long time;
	unsigned long pktCount;
};

union Data
{
	unsigned int value1;
	char* value2;
	int value3;
	int type;
};

#define BIGENDIAN (0x0)
#define LITTLEENDIAN (0x1)

#endif /* _GLOBALS_H_ */
