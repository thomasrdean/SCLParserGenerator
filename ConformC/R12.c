/*+
 * Regression Program R11
 *
 * Note, for endianness, this program was written on intel which is little endian
 * 
-*/

#include <stdlib.h>
#include <stdio.h>

#include "globals.h"
#include "packet.h"
#include "putilities.h"
#include "sutilities.h"
#include "R12_Definitions.h"
#include "R12_Serialize.h"
#include "R12_Print.h"

#include "endian.h"

struct C2{
   unsigned char a ;//__attribute__((packed)); 
   unsigned short b __attribute__((packed)); 
};

struct {
   unsigned short a __attribute__((packed)); 
   struct C2 b[2];// __attribute__((packed));
   unsigned short c __attribute__((packed)); 
} C1;



int main() {

    printf("offset C1.a = %ld\n",(unsigned long)((unsigned long long)&C1.a-(unsigned long long)&C1));
    printf("offset C1.b[0] = %ld\n",(unsigned long)((unsigned long long)&C1.b[0]-(unsigned long long)&C1));
    printf("offset C1.b[1] = %ld\n",(unsigned long)((unsigned long long)&C1.b[1]-(unsigned long long)&C1));
    printf("offset C1.c = %ld\n",(unsigned long)((unsigned long long)&C1.c-(unsigned long long)&C1));

    C1.a = bigEndian16(6);
    C1.b[0].a= 0xA1;
    C1.b[0].b= bigEndian16(0xA2A3);
    C1.b[1].a= 0xA4;
    C1.b[1].b= bigEndian16(0xA5A6);
    C1.c = bigEndian16(0xA7A8);

    PDU thePDU;
    thePDU.len = sizeof(C1);
    thePDU.remaining = sizeof(C1);
    thePDU.watermark=thePDU.len;
    thePDU.curPos = 0;
    thePDU.curBitPos = 0;
    thePDU.data = (unsigned char *)&C1;
    thePDU.header=NULL;
    unsigned char endianness = BIGENDIAN;

    printf("data=");
    for (int i = 0; i < thePDU.len; i++){
	printf("%02x",thePDU.data[i]);
    }
    printf("\n");

    printf("**********\n");
    PDU_R12 pdu_r12;
    int parsed = parsePDU_R12(&pdu_r12, &thePDU, "R12", endianness);
    if (parsed){
	if (pdu_r12.a != 6) printf("field a is not 6, it is %u\n", pdu_r12.a);
	if (pdu_r12.bcount != 2)printf("count of b is not 2, it is %lu\n", pdu_r12.bcount);
	if (pdu_r12.blength != 6)printf("length of b is not 6, it is %lu\n", pdu_r12.blength);
	if (pdu_r12.b[0].a != 0xA1) printf("b[0].a is not 0xA1, it is %x\n", pdu_r12.b[0].a);
	if (pdu_r12.b[0].b != 0xA2A3) printf("b[0].a is not 0xA2A3, it is %x\n", pdu_r12.b[0].b);
	if (pdu_r12.b[1].a != 0xA4) printf("b[1].a is not 0xA4, it is %x\n", pdu_r12.b[1].a);
	if (pdu_r12.b[1].b != 0xA5A6) printf("b[1].a is not 0xA5A6, it is %x\n", pdu_r12.b[1].b);
	if (pdu_r12.c != 0xA7A8) printf("field c is not 0xA7A8, it is %x\n", pdu_r12.c);
    } else {
	fprintf(stderr,"R12 failed to parse\n");
    }
    printf("**********\n");
    printPDU_R12(stdout,&pdu_r12,0,-1);
    printf("**********\n");

    SerializeBuffer * buff;
    buff = serializePDU_R12 (NULL, &pdu_r12, "R12", endianness);
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
