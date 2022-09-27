/*+
 * Regression Program R4
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
 * R4 has the same binary layout as R3 but split into two separate sub-structures.
 *
-*/

#include <stdlib.h>
#include <stdio.h>

#include "globals.h"
#include "packet.h"
#include "putilities.h"
#include "sutilities.h"
#include "R4_Definitions.h"
#include "R4_Serialize.h"
#include "R4_Print.h"

#include "endian.h"

struct {
    union {
	double d __attribute__((packed));
	unsigned long long l __attribute__((packed));
    } a;// __attribute__((packed)); 			// 0 -- 8 bytes
    unsigned long long b __attribute__((packed)); 	// 8 -- 8 bytes
    union {
	float f __attribute__((packed));
	u_int32_t l __attribute__((packed));
    } c ;//__attribute((packed));			// 16 -- 4 bytes
    u_int32_t d __attribute__((packed)); 		// 24 -- 4 bytes
    unsigned short e __attribute__((packed)); 	// 32 -- 2 bytes
    unsigned char f;// __attribute__((packed)); 	// 34
} R4;


int main() {

    printf("offset a = %ld\n",(unsigned long)((unsigned long long)&R4.a-(unsigned long long)&R4));
    printf("offset b = %ld\n",(unsigned long)((unsigned long long)&R4.b-(unsigned long long)&R4));
    printf("offset c = %ld\n",(unsigned long)((unsigned long long)&R4.c-(unsigned long long)&R4));
    printf("offset d = %ld\n",(unsigned long)((unsigned long long)&R4.d-(unsigned long long)&R4));
    printf("offset e = %ld\n",(unsigned long)((unsigned long long)&R4.e-(unsigned long long)&R4));
    printf("offset f = %ld\n",(unsigned long)((unsigned long long)&R4.f-(unsigned long long)&R4));

    R4.a.d = 45.5;
    R4.a.l = bigEndian64(R4.a.l);
    R4.b = bigEndian64(0xA1A2A3A4A5A6A7A8);
    R4.c.f = 45.5;
    R4.c.l = bigEndian32(R4.c.l);
    R4.d = bigEndian32(0xA1A2A3A4);
    R4.e = bigEndian16(0xA1A2);
    R4.f = 0xA5;

    PDU thePDU;
    thePDU.len = sizeof(R4);
    thePDU.remaining = sizeof(R4);
    thePDU.watermark=thePDU.len;
    thePDU.curPos = 0;
    thePDU.curBitPos = 0;
    thePDU.data = (unsigned char *)&R4;
    thePDU.header=NULL;
    unsigned char endianness = BIGENDIAN;

    printf("data=");
    for (int i = 0; i < thePDU.len; i++){
	printf("%02x",thePDU.data[i]);
    }
    printf("\n");

    printf("**********\n");
    PDU_R4 pdu_r4;
    int parsed = parsePDU_R4(&pdu_r4,&thePDU, "R4", endianness);
    if (parsed){
	if (pdu_r4.s1.a != 45.5) printf("field a is not 45.5, it is %f\n", pdu_r4.s1.a);
	//if (pdu_r4.s1.b != 0xA1A2A3A4A5A6A7A8) printf("field b is not 0xA1A2A3A4A5A6A7A8, it is %lx\n", pdu_r4.s1.b);
	if (pdu_r4.s1.b != 0xA1A2A3A4A5A6A7A8) printf("field b is not 0xA1A2A3A4A5A6A7A8, it is %" PRIx64 "\n", pdu_r4.s1.b);
	if (pdu_r4.s1.c != 45.5) printf("field c is not 45.5, it is %f\n", pdu_r4.s1.c);
	if (pdu_r4.s2.d != 0xA1A2A3A4) printf("field d is not 0xA1A2A3A4, it is %x\n", pdu_r4.s2.d);
	if (pdu_r4.s2.e != 0xA1A2) printf("field e is not 0xA1A2, it is %x\n", pdu_r4.s2.e);
	if (pdu_r4.s2.f != 0xA5) printf("field f is not 0xA5, it is %x\n", pdu_r4.s2.f);
    } else {
	fprintf(stderr,"R4 failed to parse\n");
    }

    printf("**********\n");

    printPDU_R4(stdout,&pdu_r4,0,-1);

    printf("**********\n");

    SerializeBuffer * buff;
    buff = serializePDU_R4 (NULL, &pdu_r4, "R4", endianness);
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
