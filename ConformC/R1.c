/*+
 * Regression Program R1
 *
 * Note, for endianness, this program was written on intel which is little endian
 * 
 * SCL5 contains explicit little endian for each of the 6 types
 *	Real 8
 *	Integer 8
 *	Real 4	
 *	Integer 4
 *	Integer 2
 *	integer 1
-*/

#include <stdlib.h>
#include <stdio.h>

#include "globals.h"
#include "packet.h"
#include "putilities.h"
#include "sutilities.h"
#include "R1_Definitions.h"
#include "R1_Serialize.h"
#include "R1_Print.h"

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
       } c;// __attribute((packed));			// 16 -- 4 bytes
       u_int32_t d __attribute__((packed)); 		// 24 -- 4 bytes
       unsigned short e __attribute__((packed)); 	// 32 -- 2 bytes
       unsigned char f ;//__attribute__((packed)); 	// 34
} R1;


int main() {

   // print offsets
    printf("offset a = %ld\n",(unsigned long)((unsigned long long)&R1.a-(unsigned long long)&R1));
    printf("offset b = %ld\n",(unsigned long)((unsigned long long)&R1.b-(unsigned long long)&R1));
    printf("offset c = %ld\n",(unsigned long)((unsigned long long)&R1.c-(unsigned long long)&R1));
    printf("offset d = %ld\n",(unsigned long)((unsigned long long)&R1.d-(unsigned long long)&R1));
    printf("offset e = %ld\n",(unsigned long)((unsigned long long)&R1.e-(unsigned long long)&R1));
    printf("offset f = %ld\n",(unsigned long)((unsigned long long)&R1.f-(unsigned long long)&R1));

    R1.a.d = 4.5;
    R1.a.l = littleEndian64(R1.a.l);
    R1.b = littleEndian64(0xA1A2A3A4A5A6A7A8);
    R1.c.f = 45.5;
    R1.c.l = littleEndian32(R1.c.l);
    R1.d = littleEndian32(0xA1A2A3A4);
    R1.e = littleEndian16(0xA1A2);
    R1.f = 0xA5;

    PDU thePDU;
    thePDU.len = sizeof(R1);
    thePDU.remaining = sizeof(R1);
    thePDU.watermark=thePDU.len;
    thePDU.curPos = 0;
    thePDU.curBitPos = 0;
    thePDU.data = (unsigned char *)&R1;
    thePDU.header=NULL;
    unsigned char endianness = BIGENDIAN;

    printf("data=");
    for (int i = 0; i < thePDU.len; i++){
	printf("%02x",thePDU.data[i]);
    }
    printf("\n");

    printf("**********\n");
    PDU_R1 pdu_r1;
    int parsed = parsePDU_R1(&pdu_r1,&thePDU, "R1", endianness);
    if (parsed){
        // this assumes that the ending of 4.5 is the same as the
	// assignment above
        if (pdu_r1.a != 4.5) printf("field a is not 4.5, it is %f\n", pdu_r1.a);
        if (pdu_r1.b != 0xA1A2A3A4A5A6A7A8) printf("field b is not 0xA1A2A3A4A5A6A7A8, it is %" PRIx64 "\n", pdu_r1.b);
        if (pdu_r1.c != 45.5) printf("field c is not 45.5, it is %f\n", pdu_r1.c);
        if (pdu_r1.d != 0xA1A2A3A4) printf("field d is not 0xA1A2A3A4, it is %x\n", pdu_r1.d);
        if (pdu_r1.e != 0xA1A2) printf("field e is not 0xA1A2, it is %x\n", pdu_r1.e);
        if (pdu_r1.f != 0xA5) printf("field f is not 0xA5, it is %x\n", pdu_r1.f);
    } else {
	fprintf(stderr,"R1 failed to parse\n");
    }
    printf("**********\n");
    printPDU_R1(stdout,&pdu_r1,0, -1);

    printf("**********\n");

    SerializeBuffer * buff;
    buff = serializePDU_R1 (NULL, &pdu_r1, "R1", endianness);

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
