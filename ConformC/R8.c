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
 * R8 has a type decision to recognize two different messages
 * - both have the same layout
 *
-*/

#include <stdlib.h>
#include <stdio.h>

#include "globals.h"
#include "packet.h"
#include "putilities.h"
#include "sutilities.h"
#include "R8_Definitions.h"
#include "R8_Serialize.h"
#include "R8_Print.h"

#include "endian.h"

struct {
   unsigned char a ;//__attribute__((packed)); 	// 1 -- 8 bytes
   u_int32_t b __attribute__((packed)); 		// 2 -- 4 bytes
} R82;

struct {
   unsigned char c ;//__attribute__((packed)); 	// 1 -- 8 bytes
   u_int32_t d __attribute__((packed)); 		// 2 -- 4 bytes
   u_int32_t e __attribute__((packed)); 		// 6 -- 4 bytes
} R813;


int main() {

    // do R81 first

    printf("Message Type R81 :\n");

    printf("offset c = %ld\n",(unsigned long)((unsigned long long)&R813.c-(unsigned long long)&R813));
    printf("offset d = %ld\n",(unsigned long)((unsigned long long)&R813.d-(unsigned long long)&R813));
    printf("offset e = %ld\n",(unsigned long)((unsigned long long)&R813.e-(unsigned long long)&R813));

    R813.c = 10;
    R813.d = bigEndian32(0xA1A2A3A4);
    R813.e = bigEndian32(0xA5A6A7A8);

    PDU thePDU;
    thePDU.len = sizeof(R813);
    thePDU.remaining = sizeof(R813);
    thePDU.watermark=thePDU.len;
    thePDU.curPos = 0;
    thePDU.curBitPos = 0;
    thePDU.data = (unsigned char *)&R813;
    thePDU.header=NULL;

    printf("data=");
    for (int i = 0; i < thePDU.len; i++){
	printf("%02x",thePDU.data[i]);
    }
    printf("\n");

    printf("**********\n");
    PDU_R8 pdu_r8;
    unsigned char endianness = BIGENDIAN;
    int parsed = parsePDU_R8(&pdu_r8, &thePDU, "R8_1", endianness);
    if (parsed){
	if (pdu_r8.type != R81_R8_VAL) printf("type field is not %d, it is %d\n", R81_R8_VAL,pdu_r8.type);
        if (pdu_r8.item.r81_r8.c != 10) printf("field c is not 10, it is %d\n", pdu_r8.item.r81_r8.c);
        if (pdu_r8.item.r81_r8.d != 0xA1A2A3A4) printf("field d is not 0xA1A2A3A4, it is %x\n", pdu_r8.item.r81_r8.d);
        if (pdu_r8.item.r81_r8.e != 0xA5A6A7A8) printf("field e is not 0xA5A6A7A8, it is %x\n", pdu_r8.item.r81_r8.e);

    } else {
	printf("R8 failed to parse\n");
    }
    printf("**********\n");

    printPDU_R8(stdout,&pdu_r8,-0,-1);

    printf("**********\n");
   
    SerializeBuffer * buff;
    buff = serializePDU_R8 (NULL, &pdu_r8, "R8", endianness);

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
    // do R82 next

    printf("Message Type R82 :\n");
    printf("offset a = %ld\n",(unsigned long)((unsigned long long)&R82.a-(unsigned long long)&R82));
    printf("offset b = %ld\n",(unsigned long)((unsigned long long)&R82.b-(unsigned long long)&R82));

    R82.a = 10;
    R82.b = bigEndian32(0xA1A2A3A4);


    thePDU.len = sizeof(R82);
    thePDU.remaining = sizeof(R82);
    thePDU.watermark=thePDU.len;
    thePDU.curPos = 0;
    thePDU.curBitPos = 0;
    thePDU.data = (unsigned char *)&R82;
    thePDU.header=NULL;

    printf("data=");
    for (int i = 0; i < thePDU.len; i++){
	printf("%02x",thePDU.data[i]);
    }
    printf("\n");

    printf("**********\n");
    parsed = parsePDU_R8(&pdu_r8,&thePDU, "R8_1", endianness);
    if (parsed){
	if (pdu_r8.type != R82_R8_VAL) printf("type field is not 1, it is %d\n", pdu_r8.type);
	if (pdu_r8.item.r82_r8.a != 10) printf("field a is not 10, it is %d\n", pdu_r8.item.r82_r8.a);
        if (pdu_r8.item.r82_r8.b != 0xA1A2A3A4) printf("field b is not 0xA1A2A3A4, it is %x\n", pdu_r8.item.r82_r8.b);

    } else {
	printf("R8 failed to parse\n");
    }
    printf("**********\n");
    printPDU_R8(stdout,&pdu_r8,-0,-1);

    printf("**********\n");

    buff = serializePDU_R8 (NULL, &pdu_r8, "R8", endianness);

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


    // do mesg R83
    printf("3********\n");

    printf("Message Type R83 :\n");

    printf("offset c = %ld\n",(unsigned long)((unsigned long long)&R813.c-(unsigned long long)&R813));
    printf("offset d = %ld\n",(unsigned long)((unsigned long long)&R813.d-(unsigned long long)&R813));
    printf("offset e = %ld\n",(unsigned long)((unsigned long long)&R813.e-(unsigned long long)&R813));

    R813.c = 20;
    R813.d = bigEndian32(0xA1A2A3A4);
    R813.e = bigEndian32(0xA1A2);

    thePDU.len = sizeof(R813);
    thePDU.remaining = sizeof(R813);
    thePDU.watermark=thePDU.len;
    thePDU.curPos = 0;
    thePDU.curBitPos = 0;
    thePDU.data = (unsigned char *)&R813;
    thePDU.header=NULL;

    printf("data=");
    for (int i = 0; i < thePDU.len; i++){
	printf("%02x",thePDU.data[i]);
    }
    printf("\n");

    printf("**********\n");
    parsed = parsePDU_R8(&pdu_r8,&thePDU, "R8_2", endianness);
    if (parsed){
	if (pdu_r8.type != R83_R8_VAL) printf("type field is not 2, it is %d\n", pdu_r8.type);
        if (pdu_r8.item.r83_r8.c != 20) printf("field c is not 20, it is %d\n", pdu_r8.item.r83_r8.c);
        if (pdu_r8.item.r83_r8.d != 0xA1A2A3A4) printf("field d is not 0xA1A2A3A4, it is %x\n", pdu_r8.item.r83_r8.d);
        if (pdu_r8.item.r83_r8.e != 0xA1A2) printf("field e is not 0xA1A2, it is %x\n", pdu_r8.item.r83_r8.e);

    } else {
	printf("R8 failed to parse\n");
    }
    printf("**********\n");
    printPDU_R8(stdout,&pdu_r8,-0,-1);

    printf("**********\n");

    buff = serializePDU_R8 (NULL, &pdu_r8, "R8", endianness);

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
