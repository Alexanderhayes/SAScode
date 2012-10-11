*************************************************************************
* Program Name:timestamp.sas
* Creation Date: 19/05/2007
* Author: Alberto Negron
*************************************************************************
* Description: Record start time & end time for any piece of code and
* calculates the processing time.
*
*************************************************************************
* Log
* Version		Date			Author			Comments
* 0.1.0			19/05/07		  AN			Creation date
* 0.2.0			11/10/12		  AN			Header Added
*************************************************************************;	

%let datetime_start = %sysfunc(TIME()) ;
  %put START TIME: %sysfunc(datetime(),datetime14.);
  /*... program code ...*/
  %put END TIME: %sysfunc(datetime(),datetime14.);
  %put PROCESSING TIME:  %sysfunc(putn(%sysevalf(%sysfunc(TIME())-&datetime_start.),mmss.)) (mm:ss) ;