/*NOTE THAT FM REGRESSION ~= TWO-PASS REGRESSION*/
/*With excess returns as factors, even FM regression is not needed*/
/*Instead, time-series regression is enough (with RP restricted to equal E[factor]) */

/* ********************************************************************************* */
/* ******************** W R D S   R E S E A R C H   M A C R O S ******************** */
/* ********************************************************************************* */
/* WRDS Macro: FM                                                                    */
/* Summary   : Performs Fama-MacBeth Regressions. Calculates FM coefficients         */
/*              with Newey-West adjusted standard errors                             */
/* Date      : Nov, 2010                                                             */
/* Author    : Denys Glushkov, WRDS                                                  */
/* Parameters:                                                                       */
/*             - DATA and OUT are input and output datasets                      */
/*             - DATEVAR: date variable in FM cross-sectional regressions            */
/*             - DEPVAR:  dependent variable in FM regressions(e.g.,average returns) */
/*             - INDVARS: list of independent variable separated by space            */
/*             - LAG:     number of lags to be used in the Newey-West adjustments    */
/* ********************************************************************************* */

%MACRO FM(DATA=, OUT=, DATEVAR=, DEPVAR=, INDVARS=, LAG=);
/*libname myMacro "D:\Dropbox\GitHub\CRSP_local\myMacro";*/
/*%include myMacro('NWORDS.sas');*/

/*save existing options*/
/*while running FM, notes, mprint, source and errors are suppressed not to print anything*/
%local oldoptions errors;
%let oldoptions=%sysfunc(getoption(mprint)) %sysfunc(getoption(notes)) %sysfunc(getoption(source)); 
%let errors=%sysfunc(getoption(errors));
options nonotes nomprint nosource errors=0;

%put ### START;
%put ### SORTING...PREPARING DATA FOR RUNNING FM REGRESSIONS...;

proc sort data=&DATA out=_temp;
  by &datevar;
run;

%put ### SORTING DONE!;

%put ### RUNNING CROSS-SECTIONAL FM REGRESSIONS...;
/* PROC PRINTTO log routes the SAS log to a permanent external file or SAS catalog entry */
/*This seems to be not mandatory, but to suppress the log window's output */
/*BELOW will print the log to "...\CRSP_local\"*/
/*Then it does not print the log such as "The data set work._* has * observations and * variables" in the log window. */
proc printto log=junk; run;

/* BELOW yields the TIME-SERIES OF (CROSS-SECTIONAL) REGRESSION COEFFICIENTS */
/* BY RUNNING A CROSS-SECTIONAL REGRESSION W.R.T. &datevar. */
/* --> &datevar should be the data frequency. */
/* If the regression window is an overlapping moving window, */
/* further adjustments should be made - I may find "RRLOOP.sas" useful.*/

/*TWO-PASS REGRESSION IS NOT NEEDED HERE, BECAUSE FACTORS USED HERE */
/*ARE RETURNS, SO CAN CALCULATE "lambda_t" OR FACTOR RISK PREMIUM BEFOREHAND */
/* SO ALL THAT NEEDED HERE IS TO RUN A CROSS-SECTIONAL REGRESSION AT EACH DATE */
/* TO OBTAIN A TIME-SERIES OF CROSS-SECTIONAL REGRESSION COEFFICIENTS (ESTIMATES), */
/* AND THEN CALCULATE THE MEAN OF COEFFICIENTS */

/* NOTE THAT THERE IS NO TIME-SERIES REGRESSION TO ESTIMATE BETA */
/* WHICH ONE DOES IN FIRST-PASS REGRESSION IN TWO-PASS REGRESSION. */
proc reg data=_temp outest=_results edf noprint;
  by &datevar;
  model &depvar=&indvars;
run;

proc printto; run;

%put ### RUNNING CROSS-SECTIONAL FM REGRESSIONS DONE!;

/*Restoring the default log destination*/

/* Create a dummy dataset for appending the results of FM regressions. */
/* The following dataset will contain labeled variables, but no observation. */
data &OUT; set _null_;
format parameter $32. estimate best8. stderr d8. tvalue 7.2 probt pvalue6.4
df best12. stderr_uncorr best12. tvalue_uncorr 7.2  probt_uncorr pvalue6.4;
label stderr='Corrected standard error of FM coefficient';
label tvalue='Corrected t-stat of FM coefficient';
label probt='Corrected p-value of FM coefficient';
label stderr_uncorr='Uncorrected standard error of FM coefficient';
label tvalue_uncorr='Uncorrected t-stat of FM coefficient';
label probt_uncorr='Uncorrected p-value of FM coefficient';
label df='Degrees of Freedom';
run;

