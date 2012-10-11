*************************************************************************
* Program Name: BinInterval.sas
* Creation Date:
* Author:
*************************************************************************
* Description:The macro automatically bands numeric variables			* 
*            into groups and calculate Freq, Odds, Woe & IV				*
*																		*
*																		*
* Inputs:																*
*    DSN      = Name of input dataset									*
     CLASSVAR = Name of continuous input variable to bin (limit 1)		*
     TARGET   = Name of the dependent/target variable being 			*
                modelled. Must be defined as (1/0)						*
     DECILE   = Percentile to split the continuous variable 			*
     OUT      = Report output data set									*
*
*
*************************************************************************
* Log
* Version		Date			Author			Comments
* 0.1.0			02/12/2009		  AN			Creation Date
* 0.1.1			10/12/2009 		  AN			Xsqr Correction for 2x2 table added	
* 0.2.0			11/10/2012		  AN			Header added
*************************************************************************;	


%macro BinInterval(dsn=,target=,classvar=,decile=,out=) / des="Bining Analysis for Interval variables";
options nonotes nomlogic nomprint nosymbolgen nosource nosource2;
%local AnyObs out;
**********************************
Step0: 
Work Path for creating temporal 
files
**********************************;
data _null_;
path=pathname('work');
path2='"'!!compress(path)!!'\temp.txt'!!'"';
call symputx('Mypath',path2);
run;
%put Mypath=&mypath;
**********************************
 Step1: 
Split the target variable into 2 
new variables for Bad/good or
target/nontarget populations
*********************************;
Data inputDSN;
set &dsn;
Target1=(&target eq 1);
Target0=(&target ne 1);
 weight=1;
run;

**********************************
 Step2: Creating Formats
As the classvar is interval a 
binning process is required in order
to create groups
*********************************;
%*For NonMissing values;
proc summary data=inputdsn ;
   class &classvar;
   weight weight;
   var  target1 target0;
   output out=resultsNM sum=;
   run;
%*For Missing values;
proc summary data=inputdsn missing;
   class &classvar;
   weight weight;
   var  target1 target0;
   output out=resultsM sum=;
   run;
%*Split groups between missing & non missing;
data nonMissing ;
  retain tot;
  set resultsNM ;
  if _type_=0 then tot=_freq_;
  percent=(_freq_/tot)*100;
  if _type_>0 ;
  run;
data Missing ;
  retain tot;
  set resultsM ;
  if _type_=0 then tot=_freq_;
  percent=(_freq_/tot)*100;
  if _type_>0 and &classvar eq . then output;
  run;quit;
%*Create group cut offs for the NonMissing population;
data NonMissG;
  retain group 1 cutoff 0 flag 'N';
  set nonMissing nobs=nobs;
  decile=100/&decile;
	/*in case the data set is smaller than the number of bins selected by user*/
	if (nobs-1)<=(100/decile) then flag='Y';
 	 if flag='Y' then 
		do;
     		cutoff=0;
     		group+1;
     		flag='N';
  		end;
  cutoff+percent;
  if cutoff>=decile then flag='Y';
  run;
%*Create group cut offs for the NonMissing population and SET with NonMissG- if they exist;
 	%*  0 if no observations found in data;
  	%*  1 if any observations found in data;
  	%* -1 if an error occurred;
data _null_;
  dsid=open("Missing");
   if dsid>0 then
	   any=attrn(dsid,"Any");
   call symputx("AnyObs",any);
run;

%if &AnyObs=1 %then
	%do;
		data MissG;
		  retain group 0 cutoff 0 flag 'N';
		  set Missing nobs=nobs;
		  decile=100/&decile;
			/*in case the data set is smaller than the number of bins selected by user*/
			if (nobs-1)<=(100/decile) then flag='Y';
		 	 if flag='Y' then 
				do;
		     		cutoff=0;
		     		group=0;
		     		flag='N';
		  		end;
		 run;

		Data Preformat;
		set MissG NonMissG;
		run;
	%end;
%else
	%do;
		Data Preformat;
		set  NonMissG;
		run;
	%end;
%*Creating the format file;
data formats;
  retain llimit ulimit;
  set Preformat(where=(group ne 0));
  by group;
  if first.group then llimit=&classvar;
  if last.group then do;
     ulimit=&classvar;
     output;
  end;
  run;

data _null_;
  set formats end=eof;
	file &Mypath;
		if _n_=1 then do;
  			put "PROC FORMAT;VALUE BALFMT ";
	    end;
    put LLimit "-" ULimit"='" LLimit"-" ULimit"'";
    if eof then 
		do;
			put "Other='Missing';";
			put ";run;";
    	end;
run;
%INCLUDE &Mypath;

