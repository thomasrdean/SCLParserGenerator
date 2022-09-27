/*+
 * File:    sutilities.h
 *
 * Purpose: Interface to the serializer
 *
-*/

#ifndef __SUTITILITIES_H__
#define __SUTITILITIES_H__
#include <stdio.h>

// min size is size of ethernet packet
#define MINSIZE 1520

typedef struct _SerializeBuffer {
    // pointer to data and length of room for data
    // inthe current node
    uint8_t * buffer;
    unsigned long bufferLen;

    // total data written - only used in the first node
    unsigned long totalLen;

    // current write position in the current buffer
    int curPos;

    // linked list of buffer nodes, field that points to the first node.
    struct _SerializeBuffer * next;
    struct _SerializeBuffer * first;
} SerializeBuffer;

// Make sure there is enough information to write the specified amount of data.
SerializeBuffer *SerializeBufferAllocate(SerializeBuffer * current, int size);

// need to include the odd length
void writebufferInt64(SerializeBuffer * first, uint64_t val, int endianness);
void writebufferInt48(SerializeBuffer * first, uint64_t val, int endianness);
void writebufferInt32(SerializeBuffer * first, uint32_t val, int endianness);
void writebufferInt24(SerializeBuffer * first, uint32_t val, int endianness);
void writebufferInt16(SerializeBuffer * first, uint16_t val, int endianness);
void writebufferInt8(SerializeBuffer * first, uint8_t val, int endianness);
void writebufferReal32(SerializeBuffer * first, float val, int endianness);
void writebufferReal64(SerializeBuffer * first, double val, int endianness);

void writebufferOctetStr(SerializeBuffer * node, unsigned char * val, int len, int endianness);
SerializeBuffer * writeNulls(SerializeBuffer * node, unsigned long len);

uint8_t * combineBuffers(SerializeBuffer * first, unsigned long * length);
void freeBuffers(SerializeBuffer * node);


// print utlities are also in serialize
void printOctetStr(FILE * pf, char * name, unsigned char * val, int len, unsigned int indent, int index);

#endif
