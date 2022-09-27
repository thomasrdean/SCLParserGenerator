/*+
 * Regression Program R3
 *
 * Note, for endianness, this program was written on intel which is little endian
 * 
 * SCL5 defaults to the parser default of big endian for each of the types:
 *	Real 8
 *	Integer 8
 *	Real 4	
 *	Integer 4
 *	Integer 2
 *	integer 1
 *
-*/

#include <stdlib.h>
#include <stdio.h>

#include "globals.h"
#include "packet.h"
#include "putilities.h"
#include "sutilities.h"
#include "R3_Definitions.h"
#include "R3_Serialize.h"
#include "R3_Print.h"

#include "endian.h"

struct {
    union {
	double d __attribute__((packed));
	unsigned long long l __attribute__((packed));
    } a ;//__attribute__((packed)); 			// 0 -- 8 bytes
    unsigned long long b __attribute__((packed)); 	// 8 -- 8 bytes
    union {
	float f __attribute__((packed));
	u_int32_t l __attribute__((packed));
    } c ;//__attribute((packed));			// 16 -- 4 bytes
    u_int32_t d __attribute__((packed)); 		// 24 -- 4 bytes
    unsigned short e __attribute__((packed)); 	// 32 -- 2 bytes
    unsigned char f;// __attribute__((packed)); 	// 34
} R3;


int main() {

    printf("offset a = %ld\n",(unsigned long)((unsigned long long)&R3.a-(unsigned long long)&R3));
    printf("offset b = %ld\n",(unsigned long)((unsigned long long)&R3.b-(unsigned long long)&R3));
    printf("offset c = %ld\n",(unsigned long)((unsigned long long)&R3.c-(unsigned long long)&R3));
    printf("offset d = %ld\n",(unsigned long)((unsigned long long)&R3.d-(unsigned long long)&R3));
    printf("offset e = %ld\n",(unsigned long)((unsigned long long)&R3.e-(unsigned long long)&R3));
    printf("offset f = %ld\n",(unsigned long)((unsigned long long)&R3.f-(unsigned long long)&R3));

    R3.a.d = 45.5;
    R3.a.l = bigEndian64(R3.a.l);
    R3.b = bigEndian64(0xA1A2A3A4A5A6A7A8);
    R3.c.f = 45.5;
    R3.c.l = bigEndian32(R3.c.l);
    R3.d = bigEndian32(0xA1A2A3A4);
    R3.e = bigEndian16(0xA1A2);
    R3.f = 0xA5;

    PDU thePDU;
    thePDU.len = sizeof(R3);
    thePDU.remaining = sizeof(R3);
    thePDU.watermark=thePDU.len;
    thePDU.curPos = 0;
    thePDU.curBitPos = 0;
    thePDU.data = (unsigned char *)&R3;
    thePDU.header=NULL;
    unsigned char endianness = BIGENDIAN;

    printf("data=");
    for (int i = 0; i < thePDU.len; i++){
	printf("%02x",thePDU.data[i]);
    }
    printf("\n");

    printf("**********\n");
    PDU_R3 pdu_r3;
    int parsed = parsePDU_R3(&pdu_r3,&thePDU, "R3", endianness);
    if (parsed){
        if (pdu_r3.a != 45.5) printf("field a is not 45.5, it is %f\n", pdu_r3.a);
        if (pdu_r3.b != 0xA1A2A3A4A5A6A7A8) printf("field b is not 0xA1A2A3A4A5A6A7A8, it is %" PRIx64 "\n", pdu_r3.b);
        if (pdu_r3.c != 45.5) printf("field c is not 45.5, it is %f\n", pdu_r3.c);
        if (pdu_r3.d != 0xA1A2A3A4) printf("field d is not 0xA1A2A3A4, it is %x\n", pdu_r3.d);
        if (pdu_r3.e != 0xA1A2) printf("field e is not 0xA1A2, it is %x\n", pdu_r3.e);
        if (pdu_r3.f != 0xA5) printf("field f is not 0xA5, it is %x\n", pdu_r3.f);
    } else {
	fprintf(stderr,"R3 failed to parse\n");
    }
    printf("**********\n");

    printPDU_R3(stdout,&pdu_r3,0,-1);

    printf("**********\n");

    SerializeBuffer * buff;
    buff = serializePDU_R3 (NULL, &pdu_r3, "R3", endianness);
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
}