%put ### COMPUTING FAMA-MACBETH COEFFICIENTS...;
/*--------------------------START OF THE DO LOOP------------------------*/
%do k=1 %to %nwords(&indvars); /* DO loop up to #(&indvars) */
	%let var=%scan(&indvars,&k,%str(' ')); /* Find k-th word, delimitered by ' '. */

/*1. Compute Fama-MacBeth coefficients as TIME-SERIES MEANS of CROSS-SECTIONAL REGRESSION. */
	/* ODS: Output Delivery System*/
	/* ods listing close: closes the LISTING destination and any files that are associated with it. */

	/* LISTING destination: an ODS destination that produces traditional SAS output (monospace format). */
	/* When you close an ODS destination, ODS does not send output to that destination. */
	/* Closing an unneeded destination frees some system resources */
	ods listing close; /* suppresses printing the SAS output window ("table-like" result). */
	ods html close; /* suppresses printing the SAS output window ("graphical/figure" result). */
    ods exclude all;
    ods noresults;

    /*Try "ods select none" & "ods select all" if needed. */
	proc means data=_results n std t probt;
	  var &var; /* VAR: k-th INDVARS. Note that INDVARS is a vector. */
	  ods output summary=_uncorr;
	run;

/*2. Perform Newey-West adjustment using Bart kernel in PROC MODEL. */
/* When taking time-series means of cross-sectional regression coeffients in _RESULTS, */
/* make an Newey-West adjustment. */
/* Note that (time-series of) cross-sectional regressions are run w/o any adjustment, yielding _RESULTS. */
/* Note that _PARAMS is a robust alternative to _UNCORR, and _PARAMS doesn't use _UNCORR dataset. */

	proc model data=_results; /* PROC MODEL: OLS, 2SLS, 3SLS, GMM, SMM, MC simulation, ... */
		instruments const; 		/* INSTRUMENTS: instrumental variable specification */
	  	&var=const; 				/* &VAR: Independent variable */
	  	fit &var/gmm kernel=(bart,%eval(&lag+1),0); /* KERNEL: PARZEN, BART, QS. Default: (PARZEN, 1, 0.2). */
	  	ods output ParameterEstimates=_params; 		/* ParameterEstimates: SAS-defined ODS table name. */
/*try "ODS trace on/off to trace ODS table names*/
/*(LHS): pre-defined ODS table name, (RHS): designated datset name*/
	quit;
	ods listing;
	ods html;
    ods exclude none;
    ods graphics;
    ods results;


/*3. put the results together*/
/* Merges _RESULTS and _PARAMS (NW adjusted). This merge is for a comparison purpose. */

	/* Variables such as &var._n, &var._stddev, ... are from _UNCORR dataset, from <PROC MEANS, var &VAR>. */
	/* These are automatically generated by PROC MEANS. */
	data _params (drop=&var._n); 
	merge _params
	  _uncorr (rename=(&var._stddev=stderr_uncorr
	  &var._t=tvalue_uncorr
	  &var._probt=probt_uncorr)
	  );
	  stderr_uncorr=stderr_uncorr/&var._n**0.5; 
	  /*CAUTION: this is not sqrt(var), but sqrt(n_{&var})*/
	  /*This is confusing because of renaming (&var._stddev=stderr_uncorr)*/
	  /*In fact, this is stderr_uncorr = &var._stddev / sqrt(n_{&var}), the usual "s/sqrt(n)" */
	  parameter="&var";
	  drop esttype;
	run;

/*	proc printto log=junk;*/
/*	run;*/
	proc append base=&OUT data=_params force;
	run;
/*	proc printto;*/
/*	run;*/
%end;
/*--------------------------END OF THE DO LOOP------------------------*/

    /*house cleaning */
proc sql; 
  drop table _temp, _params, _results, _uncorr;
quit;

options &oldoptions errors=&errors;
%put ### OUTPUT IN THE DATASET &OUT...;
%put ### DONE! ;
%MEND FM;

 /* ********************************************************************************* */
 /* *************  Material Copyright Wharton Research Data Services  *************** */
 /* ****************************** All Rights Reserved ****************************** */
 /* ********************************************************************************* */
