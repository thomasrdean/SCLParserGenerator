/*+
 * File:	packet.C
 *
 * Purpose:	Packet I/O. Reads/writes the binary
 *		packet from/to the filesystem.
 *
 * Revision History:
 *  1.0	- Thomas R. Dean June 2004
 *	- Initial version, read only
 *  S. Marquis
 *	- added watermark property to help implement the length constraint

-*/

#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "globals.h"
#include "packet.h"


PDU * readPDU(char * PDUFileName, char * progname){
   FILE * infile;
   struct stat stbuff;
   int res;
   unsigned int bytesToRead, bytesRead;
   PDU * thePDU;

   /* find out the file size */
   /* currently unix specific */
   res = stat(PDUFileName,&stbuff);
   if (res != 0){
      fprintf(stderr,"%s: could not determine the size of %s\n",progname,PDUFileName);
      exit(1);
   }

   infile = fopen(PDUFileName,"r");
   if (infile == NULL){
      fprintf(stderr,"%s: could not open %s for read\n",progname,PDUFileName);
      exit(1);
   }

   thePDU = (PDU*) malloc(sizeof(PDU));
   if (thePDU == NULL){
      fprintf(stderr,"%s: internal malloc error file: %s line: %d\n",progname, __FILE__ , __LINE__);
      exit(1);
   }

   thePDU->len = stbuff.st_size;
//added 27 Aug 04 S. Marquis used by doToken and doArray to determine if PDU is parsed sucessfully based on length
   thePDU->watermark=stbuff.st_size;
   thePDU->curPos = 0;
   thePDU->data = (unsigned char*)malloc(thePDU->len);
   if (thePDU->data == NULL){
      fprintf(stderr,"%s: internal malloc error file: %s line: %d\n",progname, __FILE__ , __LINE__);
      exit(1);
   }

   bytesRead = 0;
   bytesToRead = thePDU->len;
   thePDU->choices = NULL;


   // system may be unwilling to read the entire packet in a single
   // fread. Standard read loop.

   while(bytesToRead > 0){
      bytesRead = fread(thePDU->data+bytesRead,1,bytesToRead,infile);
      bytesToRead -= bytesRead;
   }

   fclose(infile);
   return thePDU;
}

// Single merged stack for initial implementaiton.
// If a lot of choices are used, may be better to have a hashtable
// to separate the stacks.

// pushes the current choice to the front of the list
void pushChoice(PDU *context, char * ruleName, int choiceVal){
   choiceNode * tmp = (choiceNode*)malloc(sizeof(choiceNode));
   tmp->ruleName = ruleName;
   tmp->choiceVal = choiceVal;
   tmp->next = context->choices;
   context->choices = tmp;
}

int removeAndReturnChoice(choiceNode **head, char * ruleName);
// finds the first node with the first node with the ruleName
// and returns the choice Value;
int getChoice(PDU *context, char * ruleName){
   return removeAndReturnChoice(&(context->choices), ruleName);
}

int removeAndReturnChoice(choiceNode **head, char * ruleName){
   if (*head == NULL){
      // major error here,.
      // SCL runtime should never look up a rulename that
      // hasn't been in a Forward Choice constraint.
      fprintf(stderr, "Choice Lookup failed for rule %s\n", ruleName);
      exit(1);
   }
   // if match, free and return choiceVal
   if (!strcmp((*head) -> ruleName, ruleName)){
      int retVal = (*head) -> choiceVal;
      choiceNode * tmp = *head;
      *head = (*head) -> next;
      free(tmp);
      return retVal;
   }
   return removeAndReturnChoice(&((*head)->next), ruleName);
}
