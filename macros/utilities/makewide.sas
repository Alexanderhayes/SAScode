/************************************************************************
MACRO NAME: makewide.sas
AUTHOR:	Gerhard Svolba
CREATION DATE: unknown
*************************************************************************
PURPOSE: Convert a LONG data set to a WIDE data set (transpose)

*************************************************************************
INPUT:
-Parameters:
	-Data: input data set
	-OUT : output data set
	-ID  : the id of the ID variable that identifies the subject
	-COPY: a list of variables that occurs repeatedly with each observation
		   for a subject and will be copied to the resulting data set
	-VAR : the variable that holds the values to be transposed
    -TIME: The variable that enumerate the repeated measurements

OUTPUT:	a data set

*************************************************************************
LOG:
major.minor.fixedbug
Version				Author		 	Date		Comments
1.0.0				
*************************************************************************/

%MACRO MAKEWIDE(DATA=,OUT=out,ID=,COPY=,
                 VAR=, TIME=);
 
PROC TRANSPOSE DATA   = &data
               PREFIX = &var
               OUT    = &out(DROP = _name_);
 BY  &id &copy;
 VAR &var;
 ID  &time;
RUN;
%MEND;
