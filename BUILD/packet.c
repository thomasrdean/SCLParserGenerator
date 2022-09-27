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

#include "globals.h"
#include "packet.h"


PDU * readPDU(char * PDUFileName){
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


   // system may be unwilling to read the entire packet in a single
   // fread. Standard read loop.

   while(bytesToRead > 0){
      bytesRead = fread(thePDU->data+bytesRead,1,bytesToRead,infile);
      bytesToRead -= bytesRead;
   }

   fclose(infile);
   return thePDU;
}
