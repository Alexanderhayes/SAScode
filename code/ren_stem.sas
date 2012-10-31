/*************************************************************************************************
 * program: ren_stem.sas
 * programmer: Dan Blanchette dan.blanchette@duke.edu
 *             Center for Entrepreneurship and Innovation Duke University's Fuqua School of Business
 * Developed at:
 *             The Carolina Population Center at The University of North Carolina at Chapel Hill, 
 *             Research Computing at The University of North Carolina at Chapel Hill, and
 *             Center for Entrepreneurship and Innovation Duke University's Fuqua School of Business
 * date: 27Apr2004
 * modified : 25Feb2009 - fixed it so that if N or C is only option specified it works fine
 * modified : 05Aug2008 - made ren_stem SAS 9.2 compatible by changing:
 *                        "%else %then %do;"  to  "%else %do;"
 * modified : 27Sep2004 - delete the temporary dataset created by ren_stem
 * modified : 24May2004 - updated the documentation by adding all valid SAS varlists.
 *                        and added exclusion varlist capability:
 *                           _all_ not(MyIDvar)
 *                        so that one or more variable can be kept from being renamed
 *                         like the id variables needed for a merge.
 * comments:
 *      This macro renames a list of variables in a dataset
 *       by adding on a prefix or suffix constant to the 
 *       existing variable name.
 *      for example:
 *        rename height = min_height;
 *        rename weight = min_weight;
 *
* %ren_stem(dataset_name, varlist, constant prefix/suffix, options);
 *
 * Arguments    | Explanation
 * -------------|----------------------------------------------------------------------------------
 * dataset_name | Full name of dataset (include libref if necessary) in which variables 
 *              |   are to be renamed.
 *              | [If no dataset name provided then the last dataset used is processed.]
 * -------------|----------------------------------------------------------------------------------
 * varlist      | Can be of the following different valid SAS varlist styles:
 *              |   gender race - the two variables "gender" and "race"
 *              |   var1-var5   - var1 var2 var3 var4 var5
 *              |   age--sampwt - could be: age gender weight psu sampwt
 *              |   age-numeric-sampwt - only the numeric variables between age and sampwt:
 *              |                   age weight psu sampwt
 *              |   age-character-sampwt - only the character variables between age and sampwt:
 *              |                   gender
 *              |   _all_       - all variables in the dataset
 *              |   _numeric_   - all numeric variables in the dataset
 *              |   _character_ - all character variables in the dataset
 *              |   va:         - all variables in the dataset that begin with the string "va"
 *  excluding:  | You can exclude certain variables from your varlist (like your id vars) by:
 *              |   _all_ not(hhid personid)
 *              |  NOTE: There can be no space between the word "not" and the left parenthesis!
 *              |  YES:  not(varlist)
 *              |  NO:  not (varlist)
 *              |  ALSO: The order must be varlist first, then not(varlist).
 * -------------|----------------------------------------------------------------------------------
 * constant     | String you want to append to the variable name as a prefix or suffix to 
 *              |  make it a new name.
 * -------------|----------------------------------------------------------------------------------
 *
 *
 * Options      | Explanation
 * ------------------------------------------------------------------------------------------------
 *  before /    | Position of constant is to be before or after variable name.
 *   after      |  [If no placement is specified then the constant will go before the existing 
 *              |    variable name.]
 * -------------|----------------------------------------------------------------------------------
 *  SAScode     | Prints the SAS code used by the macro to create the dataset with the 
 *              |  renamed variables. This could be useful if you want to modify the 
 *              |  code in some way or if you want to simply see what was done.
 * -------------|----------------------------------------------------------------------------------
 *  N / C       | If you have a variable list of both numeric and character type variables 
 *              |  but only want to rename the character variables, use "C".  Similarly if 
 *              |  you only want to rename the numeric variables in the varlist, use "N".
 *              |  [If no vartype specified then all variable types renamed].
 *              |  Can be upper or lower case N (numeric) or C (character).
**************************************************************************************************/

/********** example use **********************************************

data new;
 set old;
run;

** Let SAS know about the ren_stem macro by including it in your program: **;
 %include "/bigtemp/sas_macros/ren_stem.sas";

 ** now call your macro by feeding whatever variables and whatever you want to
     tack on the beginning of the new variable names.  A comma separates what you feed
     the ren_stem macro.  **;
*%ren_stem(dset, list of variables ,  constant, options) **;
 %ren_stem(new, x1 x2 x3 x4 x5 y1  , round4_  , before  N);  ** eg. round4_x1 **;


  ** or : **;
data out.new;
 set old;
run;

%ren_stem(out.new, x1 x2 x3 x4 x5, _max, after sascode n);  ** eg. x1_max **; 


  ** or all character variables : **;
data myData;
 set old;
run;

%ren_stem(myData, _character_ , _constant, after ); ** all numeric type variables eg. x1_constant **; 


  ** or : **
data testdata;
 set old;
run;

%ren_stem(testdata, x1--gender not(pid), _min, after);   ** eg. x1_min **;

proc contents data= testdata;
run;

********** (end of) example use **********************************************/




