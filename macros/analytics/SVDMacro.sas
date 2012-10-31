/*============================================================================
   Program Name:   SVDMacro.sas
   Author:Liang Xie
   Date:unknown
   Email:
============================================================================
   Purpose:   SVD matrix computation
============================================================================
    Log:
    Version             Date            Author          Comments
============================================================================
*/


%macro SVD(
           input_dsn,
           output_V,
     output_S,
     output_U,
     input_vars,
     ID_var
           );
options nonotes;
%local blank   para  EV  USCORE  n  pos  dsid nobs ;

%let blank=%str( );
%let options=noint cov noprint;
%let EV=EIGENVAL;
%let USCORE=USCORE;
%let n=1;
%let pos=%scan(&input_vars,&n,&blank); 
%do %while(&pos ne &blank); 
    %let n=%eval(&n+1); 
    %let pos=%scan(&input_vars,&n,&blank); 
%end;
%let n=%eval(&n-1);

proc princomp data=&input_dsn  
              out=&input_dsn._score 
              outstat=&input_dsn._stat(where=(_type_ in ("&USCORE", "&EV")))   &options;
     var &input_vars;
run;
data &output_S;
     set &input_dsn._stat;
     format Number 7.0;
  format EigenValue Proportion Cumulative 7.4;
  keep Number EigenValue  Proportion Cumulative;
  where _type_="&EV";
  array _X{&n} &input_vars;
  Total=sum(of &input_vars);
  Cumulative=0;
     do Number=1 to dim(_X);
     EigenValue=_X[number];
  Proportion=_X[Number]/Total;
        Cumulative=Cumulative+Proportion;  
     output;
  end;
run;
proc transpose data=&input_dsn._stat(where=(_TYPE_="&USCORE")) 
               out=&output_V.(rename=(_NAME_=variable))
               name=_NAME_;
     var &input_vars;
     id _NAME_;
  format &input_vars 8.6;
run;
%let dsid=%sysfunc(open(&input_dsn));
%let nobs=%sysfunc(attrn(&dsid, NOBS));
%let dsid=%sysfunc(close(&dsid));

/* recompute Proportion */
data &output_S.New;
     array _s{&n}  _temporary_;
  retain total 0;
  if _n_=1 then do;
     do i=1 to &n;
        set &output_S.(keep=Proportion) point=i;
     _s[i]=sqrt(Proportion); total+_s[i];
     end;  
     end;  
  set &output_S;
  S=_s[Number]/total; D=sqrt(EigenValue*&nobs);  
run;
/* calculate U=XV/S */

proc transpose data=&output_V out=&output_V._t  name=variable;
     var Prin1-Prin&n;
  id  variable;
run;
data &output_V._t;
       retain _TYPE_ 'PARMS';
       set &output_V._t;
    _NAME_=variable;
run;

proc score data=&input_dsn   score=&output_V._t  type=parms  
                out=&output_U.(keep=&ID_VAR Prin:);
    var   &input_vars;
run;

data &output_U;
       array _S{&n}  _temporary_;
    array _X0{&n} X1-X&n;
       if _n_=1 then do;
       do j=1 to &n;
        set  &output_S.New(keep=D);
     _S[j]=D; if abs(_S[j]) < CONSTANT('MACEPS') then _S[j]=CONSTANT('BIG');
    end;
    drop D;
    end;
    set &output_U;
       array _A{*}  Prin1-Prin&n;
    do _j=1 to dim(_A);
        _A[_j]=_A[_j]/_S[_j];
    end;
    do _j=1 to dim(_A);
       _X0[_j]=_A[_j];
    end;
    keep &ID_var X1-X&n ;
run;
%mend;
