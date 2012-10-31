 /*============================================================================
    Program Name: LSI_fast_track.sas
    Author:Alberto Negron
    Date:2010-02-12
    Email:albertonegron@gmail.com
 ============================================================================
    Purpose: Step by Step example for Latent Semantic Index




 ============================================================================
     Log:
     Version                Date            Author          Comments
     1.0.0              2010-02-12            AN            Creation Date
 ============================================================================
 */
 

/*LSI: Fast Track*/


Data A;
input terms $ 8. d1 d2 d3 q;
cards;
a        1 1 1 0
arrived  0 1 1 0
damaged  1 0 0 0
delivery 0 1 0 0
fire     1 0 0 0
gold     1 0 1 1
in       1 1 1 0
of       1 1 1 0
shipment 1 0 1 0
silver   0 2 0 1
truck    0 1 1 1
;


ods output EigenValues=S;
ods output EigenVectors=V;
proc princomp data=A
outstat=Aout(where=(_type_ in ('EIGENVAL', 'USCORE')))
noint cov ;
var d1-d3;
run;

Data S;
set S(keep=number Eigenvalue);
SingValues=sqrt(Eigenvalue*11);
InverseSV=1/SingValues;
array myD {3} ds1-ds3;
do i=1 to 3;
myd{i}=0;
if i=number then myd{i}=InverseSV;
end;
keep ds1-ds3;
run;


Data VS;
	array VecV {3} Prin1-Prin3;
	array VecS {3} ds1-ds3;
	array MatS {3,3} _temporary_;
	array result {3} Vs1-Vs3;
set V;
	if _n_=1 then do;
			do i=1 to 3;
				set S point=i;
					do j=1 to 3;
						MatS{i,j} = VecS{j};
					end;
			end;
	end;

do j=1 to 3;
	Result{j} = 0;
	do i=1 to 3;
		Result{j} = Result{j} + VecV{i}*MatS{i,j};
	end;
end;
keep Vs: ;
run;


Data U;
	array VecA {3} d1-d3;
	array VecVs {3} Vs1-Vs3;
	array MatVs {3,3} _temporary_;
	array result {3} u1-u3;
set A;
	if _n_=1 then do;
			do i=1 to 3;
				set VS point=i;
				do j=1 to 3;
					MatVs{i,j} = VecVs{j};
				end;
			end;
	end;
	do j=1 to 3;
		Result{j} = 0;
		do i=1 to 3;
			Result{j} = Result{j} + VecA{i}*MatVS{i,j};
		end;
	end;
keep terms u: ;
run;


proc fastclus data=u maxc=20 maxiter=10 out=clus; 
      var u1 u2 ; 
   run;

proc sort data=clus; by cluster;run;

