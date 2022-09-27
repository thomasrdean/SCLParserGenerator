/*+
 * Regression Program R3
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
#include "R10_Definitions.h"
#include "R10_Serialize.h"
#include "R10_Print.h"

#include "endian.h"

struct {
   unsigned short a __attribute__((packed)); 
   unsigned char b[10] ;//__attribute__((packed));
} C1;

struct {
   unsigned char a ;//__attribute__((packed)); 
   unsigned char b[10] ;//__attribute__((packed)); 
} C2;


int main() {

    printf("offset C1.a = %ld\n",(unsigned long)((unsigned long long)&C1.a-(unsigned long long)&C1));
    printf("offset C1.b = %ld\n",(unsigned long)((unsigned long long)&C1.b-(unsigned long long)&C1));

    C1.a = bigEndian16(2);
    memcpy(C1.b,"ABCDEFGHIJ",10);

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
    PDU_R10 pdu_r10;
    int parsed = parsePDU_R10(&pdu_r10, &thePDU, "R10", endianness);
    if (parsed){
        if (pdu_r10.type != C1_R10_VAL){
	    printf("C1 was not parsed as a C1\n");
	} else {
	    if (pdu_r10.item.c1_r10.a != 2) printf("field a is not 2, it is %u\n", pdu_r10.item.c1_r10.a);
	    if (memcmp(pdu_r10.item.c1_r10.b,"ABCDEFGHIJ",10)!= 0){
		printf("field b is not ABCDEFGHIJ, it is:");
		for (int i = 0; i < 10; i++){
		  printf("    '%c'(%x)\n",pdu_r10.item.c1_r10.b[i], pdu_r10.item.c1_r10.b[i]);
		}
	    }
	}
    } else {
	fprintf(stderr,"R10 C1 failed to parse\n");
    }
    printf("**********\n");

    printPDU_R10(stdout,&pdu_r10,0,-1);

    printf("**********\n");

    SerializeBuffer * buff;
    buff = serializePDU_R10 (NULL, &pdu_r10, "R10", endianness);

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
    buff = NULL;

    printf("2**********\n");

    printf("offset C2.a = %ld\n",(unsigned long)((unsigned long long)&C2.a-(unsigned long long)&C2));
    printf("offset C2.b = %ld\n",(unsigned long)((unsigned long long)&C2.b-(unsigned long long)&C2));

    C2.a = 3;
    memcpy(C2.b,"ABCDEFGHIJ",10);

    thePDU.len = sizeof(C2);
    thePDU.remaining = sizeof(C2);
    thePDU.watermark=thePDU.len;
    thePDU.curPos = 0;
    thePDU.curBitPos = 0;
    thePDU.data = (unsigned char *)&C2;
    thePDU.header=NULL;
    endianness = BIGENDIAN;

    printf("data=");
    for (int i = 0; i < thePDU.len; i++){
	printf("%02x",thePDU.data[i]);
    }
    printf("\n");

    printf("**********\n");
    parsed = parsePDU_R10(&pdu_r10, &thePDU, "R10", endianness);
    if (parsed){
        if (pdu_r10.type != C2_R10_VAL){
	    printf("C2 was not parsed as a C2\n");
	} else {
	    if (pdu_r10.item.c2_r10.a != 3) printf("field a is not 3, it is %u\n", pdu_r10.item.c2_r10.a);
	    if (memcmp(pdu_r10.item.c2_r10.b,"ABCDEFGHIJ",10)!= 0){
		printf("field b is not ABCDEFGHIJ, it is:");
		for (int i = 0; i < 10; i++){
		  printf("    '%c'(%x)\n",pdu_r10.item.c2_r10.b[i], pdu_r10.item.c2_r10.b[i]);
		}
	    }
	}
    } else {
	fprintf(stderr,"R10 C2 failed to parse\n");
    }

    printf("**********\n");

    printPDU_R10(stdout,&pdu_r10,0,-1);

    printf("**********\n");

    buff = serializePDU_R10 (NULL, &pdu_r10, "R10", endianness);

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
