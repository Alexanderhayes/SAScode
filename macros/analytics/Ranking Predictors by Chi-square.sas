******************************************;
* A SAS ROUTINE FOR PREDICTORS RANKING   *;
* BY MAXIMIZED CHI-SQUARE BASED UPON THE *;
* BINARY SPLIT IMPLEMENTED IN DMSPLIT    *;
* PROCEDURE IN ENTERPRISE MINER.         *;
* -------------------------------------- *;
* author: wensliu@paypal.com             *;
******************************************;

libname data 'D:\projects\woe\data';

options mprint mlogic;

%let varlist = x2 x3 x4 x5 x10 x11 x12 x13 x14 x15;

%macro dmsplit(data = , y = , x = &varlist);
    
%let i = 1;
%local i;

data _tmp1(keep = &y &varlist);
  set &data;
  where &y in (0, 1);
run;

proc sql;
create table _out
(
  variable   char(32),
  type       char(1),
  chi_sq     num
);
quit;
  
%do %while (%scan(&varlist, &i) ne %str());  
  %let var = %scan(&varlist, &i);
  
  data _tmp2(keep = &y &var);
    set _tmp1;
    if _n_ = 1 then do;
      call symput('vtype', vtype(&var));
    end;
  run;

  proc dmdb data = _tmp2 out = _db1 dmdbcat = _ct1;
  %if &vtype = C %then %do;
    class &y &var;
  %end;
  %else %if &vtype = N %then %do;
    class &y;
    var &var;
  %end;
  run;

  proc dmsplit data = _db1 dmdbcat = _ct1 outvars = _tmp3 noprint passes = 5;
    var &var;
    target &y;
  run;

  %if %sysfunc(exist(_tmp3)) %then %do;
    proc sql noprint;
      select count(*) into :nobs from _tmp3;
    quit;

    %if &nobs > 0 %then %do;
      proc sql;
        insert into _out
      select
        upcase(_split_), "&vtype", round(_chisqu_, 0.01)
      from
        _tmp3
      where
        _parent_ = 0;
      quit;
    %end;
    %else %do;
      options obs = max nosyntaxcheck;
      proc sql;
        insert into _out
        values("%upcase(&var)", "&vtype", .);;
      quit;      
    %end;
  %end;

  proc datasets library = work nolist;
    delete _tmp2 _tmp3 / memtype = data;
  run;
  quit;
  
  %let i = %eval(&i + 1);    
%end;    

proc format;
  picture chi_fmt . = 'N / A';
run;

proc sort data = _out;
  by descending chi_sq;
run;

proc report data = _out box spacing = 1 split = "*";
  column("Predictors Ranking by*Maximized Chi-Square Based on Binary Cut"
         variable type chi_sq);
  define variable / "Predictor" width = 20 center;
  define type     / "Type"      width = 10 center;
  define chi_sq   / "ChiSQ"     width = 15 center format = chi_fmt.;
run;

%mend dmsplit;

%dmsplit(data = data.credit, y = y, x = &varlist);