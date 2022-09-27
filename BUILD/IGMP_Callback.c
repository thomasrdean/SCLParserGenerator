#include "globals.h"
#include "IGMP_Definitions.h"



void Query_IGMP_callback (Query_IGMP *query_igmp, PDU *thePDU){
    if(traceFileParser) fprintf(traceFileParser,"\tQUERY");
}

void V2Report_IGMP_callback (V2Report_IGMP *v2report_igmp, PDU *thePDU){
    if(traceFileParser) fprintf(traceFileParser,"\tV2Report");
}

void V2Leave_IGMP_callback (V2Leave_IGMP *v2leave_igmp, PDU *thePDU){
    if(traceFileParser) fprintf(traceFileParser,"\tV2Leave");
}

void V3Report_IGMP_callback (V3Report_IGMP *v3report_igmp, PDU *thePDU){
    if(traceFileParser) {
	fprintf(traceFileParser,"\tV3Report");
        fprintf(traceFileParser, "R1(%d),Chk(%x),R2(%d),Grps(%d) ",
			   v3report_igmp->reserved,
			   v3report_igmp->checksum,
			   v3report_igmp->secondreserved,
			   v3report_igmp->numgrps);
	GROUPRECORD_IGMP * grps = v3report_igmp->grouprecordinfo;
	for (int i = 0; i < v3report_igmp->grouprecordinfocount; i++){
	    switch(grps[i].type){
		case V3GENERALGROUP_IGMP_VAL:
		    fprintf(traceFileParser, "General ");
		    break;
		case V3ExcludeMode_IGMP_VAL:
		    fprintf(traceFileParser, "Exclude ");
		    fprintf(traceFileParser,  "ALen(%d),Num(%d),GrpAddr(%x) [Exclude 0 => Join]",
						    grps[i].item.v3excludemode_igmp.auxdatalen,
						    grps[i].item.v3excludemode_igmp.numsources,
						    grps[i].item.v3excludemode_igmp.groupaddr);
		    break;
		case V3IncludeMode_IGMP_VAL:
		    fprintf(traceFileParser, "Include " );
		    fprintf(traceFileParser,  "ALen(%d),Num(%d),GrpAddr(%x) [Include 0 => Leave]",
						    grps[i].item.v3includemode_igmp.auxdatalen,
						    grps[i].item.v3includemode_igmp.numsources,
						    grps[i].item.v3includemode_igmp.groupaddr);
		    break;
		default:
		    fprintf(traceFileParser, "****ERROR unknown V3Report tag");
	    }
	}
    }

}

//void V3IncludeMode_IGMP_callback (V3Report_IGMP *v3report_igmp, V3IncludeMode_IGMP *v3includemode_igmp, PDU *thePDU);
//void V3ExcludeMode_IGMP_callback (V3Report_IGMP *v3report_igmp, V3ExcludeMode_IGMP *v3excludemode_igmp, PDU *thePDU);
//void V3GENERALGROUP_IGMP_callback (V3Report_IGMP *v3report_igmp, V3GENERALGROUP_IGMP *v3generalgroup_igmp, PDU *thePDU);
