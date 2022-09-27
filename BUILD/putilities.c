#include "putilities.h"
#include "string.h"


bool lengthRemaining(PDU * thePDU, unsigned long length, char * name) {
	if(thePDU->remaining >= length) {
		//thePDU->remaining -= length;
		return true;
	} else {
		//fprintf(stderr,"%s: PDU Length Error file: %s line: %d\n",name, __FILE__ , __LINE__);
		return false;
	}   
}

bool checkSlack(PDU * thePDU, unsigned long len) {
	while(len > 0) {
		if(thePDU->data[thePDU->curPos++] != '\0')
			return false;
		len--;
	};
	return true;
}

uint8_t get8_e(PDU * thePDU, uint8_t endianness) {
	return thePDU->data[thePDU->curPos++];
}

uint8_t la8_e(PDU * thePDU, unsigned long offset, uint8_t endianness) {
	return thePDU->data[thePDU->curPos+offset];
}


uint16_t get16_e(PDU * thePDU, uint8_t endianness) {
	uint16_t result;
	if((endianness & 0x1) == LITTLEENDIAN) //Little Endian
		result = thePDU->data[thePDU->curPos++] |
					thePDU->data[thePDU->curPos++]<< 8;
	else //Big Endian
		result = thePDU->data[thePDU->curPos++] << 8 | 
					  thePDU->data[thePDU->curPos++];

	return result;
}

uint16_t la16_e(PDU * thePDU, unsigned long offset, uint8_t endianness) {
	uint16_t result;
	if((endianness & 0x1) == LITTLEENDIAN) //Little Endian
		result = thePDU->data[thePDU->curPos+offset] |
					thePDU->data[thePDU->curPos+offset+1] << 8;
	else //Big Endian
		result = thePDU->data[thePDU->curPos+offset] << 8 | 
					  thePDU->data[thePDU->curPos+offset+1];

	return result;
}

uint32_t get24_e(PDU * thePDU, uint8_t endianness) {
	uint32_t result = 0;
	if((endianness & 0x1) == LITTLEENDIAN) //Little Endian
		result = thePDU->data[thePDU->curPos++] |
					thePDU->data[thePDU->curPos++] << 8 |
					thePDU->data[thePDU->curPos++] << 16;
	else //Big Endian
		result = thePDU->data[thePDU->curPos++] << 16 |
					thePDU->data[thePDU->curPos++] << 8 | 
					  thePDU->data[thePDU->curPos++];

	return result;
}

uint32_t la24_e(PDU * thePDU, unsigned long offset, uint8_t endianness) {
	uint32_t result = 0;
	if((endianness & 0x1) == LITTLEENDIAN) //Little Endian
		result = thePDU->data[thePDU->curPos+offset] |
					thePDU->data[thePDU->curPos+offset + 1] << 8 |
					thePDU->data[thePDU->curPos+offset + 2] << 16;
	else //Big Endian
		result = thePDU->data[thePDU->curPos+offset] << 16 |
					thePDU->data[thePDU->curPos+offset + 1] << 8 |
					  thePDU->data[thePDU->curPos+offset + 2];

	return result;
}

uint32_t get32_e(PDU * thePDU, uint8_t endianness) {
	uint32_t result;
	if((endianness & 0x1) == LITTLEENDIAN) //Little Endian
		result = thePDU->data[thePDU->curPos++] |
					thePDU->data[thePDU->curPos++] << 8 |
					thePDU->data[thePDU->curPos++] << 16 |
					thePDU->data[thePDU->curPos++] << 24;
	else //Big Endian
		result = thePDU->data[thePDU->curPos++] << 24 | 
					thePDU->data[thePDU->curPos++] << 16 | 
					thePDU->data[thePDU->curPos++] << 8 | 
					thePDU->data[thePDU->curPos++];
	return result;
}

uint32_t la32_e(PDU * thePDU, unsigned long offset, uint8_t endianness) {
	uint32_t result;
	if((endianness & 0x1) == LITTLEENDIAN) //Little Endian
		result = thePDU->data[thePDU->curPos+offset] |
					thePDU->data[thePDU->curPos+offset+1] << 8 |
					thePDU->data[thePDU->curPos+offset+2] << 16 |
					thePDU->data[thePDU->curPos+offset+3] << 24;
	else //Big Endian
		result = thePDU->data[thePDU->curPos+offset] << 24 | 
					thePDU->data[thePDU->curPos+offset+1] << 16 | 
					thePDU->data[thePDU->curPos+offset+2] << 8 | 
					thePDU->data[thePDU->curPos+offset+3];
	return result;
}

uint64_t get48_e(PDU * thePDU, uint8_t endianness) {
	uint64_t result;
	//NOTE: ASSUMING ONLY BIGENDIAN (USED FOR ARP)
	result = (uint64_t)0x0000 << 46 |
					(uint64_t)thePDU->data[thePDU->curPos++] << 40 | 
					(uint64_t)thePDU->data[thePDU->curPos++] << 32 | 
					(uint64_t)thePDU->data[thePDU->curPos++] << 24 |
					(uint64_t)thePDU->data[thePDU->curPos++] << 16 |
					(uint64_t)thePDU->data[thePDU->curPos++] << 8 |
					(uint64_t)thePDU->data[thePDU->curPos++];
	return result;
}

