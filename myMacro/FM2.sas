/*This is from Stoffman(https://kelley.iu.edu/nstoffma/fe.html).*/
/*Faster than FM(). By using ODS OUTPUT for a regression, no need to DO loop over slopes of INDEPVARS. */
/*options mstored sasmstore=myMacro;*/
%MACRO FM2(DATA=, OUT=, DATEVAR=, byvar=, DEPVAR=, INDEPVARS=, LAGS=) / des="Fama-MacBeth. NW via PROC MODEL";
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

	proc sort data=&DATA out=_temp;
		by &DATEVAR &byvar.;
	run;

	%put ### SORTING DONE!;
	%put ### RUNNING CROSS-SECTIONAL FM REGRESSIONS...;

	/*EDF option useless with ODS OUTPUT*/
	proc printto log=junk_FM;
	run;

	proc reg data=_temp;
		by &DATEVAR &byvar.;
		model &DEPVAR = &INDEPVARS;
		ods output ParameterEstimates=pe;
		ods output nObs = obs(keep=date &byvar. model dependent N Label where=(Label="Number of Observations Used"));
		ods output FitStatistics = fit(keep=date &byvar. model dependent Label2 nValue2 where=(Label2="Adj R-Sq") rename=nValue2=AdjRsq);
	quit;

	proc printto;
	run;

	data pe;
		merge pe obs(drop=Label) fit(drop=Label2);
		by date &byvar. model dependent;
	run;
  
	%put ### RUNNING CROSS-SECTIONAL FM REGRESSIONS DONE!;

	/*Since the results from this approach give a time-series,
	it is common practice to use the Newey-West adjustment for standard errors.
	Unlike Stata, this is somewhat complicated in SAS, but can be done as follows:*/
/*Variable: Variable name which contains indepdent variables' names.*/
	proc sort data=pe;
		by variable &byvar.;
	run;

	/*"Estimate": Reserved keyword for dataset PE.*/
	/*"Const":  meaningless, in fact. Will be the PARAMETER's value.*/
	proc model data=pe;
		by variable &byvar.;
		instruments const / intonly;
		estimate=const;
		fit estimate / gmm kernel=(bart,%eval(&LAGS+1),0) vardef=n;
		ods output ParameterEstimates=&out._;
	run; quit;

	proc model data=pe;
		by variable &byvar.;
		instruments const / intonly;
		n = const;
		fit n;
		ods output ParameterEstimates = nObs;
	run; quit;

	data &out.;
		merge &out._ nObs(keep=Variable &byvar. Estimate rename=Estimate=N);
		by Variable &byvar.;
	run;

	proc sql;
		drop table _temp, pe, obs, fit, nobs, &out._;
	quit;

/*	ods listing;*/
/*	ods exclude none;*/
/*	ods graphics;*/
	options &oldoptions errors=&errors;
%mend FM2;
