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
	-ID  : the id of the ID variable that identifies the new column
	-COPY: a list of variables that occurs repeatedly with each observation
		   for a subject and will be copied to the resulting data set
	-VAR : the variable that holds the values to be transposed

OUTPUT:	a data set

*************************************************************************
LOG:
major.minor.fixedbug
Version				Author		 	Date		Comments
1.1.0				 AN				08/09/2010	 Macro modified				
*************************************************************************/

%MACRO MAKEWIDE2(DATA=,OUT=out,By=,COPY=,
                 VAR=, id=);
 
PROC TRANSPOSE DATA   = &data
               
               OUT    = &out;
 BY  &by &copy;
 VAR &var;
 ID  &id;
RUN;
%MEND;
