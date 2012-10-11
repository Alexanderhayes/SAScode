/************************************************************************
MACRO NAME:delds.sas
AUTHOR:	Alberto Negron
CREATION DATE: 01/09/2008
*************************************************************************
PURPOSE: Delete a dateset

*************************************************************************
INPUT:
-Parameters:
	dsn= data set name
	lib= library name

OUTPUT:	

*************************************************************************
LOG:
major.minor.fixedbug
Version				Author		 	Date		Comments
1.0.0				 AN				01/09/08	Creation date
*************************************************************************/

%macro delds(dsn=,lib=);
	Proc datasets library = &lib nodetails nolist;
	delete &dsn;;
	quit;
%mend;
