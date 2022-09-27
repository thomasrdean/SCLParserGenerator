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
#include "R9_Definitions.h"
#include "R9_Serialize.h"
#include "R9_Print.h"

#include "endian.h"

struct {
       unsigned short a __attribute__((packed)); 	// 32 -- 2 bytes
       unsigned char b[10] ;//__attribute__((packed)); 	// 8 -- 8 bytes
       unsigned char c[5] ;//__attribute__((packed)); 	// 8 -- 8 bytes
} R9;


int main() {

   printf("offset a = %ld\n",(unsigned long)((unsigned long long)&R9.a-(unsigned long long)&R9));
   printf("offset b = %ld\n",(unsigned long)((unsigned long long)&R9.b-(unsigned long long)&R9));
   printf("offset c = %ld\n",(unsigned long)((unsigned long long)&R9.c-(unsigned long long)&R9));

   R9.a = bigEndian16(5);
   memcpy(R9.b,"ABCDEFGHIJ",10);
   memcpy(R9.c,"VWXYZ",5);

   PDU thePDU;
   thePDU.len = sizeof(R9);
   thePDU.remaining = sizeof(R9);
   thePDU.watermark=thePDU.len;
   thePDU.curPos = 0;
   thePDU.curBitPos = 0;
   thePDU.data = (unsigned char *)&R9;
   thePDU.header=NULL;
   unsigned char endianness = BIGENDIAN;

    printf("data=");
    for (int i = 0; i < thePDU.len; i++){
	printf("%02x",thePDU.data[i]);
    }
    printf("\n");

    printf("**********\n");
    PDU_R9 pdu_r9;
    int parsed = parsePDU_R9(&pdu_r9,&thePDU, "R9", endianness);
    if (parsed){
        if (pdu_r9.a != 5) printf("field a is not 5, it is %u\n", pdu_r9.a);
        if (memcmp(pdu_r9.b,"ABCDEFGHIJ",10)!= 0){
	    printf("field b is not ABCDEFGHIJ, it is:");
	    for (int i = 0; i < 10; i++){
	      printf("    '%c'(%x)\n",pdu_r9.b[i], pdu_r9.b[i]);
	    }
	}
	if (pdu_r9.c == NULL){
	    printf("Field C is not allocated\n");
	} else{
	    if(pdu_r9.c_length != 5){
		printf("length of field c is not 5 it is %lu\n",pdu_r9.c_length);
	    }
	    if (memcmp(pdu_r9.c,"VWXYZ",5) != 0)
	    {
		printf("field c is not VWXYZ, it is:\n");
		for (int i = 0; i < 5; i++){
		  printf("    '%c'(%x)\n",pdu_r9.c[i], pdu_r9.c[i]);
		}
	    }
	}
    } else {
	fprintf(stderr,"R9 failed to parse\n");
    }
    printf("**********\n");

    printPDU_R9(stdout,&pdu_r9,0,-1);

    printf("**********\n");

    SerializeBuffer * buff;
    buff = serializePDU_R9 (NULL, &pdu_r9, "R9", endianness);
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