proc summary data=preformat missing;
class &classvar;
format  &classvar balfmt.;
var target1 target0;
output out=resultsF sum=;
run; 

Data resultsF(drop=&classvar);
length bins $ 40;
set resultsF;
bins=put(&classvar,balfmt.);
if _type_=0 and &classvar=. then bins='Total';
run;
**********************************
 Step3:Calculating Odds, WOE, IV
and Chi-square statistic
*********************************;
*Number of rows for calculating Degree of Freedom;
data _NULL_;
	if 0 then set resultsF nobs=n;
	call symputx('nrows',n);
	stop;
run;

Data Mybins;
set resultsf end=EOF;
retain count TOTtarget1 TOTtarget0 CUMtarget1 CUMtarget0 total totchisq 0 cumIV;
	count=sum(target1,target0);
	If _Type_=0 then do;
	     TOTtarget1=target1;
	     TOTtarget0=Target0;
		 total=count;
	end;
	totdist=count/total;
	if count ne 0 then
		Target1Rate=ROUND((target1/count),0.0001);
	else 
		Target1Rate=0;
	if TOTtarget1 ne 0 then
		do;
	 		PERCtarget1=ROUND((target1/TOTtarget1),0.0001);
			if _type_=1 then 
				do;
	        		if _N_=2 then CUMtarget1=0;
	      			CUMtarget1=CUMtarget1+PERCtarget1;
				end;
	 	end;
	else PERCtarget1=0;
	if TOTtarget0 ne 0 then
		do;
		 	PERCtarget0=ROUND((target0/TOTtarget0),0.0001);
			if _type_=1 then 
				do;
	        		if _N_=2 then CUMtarget0=0;
	      			CUMtarget0=CUMtarget0+PERCtarget0;
				end;
	 	end;
	else PERCtarget0=0;
	If PERCtarget1>0 AND PERCtarget0>0 then 
		Odds=PERCtarget1/PERCtarget0;
	else
		Odds=0;
	if _type_ ne 0 and Odds>0 then 
			Woe=ROUND(LOG(Odds),0.01);
	if _type_ ne 0 then 
		do;
			IV=((PERCtarget1-PERCtarget0)*Woe);
			cumIV+IV;
		end;
/**************************************
*    DF for chisquare statistic       *
***************************************/
DF=&nrows-2; /*-2 for susbstracting row 'Total' from formula*/
ExpTarget1=count*ToTtarget1/Total;
ExpTarget0=count*ToTtarget0/Total;
IF _TYPE_ NE 0 then
	do;
			if DF>1 then
				do;
				Chisq=((Target1-ExpTarget1)**2)/ExpTarget1 + ((Target0-ExpTarget0)**2)/ExpTarget0;
				totchisq+Chisq;
				end;
			else
				do;
				Chisq=max(0,(Target1-ExpTarget1-0.5)**2)/ExpTarget1 + max(0,(Target0-ExpTarget0-0.5)**2)/ExpTarget0; /*correction for 2x2 table*/
				totchisq+Chisq;
				end;
			P=1-PROBCHI(TOTCHISQ,DF); 
	end;
if EOF then
	do;
		call symputx('TotIv',round(cumiv,0.01));
		call symputx('totalchisq',round(totchisq,0.01));
        call symputx('theoChisq',round(CINV(0.95,DF),0.01));
		call symputx('pvalue',round(p,0.01));

	end;
run;

Title "Characteristic Analysis for Variable:%upcase(&classvar)";
footnote  justify=l height=8pt "Information Value = &TotIv" ;
footnote2 justify=l height=8pt "Chi-Square observed = &totalchisq / P-Value=&pvalue" ;
footnote3 justify=l height=8pt "Ho: %upcase(&target) and %upcase(&classvar) are independent. Reject Ho at 95% of confidence if &totalchisq > &theoChisq " ;
Proc report data=Mybins NOWINDOWS 
	%if &out ne %then out=&out;
;
	column bins _type_ count totdist target1 PERCtarget1 target0 PERCtarget0 Target1Rate Odds Woe;
	define bins / display 'Groups';
	define _type_ / order descending noprint ;
	define count/ display 'Counts';
	define totdist /display format=percent6.2 'Tot Distr';
	define target1 /display  'Target=1';
	define PERCtarget1 / display format=percent6.2 'Distr Target=1';
	define target0 /display  'Target=0';
	define PERCtarget0 / display format=percent6.2 'Distr Target=0';
	define Target1Rate / display format=percent6.2 'Target=1 Rate';
	define odds/ display 'Odds' format=comma20.2;
	define woe/ display 'Woe';
run;



proc datasets library=Work nodetails nolist;
delete InputDSN resultsNM nonMissing Missing MissG NonMissG formats preformat resultsm resultsf MyBins ;
quit;
%mend;

