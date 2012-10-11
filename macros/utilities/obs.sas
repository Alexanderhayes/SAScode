/************************************************************************
MACRO NAME:obs.sas 
AUTHOR:	Alberto Negron
CREATION DATE: 23/05/2007
*************************************************************************
PURPOSE: Print to the log the number of observation for a given data set 

*************************************************************************
INPUT:
-Parameters:
	- dsn: data set name

OUTPUT:	Log

*************************************************************************
LOG:
major.minor.fixedbug
Version				Author		 	Date		Comments
1.0.0				  AN			23/05/07	Creation Date
1.1.0				  AN			08/10/11	Header added
1.2.0				  AN			09/10/11	Put remove from inside data step
												Put and sysfunc(compress()) added
1.3.0				  AN			11/10/11    Option nonotes added
*************************************************************************/
%macro Obs(dsn);
options nonotes;
%if %sysfunc(exist(&dsn)) %then
	%do;
			data _null_;
				if 0 then set &dsn nobs=nobs;
/*				dsn="&dsn";*/
/*				put "&dsn"= nobs;*/
				call symput("nobs",nobs);
			stop;
			run;
			%put Data set:&dsn has %sysfunc(compress(&nobs)) observations.;
	%end;
	%else 
		%put ERROR: Data set &dsn does not exist.;
options notes;
%mend;
