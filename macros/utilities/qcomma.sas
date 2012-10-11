/************************************************************************
MACRO NAME: qcomma.sas
AUTHOR:	Unknown / modified by: Alberto Negron
CREATION DATE:
*************************************************************************
PURPOSE: convert a list separated by spaces to a comma list. It should be
used as part of macro functions 

*************************************************************************
INPUT:
-Parameters: List

OUTPUT:	list separated by commas

Example:
%let numeros= uno dos tres cuatro cinco seis siete ocho;
%qcomma(&numeros,delim=%str( ));
*************************************************************************
LOG:
major.minor.fixedbug
Version				Author		 	Date		Comments
1.0.0				 AN				20/12/08	Modification date
1.1.0				 AN				11/10/11	Single quote changed to double quotes
*************************************************************************/
%macro qcomma(list, delim=%str( ));
  %local varlist i var;
  %let varlist=&list.;
  %let i=0;
  %do %while(%qscan(&varlist.,%eval(&i.+1),
%quote(&delim.)) ne );
    %if &i. gt 0 %then %do;
      %let var=%str(%trim(%quote(&var.)),);
    %end;
    %let i = %eval(&i.+1);
    %let var=&var.%str(%")%qscan(&varlist,&i.,
%quote(&delim.))%str(%");
  %end;
%* MUST be first and only thing on a line by itself *;
%unquote(&var.)
%mend;


