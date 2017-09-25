proc sort data=msf out=count_of_permnos(keep=permno) nodupkey;
	where not(missing(ret)) and not(missing(lagsize));
	by permno;
run;

data _null_;
	if 0 then
		set count_of_permnos nobs=nobs;
	call symput('nobs', nobs);
	stop;
run;

/*In the macro or SCL, the following can be used. Note that %IF statement is invalid in the open code.*/

%let dsid=%sysfunc(open(work.count_of_permnos, in)); /*Opens the dataset.*/
%let nobs=%sysfunc(attrn(&dsid, nobs));

%if &dsid>0 %then %let rc=%sysfunc(close(&dsid));/*Closes the dataset.*/

	/*Open&close needed because one is not using DATA step or SCL, so could*/
	/*leave a dataset open, causing problems later.*
