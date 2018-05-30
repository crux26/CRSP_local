/*This is from Stoffman(https://kelley.iu.edu/nstoffma/fe.html).*/
/*Faster than FM(). By using ODS OUTPUT for a regression, no need to DO loop over slopes of INDEPVARS. */
%MACRO FM2(DATA=, OUT=, DATEVAR=, DEPVAR=, INDEPVARS=, LAGS=) / store des="Fama-MacBeth regression";
    options MSTORED;
    options SASMSTORE=myMacro;
    
	%local oldoptions errors;
	%let oldoptions=%sysfunc(getoption(mprint)) %sysfunc(getoption(notes)) %sysfunc(getoption(source));
	%let errors=%sysfunc(getoption(errors));
	options nonotes nomprint nosource errors=0;
	ods listing close;
	ods exclude all;
	ods graphics off;
	ods noresults;
	%put ### START;
	%put ### SORTING...PREPARING DATA FOR RUNNING FM REGRESSIONS...;

	proc printto log=junk;
	run;

	proc sort data=&DATA out=_temp;
		by &DATEVAR;
	run;

	proc printto;
	run;

	%put ### SORTING DONE!;
	%put ### RUNNING CROSS-SECTIONAL FM REGRESSIONS...;

	proc printto log=junk;
	run;

	/*EDF option useless with ODS OUTPUT*/
	proc reg data=_temp;
		by &DATEVAR;
		model &DEPVAR = &INDEPVARS;
		ods output ParameterEstimates=pe;
	quit;

	proc printto;
	run;
    
	%put ### RUNNING CROSS-SECTIONAL FM REGRESSIONS DONE!;

	/*Since the results from this approach give a time-series,
	it is common practice to use the Newey-West adjustment for standard errors.
	Unlike Stata, this is somewhat complicated in SAS, but can be done as follows:*/
/*Variable: Variable name which contains indepdent variables' names.*/
	proc sort data=pe;
		by variable;
	run;

	/*"Estimate": Reserved keyword for dataset PE.*/
	/*"Const":  meaningless, in fact. Will be the PARAMETER's value.*/
	proc model data=pe;
		by variable;
		instruments const / intonly;
		estimate=const;
		fit estimate / gmm kernel=(bart,%eval(&LAGS+1),0) vardef=n;
		ods output ParameterEstimates=&out;
	run; quit;

	proc sql;
		drop table _temp, pe;
	quit;

	ods listing;
	ods exclude none;
	ods graphics;
	options &oldoptions errors=&errors;
%mend FM2;
