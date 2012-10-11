/************************************************************************
MACRO NAME: age.sas
AUTHOR:	Alberto Negron
CREATION DATE: 10/01/2007
*************************************************************************
PURPOSE:  Calculate the diff between 2 dates in years. This macro has
been designed for calculate customers' ages for example

*************************************************************************
INPUT:
-Parameters:
	- date: this date represent date in the future or the right limit of
		   the range
    - birth: date when customer born

OUTPUT:	variable

Example:
data www;
set my_input;
age_cust=%age(date=,birth=);

*************************************************************************
LOG:
major.minor.fixedbug
Version				Author		 	Date		Comments
1.0.0				  AN			10/01/2007	Creation date
1.1.0				  AN			11/10/2011	Header added
*************************************************************************/
%macro age(date=,birth=);
floor ((intck('month',&birth,&date)- (day(&date) < day(&birth))) / 12) ;
%mend age;
