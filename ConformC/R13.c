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
#include <string.h>

#include "globals.h"
#include "packet.h"
#include "putilities.h"
#include "sutilities.h"
#include "R13_Definitions.h"
#include "R13_Serialize.h"
#include "R13_Print.h"

#include "endian.h"

struct {
       unsigned char t1  __attribute__((packed)); 	// 0 - 1 byte
       unsigned char t2  __attribute__((packed)); 	// 1 - 1 byte
       unsigned char t3  __attribute__((packed)); 	// 2 - 1 byte
       unsigned char t4  __attribute__((packed)); 	// 3 - 1 byte
       unsigned int  d1  __attribute__((packed)); 	// 4 - 4 byte
       union {
	   double d __attribute__((packed));
	   unsigned long long l __attribute__((packed));
       } d2 ; //__attribute__((packed)); 			// 8 -- 8 bytes
       union {
           float f __attribute__((packed));
	   u_int32_t l __attribute__((packed));
       } d3 ; // __attribute((packed));			// 16 -- 4 bytes
} R13a;


int main() {

   // print offsets
    printf("offset t1 = %ld\n",(unsigned long)((unsigned long long)&R13a.t1-(unsigned long long)&R13a));
    printf("offset t2 = %ld\n",(unsigned long)((unsigned long long)&R13a.t2-(unsigned long long)&R13a));
    printf("offset t3 = %ld\n",(unsigned long)((unsigned long long)&R13a.t3-(unsigned long long)&R13a));
    printf("offset t4 = %ld\n",(unsigned long)((unsigned long long)&R13a.t4-(unsigned long long)&R13a));
    printf("offset d1 = %ld\n",(unsigned long)((unsigned long long)&R13a.d1-(unsigned long long)&R13a));
    printf("offset d2 = %ld\n",(unsigned long)((unsigned long long)&R13a.d2-(unsigned long long)&R13a));
    printf("offset d3 = %ld\n",(unsigned long)((unsigned long long)&R13a.d3-(unsigned long long)&R13a));

    R13a.t1 = 1; // integer
    R13a.d1 = bigEndian32(23); // integer value
    R13a.t2 = 3; // double
    R13a.d2.d = 4.5;
    R13a.d2.l = bigEndian64(R13a.d2.l);
    R13a.t3 = 2; // float
    R13a.d3.f = 7.5;
    R13a.d3.l = bigEndian32(R13a.d3.l);
   
    PDU thePDU;
    memset((void*)&thePDU,0,sizeof(thePDU));
    thePDU.len = sizeof(R13a);
    thePDU.remaining = sizeof(R13a);
    thePDU.watermark=thePDU.len;
    thePDU.curPos = 0;
    thePDU.curBitPos = 0;
    thePDU.data = (unsigned char *)&R13a;
    thePDU.header=NULL;
    unsigned char endianness = BIGENDIAN;

    printf("data=");
    for (int i = 0; i < thePDU.len; i++){
	printf("%02x",thePDU.data[i]);
    }
    printf("\n");

    printf("**********\n");
    PDU_R13 pdu_r13a;
    int parsed = parsePDU_R13(&pdu_r13a,&thePDU, "R13", endianness);
    if (parsed){
        // this assumes that the ending of 4.5 is the same as the
	// assignment above
        if (pdu_r13a.t1 != 1) printf("field t1 is not 1, it is %d\n", pdu_r13a.t1);
        if (pdu_r13a.t2 != 3) printf("field t2 is not 3, it is %d\n", pdu_r13a.t2);
        if (pdu_r13a.t3 != 2) printf("field t3 is not 2, it is %d\n", pdu_r13a.t3);
        if (pdu_r13a.t4 != 0) printf("field t4 is not 0, it is %d\n", pdu_r13a.t4);
	if (pdu_r13a.d1 == NULL)
	    printf("failed to generate a data item for d1");
	else  {
	    if (pdu_r13a.d1->type != INT4_R13_VAL) printf("field d1 is not parsed as an integer\n");
	    if (pdu_r13a.d1->item.int4_r13.val != 23) printf("field d13 is not 23, it is %d\n",pdu_r13a.d1->item.int4_r13.val);
	}
	if (pdu_r13a.d2 == NULL)
	    printf("failed to generate a data item for d2");
	else  {
	    if (pdu_r13a.d2->type != DBL8_R13_VAL) printf("field d2 is not parsed as an integer\n");
	    if (pdu_r13a.d2->item.dbl8_r13.val != 4.5) printf("field d2 is not 4.5, it is %lf\n",pdu_r13a.d2->item.dbl8_r13.val);
	}
	if (pdu_r13a.d3 == NULL)
	    printf("failed to generate a data item for d3");
	else  {
	    if (pdu_r13a.d3->type != FLT4_R13_VAL) printf("field d3 is not parsed as an integer\n");
	    if (pdu_r13a.d3->item.flt4_r13.val != 7.5) printf("field d3 is not 7.5, it is %f\n",pdu_r13a.d3->item.flt4_r13.val);
	}
	if (pdu_r13a.d4 != NULL)
	   printf("d4 should not have a value but it does\n");
    } else {
	fprintf(stderr,"R13a failed to parse\n");
    }
    printf("**********\n");
    printPDU_R13(stdout,&pdu_r13a,0, -1);
    printf("**********\n");


    SerializeBuffer * buff;
    buff = serializePDU_R13(NULL, &pdu_r13a, "R13", endianness);
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
