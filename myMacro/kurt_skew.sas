/*%sysevalf(%superq(by)=, boolean): by=; then returns 1. by=' ' or by=. then returns 0. */

%macro kurt_skew(datain=, dataout=, by=permno, var=ret);

proc sort data=&datain out=&datain._0; by permno date; run;

proc univariate data=&datain._0 noprint normaltest outtable=&dataout(keep=permno _VAR_ _kurt_ _skew_ _normal_ _probn_) ;
	by &by; var &var;
run;

/*proc univariate data=&datain noprint normaltest outtable=&dataout(keep=permno _VAR_ _kurt_ _skew_ _normal_ _probn_) ;*/
/*%if not %sysevalf(%superq(by)=, boolean) %then %do;*/
/*	by &by; var &var;*/
/*%end;*/
/*%else %do;*/
/*	var &var;*/
/*%end;*/
/*run;*/

proc sort data=&dataout; by _VAR_ permno; run;

proc sql;
drop table &datain._0;
quit;

%mend;
