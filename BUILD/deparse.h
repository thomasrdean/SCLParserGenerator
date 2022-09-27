/*+
 * File:    deparse.h
 *
 * Purpose: Interface to the deparser
 *
-*/

#ifndef DEPARSER
#define DEPARSER

typedef struct DeparseBuffer{
    u_int8_t * buffer;
    int bufferLen;
    int curPos;
    struct DeparseBuffer * next;
    struct DeparseBuffer * first;
};

struct DeparseBuffer * DeparseBufferAllocate(struct DeparseBuffer * current, int size);

void writebufferInt64(struct DeparseBuffer * first,u_int64_t val, int endianness);
void writebufferInt32(struct DeparseBuffer * first,u_int32_t val, int endianness);
void writebufferInt16(struct DeparseBuffer * first,u_int16_t val, int endianness);
void writebufferInt8(struct DeparseBuffer * first,u_int8_t val, int endianness);
void writebufferReal32(struct DeparseBuffer * first,float val, int endianness);
void writebufferReal64(struct DeparseBuffer * first,double val, int endianness);

u_int8_t * combineBuffers(struct DeparseBuffer * first, int * length);

#endif