uint64_t la48_e(PDU * thePDU, unsigned long offset, uint8_t endianness) {
	uint64_t result;
	//NOTE: ASSUMING ONLY BIGENDIAN (USED FOR ARP)
	result = (uint64_t)0x0000 << 46 |
					(uint64_t)thePDU->data[thePDU->curPos+offset] << 40 |
					(uint64_t)thePDU->data[thePDU->curPos+offset+1] << 32 |
                                        (uint64_t)thePDU->data[thePDU->curPos+offset+2] << 24 |
                                        (uint64_t)thePDU->data[thePDU->curPos+offset+3] << 16 |
                                        (uint64_t)thePDU->data[thePDU->curPos+offset+4] << 8 |
                                        (uint64_t)thePDU->data[thePDU->curPos+offset+5];
	return result;
}

uint64_t get64_e(PDU * thePDU, uint8_t endianness) {
	uint64_t result;
	if((endianness & 0x1) == LITTLEENDIAN) 
		result = ((uint64_t)get32_e(thePDU,endianness)) | ((uint64_t)get32_e(thePDU,endianness) << 32);
	else{
	    //uint64_t top  = ((uint64_t)get32_e(thePDU, endianness) << 32);
	    //fprintf(stderr,"top = %llx\n",top);
	    //uint64_t bottom = ((uint64_t)get32_e(thePDU, endianness));
	    //fprintf(stderr,"bottom = %llx\n",bottom);
	    //result = top | bottom;
	    result = ((uint64_t)get32_e(thePDU, endianness) << 32) | ((uint64_t)get32_e(thePDU, endianness));
	}
	return result;
}

uint64_t la64_e(PDU * thePDU, unsigned long offset, uint8_t endianness) {
	uint64_t result;
	if((endianness & 0x1) == LITTLEENDIAN) 
		result = ((uint64_t)la32_e(thePDU, offset, endianness)) | ((uint64_t)la32_e(thePDU, offset+4, endianness) << 32);
	else{
	    //uint64_t top  = ((uint64_t)get32_e(thePDU, endianness) << 32);
	    //fprintf(stderr,"top = %llx\n",top);
	    //uint64_t bottom = ((uint64_t)get32_e(thePDU, endianness));
	    //fprintf(stderr,"bottom = %llx\n",bottom);
	    //result = top | bottom;
	    result = ((uint64_t)la32_e(thePDU, offset, endianness) << 32) | ((uint64_t)la32_e(thePDU, offset+4, endianness));
	}
	return result;
}

float getReal4_e(PDU * thePDU, uint8_t endianness) {
	uint32_t i = get32_e(thePDU, endianness);
 	return *((float *)&i);
}

float laReal4_e(PDU * thePDU, unsigned long offset, uint8_t endianness) {
	uint32_t i = la32_e(thePDU, offset, endianness);
 	return *((float *)&i);
}

double getReal8_e(PDU * thePDU, uint8_t endianness) {
	uint64_t i = get64_e(thePDU, endianness);
 	return *((double *)&i);
}

double laReal8_e(PDU * thePDU, unsigned long offset, uint8_t endianness) {
	uint64_t i = la64_e(thePDU, offset, endianness);
 	return *((double *)&i);
}

uint8_t get8(PDU * thePDU) {
	return thePDU->data[thePDU->curPos++];;
}

uint16_t get16(PDU * thePDU) {
	return get16_e(thePDU, BIGENDIAN);
}

uint32_t get24(PDU * thePDU)  {
	return get24_e(thePDU, BIGENDIAN);
}

uint32_t get32(PDU * thePDU) {
	return get32_e(thePDU, BIGENDIAN);
}

uint64_t get64(PDU * thePDU) {
	return get64_e(thePDU, BIGENDIAN);
}

float getReal4(PDU * thePDU) {
	uint32_t i = get32_e(thePDU, BIGENDIAN);
	return *((float *)&i);
}

double getReal8(PDU * thePDU) {
	uint64_t i = get64_e(thePDU, BIGENDIAN);
	return *((double *)&i);
}

void getConstChar_e(PDU * thePDU, unsigned char * buffer, unsigned long numChars, uint8_t endianness){
  // implment endianness later
  memcpy(buffer,&(thePDU->data[thePDU->curPos]),numChars);
  thePDU->curPos += numChars;
}

int debugIndent=0;

void IN(FILE * tf,char * functionName){
    if (tf) fprintf(tf,"%*s %s\n",(debugIndent<50)?debugIndent:50,"->",functionName);
    debugIndent++;
}

void SUCCESS(FILE * tf,char * functionName){
    debugIndent --;
    if (tf) fprintf(tf,"%*s %s\n",(debugIndent<50)?debugIndent:50,"<-",functionName);
}

void FAIL(FILE * tf,char * functionName){
    debugIndent --;
    if (tf) fprintf(tf,"%*s %s\n",(debugIndent<50)?debugIndent:50,"<#",functionName);
}

void READREAL(FILE * tf, char * fn, double value){
    if (tf) fprintf(tf,"%*s %s=%f\n",(debugIndent<50)?debugIndent:50,"@",fn,value);
}

void READLONG(FILE * tf, char * fn, unsigned long value){
    if (tf) fprintf(tf,"%*s %s=%02lx(%ld)\n",(debugIndent<50)?debugIndent:50,"@",fn,value,value);
}

void READLONGLONG(FILE * tf,char*fn,unsigned long long value){
    if (tf) fprintf(tf,"%*s %s=%02llx(%lld)\n",(debugIndent<50)?debugIndent:50,"@",fn,value,value);
}

void READOCTET(FILE * tf,char * fn, char * ostring, unsigned long length){
    if (tf) {
	fprintf(tf,"%*s %s=",(debugIndent<50)?debugIndent:50,"@", fn);
	for (int i; i < length; i++){
	    fprintf(tf,"%02x(%c) ",ostring[i],ostring[i]);
	}
    }
}

void CHOICE(FILE * tf, long long value){
}
