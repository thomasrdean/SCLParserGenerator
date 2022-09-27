/*+
 * File:	StringHash.h
 *
 * Purpose:	headerfile for string hash library
 *
 * Revision History
 *  1.0		Thomas R. Dean, May 2016
 *		- initial version
 *  1.0.1	Ali ElShakankiry May 2016
		- Hash Table will now properly return the same index for identical strings.
		- No Need for string duplicates, this hash table is used to compare indices of equivalent strings
		- NOTE: This Hash table implementation is case SENSITIVE. See hashForString()
-*/

#ifndef STRINGHASH_H
#define STRINGHASH_H

#include "globals.h"

bool initStringHash();
void initKnownStrings();

unsigned long hashForString(const char * str);

char * stringForHash(unsigned long h);
unsigned long getNullIndex();
unsigned long getLengthIndex();
unsigned long getCardinalityIndex();
unsigned long getPDUIndex();
unsigned long getCurIndex();
unsigned long getSizeIndex();
void writeHashTable();
#endif
