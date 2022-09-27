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
 * R5 has a type decision to recognize two different messages
 * - both have the same layout
 *
-*/

#include <stdlib.h>
#include <stdio.h>

#include "globals.h"
#include "packet.h"
#include "putilities.h"
#include "sutilities.h"
#include "R5_Definitions.h"
#include "R5_Serialize.h"
#include "R5_Print.h"

#include "endian.h"

struct {
   unsigned char a ;//__attribute__((packed)); 	// 1 -- 8 bytes
   u_int32_t b __attribute__((packed)); 		// 2 -- 4 bytes
} R51;

struct {
   unsigned char c ;//__attribute__((packed)); 	// 1 -- 8 bytes
   u_int32_t d __attribute__((packed)); 		// 2 -- 4 bytes
   u_int32_t e __attribute__((packed)); 		// 6 -- 4 bytes
} R52;


int main() {

    // do R51 first
    printf("Message Type R51 :\n");
    printf("offset a = %ld\n",(unsigned long)((unsigned long long)&R51.a-(unsigned long long)&R51));
    printf("offset b = %ld\n",(unsigned long)((unsigned long long)&R51.b-(unsigned long long)&R51));

    R51.a = 10;
    R51.b = bigEndian32(0xA1A2A3A4);


    PDU thePDU;
    thePDU.len = sizeof(R51);
    thePDU.remaining = sizeof(R51);
    thePDU.watermark=thePDU.len;
    thePDU.curPos = 0;
    thePDU.curBitPos = 0;
    thePDU.data = (unsigned char *)&R51;
    thePDU.header=NULL;
    unsigned char endianness = BIGENDIAN;

    printf("data=");
    for (int i = 0; i < thePDU.len; i++){
	printf("%02x",thePDU.data[i]);
    }
    printf("\n");

    PDU_R5 pdu_r5;
    printf("**********\n");
    int parsed = parsePDU_R5(&pdu_r5,&thePDU, "R5_1", endianness);
    if (parsed){
	if (pdu_r5.type != R51_R5_VAL) printf("type field is not 1, it is %d\n", pdu_r5.type);
	if (pdu_r5.item.r51_r5.a != 10) printf("field a is not 10, it is %d\n", pdu_r5.item.r51_r5.a);
        if (pdu_r5.item.r51_r5.b != 0xA1A2A3A4) printf("field b is not 0xA1A2A3A4, it is %x\n", pdu_r5.item.r51_r5.b);

    } else {
	printf("R5 failed to parse\n");
    }

    printf("**********\n");
    printPDU_R5(stdout,&pdu_r5,0,-1);
    printf("**********\n");

    SerializeBuffer * buff;
    buff = serializePDU_R5 (NULL, &pdu_r5, "R5_1", endianness);

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

    printf("52**********\n");
    // do mesg R52

    printf("Message Type R52 :\n");

    printf("offset c = %ld\n",(unsigned long)((unsigned long long)&R52.c-(unsigned long long)&R52));
    printf("offset d = %ld\n",(unsigned long)((unsigned long long)&R52.d-(unsigned long long)&R52));
    printf("offset e = %ld\n",(unsigned long)((unsigned long long)&R52.e-(unsigned long long)&R52));

    R52.c = 20;
    R52.d = bigEndian32(0xA1A2A3A4);
    R52.e = bigEndian32(0xA1A2);

    thePDU.len = sizeof(R52);
    thePDU.remaining = sizeof(R52);
    thePDU.watermark=thePDU.len;
    thePDU.curPos = 0;
    thePDU.curBitPos = 0;
    thePDU.data = (unsigned char *)&R52;
    thePDU.header=NULL;

    printf("data=");
    for (int i = 0; i < thePDU.len; i++){
	printf("%02x",thePDU.data[i]);
    }
    printf("\n");

    printf("**********\n");

    parsed = parsePDU_R5(&pdu_r5,&thePDU, "R5_2", endianness);
    if (parsed){
	if (pdu_r5.type != R52_R5_VAL) printf("type field is not 2, it is %d\n", pdu_r5.type);
        if (pdu_r5.item.r52_r5.c != 20) printf("field c is not 20, it is %d\n", pdu_r5.item.r52_r5.c);
        if (pdu_r5.item.r52_r5.d != 0xA1A2A3A4) printf("field d is not 0xA1A2A3A4, it is %x\n", pdu_r5.item.r52_r5.d);
        if (pdu_r5.item.r52_r5.e != 0xA1A2) printf("field e is not 0xA1A2, it is %x\n", pdu_r5.item.r52_r5.e);

    } else {
	printf("R5 failed to parse\n");
    }
    printf("**********\n");
    printPDU_R5(stdout,&pdu_r5,0,-1);
    printf("**********\n");

    buff = serializePDU_R5 (NULL, &pdu_r5, "R5_2", endianness);
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
