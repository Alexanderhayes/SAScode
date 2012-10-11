/************************************************************************
MACRO NAME:rfm.sas
AUTHOR:	Alberto Negron
CREATION DATE: 20/12/2007
*************************************************************************
PURPOSE: Create RFM segments

*************************************************************************
INPUT:
-Parameters:
	- input: Transaction data set
	- custid: customer id variable
	- datevar: date variable
	- money: defines input variable for Monetary segment
	- enddate: this param defines last date to calculate recency
	- splits: define how many levels will be created, i.e 5 will create
             1,2,3,4,5 for each RFM
	- rfmvar: name of the rfm score variable
	- output: output data set
OUTPUT:	dataset with rfm score values

*************************************************************************
LOG:
major.minor.bug
Version				Author		 	Date		Comments
1.0.0				  AN			20/12/2007	Creation date
1.1.0				  AN			07/08/2009  Temp data sets deleted
1.2.0				  AN			23/09/2011  The segmentation starts with recency, 
												then frequency and finally with Monetary
1.2.1				  AN			24/09/2011 	order level in Monetary and recency was wrong. Fixed now
1.3.2				  AN			27/09/2011  replace date for macro variable datevar
												datedif added to calculate recency
*************************************************************************/	

%macro rfm(input=,custid=,datevar=,enddate=,money=,splits=,rfmvar=,output=);
%*Summarise Monetary, transactions (frequency) and recency by custid;
Proc SQL;
create table pre_rfm as
Select &custid
	   ,sum(&money) as monetary
	   ,count(&datevar) as freq
	   ,min(datdif(&datevar,&enddate,'actual')) as day
from &input
group by 1;
quit;
%*Rank tot_money num_trans diff_day;
proc rank data=pre_rfm out=pre_rfm2 ties=low descending groups=&splits; 
     var day;
   ranks R;
run;
proc rank data=pre_rfm2 out=rfm ties=low groups=&splits ; 
     var freq monetary ;
   ranks  F M;
run; 
%*Create rfm score variable; 
data &output;
set rfm;
R+1;
F+1;
M+1;
&rfmvar=cats(R,F,M)+0;
run;

proc datasets library=work nolist ;
delete pre_rfm  pre_rfm2 rfm;
quit;

%mend rfm;



