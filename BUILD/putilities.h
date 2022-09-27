#ifndef PUTILITIES_H
#define PUTILITIES_H

#include "globals.h"
#include "packet.h"

bool lengthRemaining(PDU * thePDU, unsigned long length, char * name);
bool checkSlack(PDU * thePDU, unsigned long len);

uint8_t get8_e(PDU * thePDU, uint8_t endianness);
uint16_t get16_e(PDU * thePDU, uint8_t endianness);
uint32_t get24_e(PDU * thePDU, uint8_t endianness);
uint32_t get32_e(PDU * thePDU, uint8_t endianness);
uint64_t get48_e(PDU * thePDU, uint8_t endianness);
uint64_t get64_e(PDU * thePDU, uint8_t endianness);
float getReal4_e(PDU * thePDU, uint8_t endianness);
double getReal8_e(PDU * thePDU, uint8_t endianness);

uint8_t la8_e(PDU * thePDU, unsigned long offset, uint8_t endianness);
uint16_t la16_e(PDU * thePDU, unsigned long offset, uint8_t endianness);
uint32_t la24_e(PDU * thePDU, unsigned long offset, uint8_t endianness);
uint32_t la32_e(PDU * thePDU, unsigned long offset, uint8_t endianness);
uint64_t la48_e(PDU * thePDU, unsigned long offset, uint8_t endianness);
uint64_t la64_e(PDU * thePDU, unsigned long offset, uint8_t endianness);
float laReal4_e(PDU * thePDU, unsigned long offset, uint8_t endianness);
double laReal8_e(PDU * thePDU, unsigned long offset, uint8_t endianness);

uint8_t get8(PDU * thePDU);
uint16_t get16(PDU * thePDU);
uint32_t get24(PDU * thePDU);
uint32_t get32(PDU * thePDU);
uint64_t get64(PDU * thePDU);
float getReal4(PDU * thePDU);
double getReal8(PDU * thePDU);

void getConstChar_e(PDU * thePDU, unsigned char * buffer, unsigned long numChars, uint8_t endianness);

extern int debugIndent;
void IN(FILE *,char * functionName);
void SUCCESS(FILE *,char * functionName);
void FAIL(FILE*,char * functionName);
void READREAL(FILE * tf,char * fn,double value);
void READLONG(FILE * tf,char * fn,unsigned long value);
void READLONGLONG(FILE * tf,char * fn,unsigned long long value);
void READOCTET(FILE * tf,char * fn,char * ostring, unsigned long length);

void CHOICE(FILE*,long long value);
#endif /* PUTILITIES_H */