* options mprint source2;


%macro ren_stem(dset,vars,constant,options);
  %** capture settings before changing them **;
  %let notes=%sysfunc(getoption(notes));
  %let obs=%sysfunc(getoption(obs));
  options nonotes obs=max;

  %if &dset.=  %then %let dset= &syslast.;
  %let options=%upcase(&options.);
  %let placement=before;  %** default is before the variable name **;
  %if %index(&options.,AFT) %then %do;
    %let placement=after;
  %end;
  %let vt= ;
  %if %index(&options.,%str(N ))=1 or %index(&options.,%str( N)) or &options.=N %then %do;
    %let vt=N;
  %end;
  %if %index(&options.,%str(C ))=1 or %index(&options.,%str( C)) or &options.=C %then %do;
    %let vt=C;
  %end;
  %let sascode=0;
  %if %index(&options.,SASCODE) %then %do;
    %let sascode=1;
  %end; 

  %let work_dir = %sysfunc(pathname(work));

  proc contents data= &dset.
  %if %index(&vars.,*) %then %do;
    (keep=_all_) 
  %end; 
  %else %if %index(&vars.,not%nrstr(%()) or
            %index(&vars.,NOT%nrstr(%()) or
            %index(&vars.,Not%nrstr(%()) 
      %then %do;
        %let end=%index(&vars.,%nrstr(%)));
        %let start=%eval(%index(&vars.,%nrstr(%())+1);
        %let length=%eval(&end.-&start.);
        %let notv=%substr(&vars.,&start.,&length.);
        %if %length(&vars.)=%eval(&length.+2) %then %do; %* not(varlist) is all in &vars. macro var *;
          (drop= &notv.)
        %end;
        %else %do;
          %let othv=%substr(&vars.,1,%eval(&start.-5));  %* not( is 4 characters +1 is 5 *;
          (keep= &othv. drop= &notv.)
        %end;
      %end; %* end of processing not variable list *;
  %else %do;
    (keep= &vars.) 
  %end;
   noprint out= ___&sysjobid.&sysindex.; 
  run;

  %let vt=%upcase(&vt.);
  %if &vt.^=  %then %do;
   %if &vt.=N %then %let vt_num=1;  %** only process numeric vars **;
   %if &vt.=C %then %let vt_num=2;  %** only process character vars **;
  %end;

  proc sort data=___&sysjobid.&sysindex.(keep= name type varnum);
   by varnum;
  run;

  data _null_;
   set ___&sysjobid.&sysindex.(keep= name type) end= lastvar; 
    file "&work_dir./___&sysjobid.&sysindex..txt";
    if _n_=1 then put '%macro varlist;';
    %if &vt.^=  %then %do;
     if type=&vt_num. then do;
      put name;
      count+1;
     end;
    %end;
    %else %do;
      put name;
      count+1;
    %end;
    if lastvar then do;
      put '%mend varlist;';
      call symput( 'count', left( put( count, 5. ) ) );
    end;
   run;
   %include "&work_dir./___&sysjobid.&sysindex..txt";


  data &dset.;
   set &dset.;

   %if &sascode.=1 %then %do;
     %put  ;
     %put ** This is the SAS code used by ren_stem to rename your variables. **;
     %put  ;
     %put  data &dset.%str(;);
     %put  %str( )set &dset.%str(;);
   %end;

   %do i=1 %to &count.; 
     %if &placement.=before %then %do;
       %* rename x2 = x2_constant;
       rename %scan(%varlist,&i.,%str( )) = &constant.%scan(%varlist,&i.,%str( ));
       %if &sascode.=1 %then %do;
         %put %str(  ) rename %scan(%varlist,&i.,%str( ))  =  &constant.%scan(%varlist,&i.,%str( ))%str(;);
       %end;
     %end;
     %else %do;  %* after *;
       rename %scan(%varlist,&i.,%str( )) = %scan(%varlist,&i.,%str( ))&constant.;
       %if &sascode.=1 %then %do;
         %put %str(  ) rename %scan(%varlist,&i.,%str( )) = %scan(%varlist,&i.,%str( ))&constant.%str(;);
       %end;
     %end;
   %end;  %* end of do i=1 to count *;

  run;

  %if &sascode.=1 %then %do;
    %put run%str(;) ;
    %put  ;
  %end;
 
  %** put things back as they were **;
  proc datasets;
   delete ___&sysjobid.&sysindex.;
  run;
  %let syslast=&dset.;
  options &notes. obs= &obs.;
%mend ren_stem;


