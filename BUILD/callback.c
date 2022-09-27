//#include "callback.h"
#include "StringHash.h"
#include "globals.h"

//#include "NTP_Generated.h"
#include "ARP_Definitions.h"
//#include "RTPS_Generated.h"
//#include "IGMP_Generated.h"

#include <stdio.h>
#include <assert.h>
#include <arpa/inet.h>


#define NoPrint
#ifdef NOTNOW
void Query_IGMP_callback(Query_IGMP * q, PDU * thePDU){
    if (traceFile) fprintf(traceFile,"\tIGMP QUERY");	
}

void V2Report_IGMP_callback(V2Report_IGMP * v, PDU * thePDU) {
    if (traceFile) fprintf(traceFile,"\tIGMP V2Report");	
}

void V2Leave_IGMP_callback(V2Leave_IGMP * v, PDU * thePDU) {
    if (traceFile) fprintf(traceFile,"\tIGMP V2Leave");	
}

void V3Report_IGMP_callback(V3Report_IGMP * v, PDU * thePDU) {
    if (traceFile) fprintf(traceFile,"\tIGMP V3Report");	
}

void PING_RTPS_callback (PING_RTPS * ping_rtps, PDU * thePDU){
    if (traceFile) fprintf(traceFile,"\tPing");
}

void FULL_RTPS_callback(FULL_RTPS * r, PDU * thePDU) 
{
    if (traceFile) fprintf(traceFile,"\t(Full callback reached)");
}

// ADDED FROM ORIGINAL //

void DATAPSUB_RTPS_callback (FULL_RTPS * full_rtps, DATAPSUB_RTPS * datapsub_rtps, PDU * thePDU) {
    if (traceFile) fprintf(traceFile," | DATAPSUB");
}

void DATASUB_RTPS_callback (FULL_RTPS * full_rtps, DATASUB_RTPS * datasub_rtps, PDU * thePDU) {
    if (traceFile) fprintf(traceFile," | DATASUB");
}

void ACKNACK_RTPS_callback (FULL_RTPS * full_rtps, ACKNACK_RTPS * acknack_rtps, PDU * thePDU) {
    if (traceFile) fprintf(traceFile," | ACKNACK");
}

void HEARTBEAT_RTPS_callback (FULL_RTPS * full_rtps, HEARTBEAT_RTPS * heartbeat_rtps, PDU * thePDU) {
    if (traceFile) fprintf(traceFile," | HEARTBEAT");
}

void INFO$DST_RTPS_callback (FULL_RTPS * full_rtps, INFO$DST_RTPS * info$dst_rtps, PDU * thePDU) {
    if (traceFile) fprintf(traceFile," | INFO_DST");
}

void INFO$TS_RTPS_callback (FULL_RTPS * full_rtps, INFO$TS_RTPS * info$ts_rtps, PDU * thePDU) {
    if (traceFile) fprintf(traceFile," | INFO_TS");
}

void DATAWSUB_RTPS_callback (FULL_RTPS * full_rtps, DATAWSUB_RTPS * datawsub_rtps, PDU * thePDU) {
    if (traceFile) fprintf(traceFile," | DATAWSUB");
}

void DATARSUB_RTPS_callback (FULL_RTPS * full_rtps, DATARSUB_RTPS * datarsub_rtps, PDU * thePDU) {
    if (traceFile) fprintf(traceFile," | DATARSUB");
}

void GAP_RTPS_callback (FULL_RTPS * full_rtps, GAP_RTPS * gap_rtps, PDU * thePDU) {
    if (traceFile) fprintf(traceFile," | GAP");
}

void QOSPARM_RTPS_callback (QOSPARM_RTPS * qosparm_rtps, PDU * thePDU) {
    if (traceFile) fprintf(traceFile," | QOSPARM");
}

void V3LEAVE_IGMP_callback (V3Report_IGMP * v3report_igmp, V3LEAVE_IGMP * v3leave_igmp, PDU * thePDU) {
    if (traceFile) fprintf(traceFile,"\tIGMP V3Leave");
}

void V3JOIN_IGMP_callback (V3Report_IGMP * v3report_igmp, V3JOIN_IGMP * v3join_igmp, PDU * thePDU) {
    if (traceFile) fprintf(traceFile,"\tIGMP V3JOIN");
}

void V3GENERALGROUP_IGMP_callback (V3Report_IGMP * v3report_igmp, V3GENERALGROUP_IGMP * v3generalgroup_igmp, PDU * thePDU) {
    if (traceFile) fprintf(traceFile,"\tIGMP V3Genral Group");
}


// END ADDED //

////*******************************************************************************************************//////////



#endif
