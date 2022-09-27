/*+
 * Regression Program R6
 *
 * Note, for endianness, this program was written on intel which is little endian
 * 
 * SCL5 defaults to the parser default of big endian for each of the types:
 * Main PDU has two fields each 2 bytes long, followed by an optional field
 * that also contians two two byte fields. Based on the length of the PDU
 *
 *
 * Test is two parts. Fill out all four field, pass with length of only first
 * two fields, and pass with length of all fields.
 *
-*/

#include <stdlib.h>
#include <stdio.h>

#include "globals.h"
#include "packet.h"
#include "putilities.h"
#include "sutilities.h"
#include "R6_Definitions.h"
#include "R6_Serialize.h"
#include "R6_Print.h"

#include "endian.h"

struct {
    unsigned short a __attribute__((packed));	// 0 -- 2 bytes
    unsigned short b __attribute__((packed)); 	// 2 -- 2 bytes
    unsigned short c __attribute__((packed)); 	// 4 -- 2 bytes
    unsigned short d __attribute__((packed)); 	// 6 -- 2 bytes
} R6;


int main() {

    printf("offset a = %ld\n",(unsigned long)((unsigned long long)&R6.a-(unsigned long long)&R6));
    printf("offset b = %ld\n",(unsigned long)((unsigned long long)&R6.b-(unsigned long long)&R6));
    printf("offset c = %ld\n",(unsigned long)((unsigned long long)&R6.c-(unsigned long long)&R6));
    printf("offset d = %ld\n",(unsigned long)((unsigned long long)&R6.d-(unsigned long long)&R6));

    R6.a = bigEndian16(0xA1A2);
    R6.b = bigEndian16(0xA3A4);
    R6.c = bigEndian16(0xA5A6);
    R6.d = bigEndian16(0xA7A8);

    // only first two fields
    PDU thePDU;
    thePDU.len = 4;
    thePDU.remaining = 4;
    thePDU.watermark=thePDU.len;
    thePDU.curPos = 0;
    thePDU.curBitPos = 0;
    thePDU.data = (unsigned char *)&R6;
    thePDU.header=NULL;
    unsigned char endianness = BIGENDIAN;

    printf("data=");
    for (int i = 0; i < thePDU.len; i++){
	printf("%02x",thePDU.data[i]);
    }
    printf("\n");

    printf("**********\n");
    PDU_R6 pdu_r6;
    int parsed = parsePDU_R6(&pdu_r6,&thePDU, "R6", endianness);
    if (parsed){
        if (pdu_r6.a != 0xA1A2) printf("field a is not 0xA1A2, it is %x\n", pdu_r6.a);
        if (pdu_r6.b != 0xA3A4) printf("field a is not 0xA3A4, it is %x\n", pdu_r6.b);
    } else {
	fprintf(stderr,"R6 failed to parse\n");
    }
    printf("**********\n");
    printPDU_R6(stdout,&pdu_r6,0,-1);
    printf("**********\n");

    SerializeBuffer * buff;
    buff = serializePDU_R6 (NULL, &pdu_r6, "R6", endianness);

    printf("**********\n");

    unsigned long len;
    unsigned char * sdata = combineBuffers(buff,&len);

    if (len != thePDU.len){
        printf("serialized size doesn't agree: %lu, %lu\n", thePDU.len, len);
    }

    if (memcmp(sdata,thePDU.data,len) != 0){
        printf("serialized data is different\n");
        printf("serialized data=");
        for (int i = 0; i < len; i++){
            printf("%02x",sdata[i]);
        }
        printf("\n");
    }
    freeBuffers(buff);
    buff=NULL;

    printf("2**********\n");

    // All fields
    thePDU.len = 8;
    thePDU.remaining = 8;
    thePDU.curPos = 0;
    thePDU.curBitPos = 0;

    printf("data=");
    for (int i = 0; i < thePDU.len; i++){
	printf("%02x",thePDU.data[i]);
    }
    printf("\n");

    printf("**********\n");
    parsed = parsePDU_R6(&pdu_r6,&thePDU, "R6", endianness);
    if (parsed){
	if (pdu_r6.a != 0xA1A2) printf("field a is not 0xA1A2, it is %x\n", pdu_r6.a);
	if (pdu_r6.b != 0xA3A4) printf("field b is not 0xA3A4, it is %x\n", pdu_r6.b);
	if (pdu_r6.x->c != 0xA5A6) printf("field c is not 0xA5A6, it is %x\n", pdu_r6.x->c);
	if (pdu_r6.x->d != 0xA7A8) printf("field d is not 0xA7A8, it is %x\n", pdu_r6.x->d);
    } else {
	fprintf(stderr,"R6 failed to parse\n");
    }
    printf("**********\n");
    printPDU_R6(stdout,&pdu_r6,0,-1);
    printf("**********\n");

    buff = serializePDU_R6 (NULL, &pdu_r6, "R6", endianness);

    printf("**********\n");

    sdata = combineBuffers(buff,&len);

    if (len != thePDU.len){
        printf("serialized size doesn't agree: %lu, %lu\n", thePDU.len, len);
    }

    if (memcmp(sdata,thePDU.data,len) != 0){
        printf("serialized data is different\n");
        printf("serialized data=");
        for (int i = 0; i < len; i++){
            printf("%02x",sdata[i]);
        }
        printf("\n");
    }
    freeBuffers(buff);
}
