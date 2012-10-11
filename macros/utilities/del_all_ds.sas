/************************************************************************
MACRO NAME:del_all_ds.sas
AUTHOR:	Alberto Negron
CREATION DATE: 11/10/2011
*************************************************************************
PURPOSE: Delete all datesets in a given library

*************************************************************************
INPUT:
-Parameters:
	lib= library name

OUTPUT:	

*************************************************************************
LOG:
major.minor.fixedbug
Version				Author		 	Date		Comments
1.0.0				 AN				11/10/11	Creation date
*************************************************************************/

%macro del_all_ds(lib=);
	Proc datasets library = &lib kill memtype=data nodetails nolist;
	quit;
%mend;
