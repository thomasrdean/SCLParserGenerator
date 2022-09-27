/*+
* File:	StringHash.cpp
*
* Purpose:	
*
* Revision History
*  1.0		Thomas R. Dean, May 2016
*		- initial version
*
-*/

#include <stdlib.h>
#include <stdio.h>
#include <string.h>

#include "StringHash.h"

#define hashTableSize (2048-1)
static char * hashTable[hashTableSize];

bool initStringHash(){
	for (int i = 0; i < hashTableSize; i++){
		hashTable[i] = NULL;
	}
	return true;
}

unsigned long hashForString(const char * str){
	// based on djb2 hash http://www.cse.yorku.ca/~oz/hash.html
	// and linear probing
	unsigned long hash = 5381;
	const char * str2 = str;
	int c;

	while ((c = *str2++))
		hash = ((hash << 5) + hash) + c; /* hash * 33 + c */

	unsigned long startpos =  hash % hashTableSize;
	unsigned long pos = (startpos+1) % hashTableSize;
	
	while(1){
		if (pos == startpos) {
			fprintf(stderr, "Hash table full\n");
			exit(1);
		}
		if (hashTable[pos] == NULL){
			//empty slot
			hashTable[pos] = (char *)malloc(strlen(str)+1);
			strcpy(hashTable[pos], str);
			
			return (pos);
		}
		if (strcmp(hashTable[pos],str) == 0){
			return pos;
		}
		pos = (pos+1) % hashTableSize;
		//fprintf(stdout, "pos: %u\n", pos);
	}

}

char * stringForHash(unsigned long h){
	//h = h % hashTableSize;
	return hashTable[h];
}
