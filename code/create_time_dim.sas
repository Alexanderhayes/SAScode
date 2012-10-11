*************************************************************************
* Program Name: Create Time Dimension
* Creation Date:27/09/2012
* Author: Alberto Negron
*************************************************************************
* Description: Create a time Dimension data set
*
*
*************************************************************************
* Log
* Version		Date			Author			Comments
* 0.1.0			27/09/12		  AN			 Creation Date
*
*************************************************************************;	

libname anlib "/home/negrona/parallel_run";

data anlib.time_dimension(drop=i);
format date start_week end_week date9.;
do i='01jan2000'd to '31dec2020'd;
	date=i;
	day=day(date); * day of the month;
	weekday=weekday(date);
	wkdname=strip(put(date,weekdate3.));
	week=week(date,'v'); *v starts weeks on Mondays;
	month=month(date);
	monname=strip(put(date,monname3.));
	Quarter=qtr(date);
	semester=(quarter in (1,2))*1 + (quarter in (3,4))*2;
	year=year(date);
	yyq=strip(put(date,yyq4.));
	if weekday=1 then
		do;
		start_week=intnx('week',date-1,0,'b')+1;
		end_week=intnx('week',date-1,0,'e')+1;
		end;
	else
		do;
		start_week=intnx('week',date,0,'b')+1;
		end_week=intnx('week',date,0,'e')+1;
		end;
	output;
end;
run;