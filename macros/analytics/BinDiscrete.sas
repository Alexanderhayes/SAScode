*************************************************************************
* Program Name: BinDiscrete.sas
* Creation Date:
* Author:Alberto Negron - albertonegron@gmail.com
*************************************************************************
* Description:The macro calcualtes Freq, Odds, Woe & IV for  *
*             discrete variables 
*
* Inputs:																*
*    DSN      = Name of input dataset									*
     CLASSVAR = Name of discrete input variable to bin	(1 only)		*
     TARGET   = Name of the dependent/target variable being 			*
                modelled. Must be defined as (1/0)						*
     OUT      = Report output data set									*
*
*************************************************************************
* Log
* Version		Date			Author			Comments
* 0.1.0			11/12/2009		  AN			Creation Date
* 0.2.0			11/10/2012		  AN			Header Added
*												store option removed
*************************************************************************;	


%macro BinDiscrete(dsn=,target=,classvar=,out=) / des='Bining Analysis for Discrete variables' ;
options nonotes nomlogic nomprint nosymbolgen nosource nosource2;

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

**********************************
 Step1: 
Split the target variable into 2 
new variables for Bad/good or
target/nontarget populations
*********************************;
Data inputDSN_d;
set &dsn;
Target1=(&target eq 1);
Target0=(&target ne 1);
 weight=1;
run;

proc summary data=inputdsn_d missing;
   class &classvar;
   weight weight;
   var  target1 target0;
   output out=resultsM_d sum=;
   run;

Data resultsF_d(drop=&classvar);
length bins $ 100;
set resultsM_d;
bins=&classvar;
if _type_=0 and &classvar='' then bins='Total';
if _type_=1 and &classvar='' then bins='Missing';
run;

**********************************
 Step3:Calculating Odds, WOE, IV
and Chi-square statistic
*********************************;
*Number of rows for calculating Degree of Freedom;
data _NULL_;
	if 0 then set resultsF_d nobs=n;
	call symputx('nobs',n);
	stop;
run;


Data MyDiscretebins;
set resultsf_d end=EOF;
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
DF=&nobs-2; /*-2 for susbstracting row 'Total' from formula*/
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
Proc report data=MyDiscretebins NOWINDOWS 
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
delete inputDSN_d resultsM_d resultsM_d MyDiscretebins;
quit;
%mend;

