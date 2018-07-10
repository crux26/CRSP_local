/*Checking done! (2017.06.29).*/
/* Can be used for both trimming and winsorization. */
/* ********************************************************************************* */
/* ******************** W R D S   R E S E A R C H   M A C R O S ******************** */
/* ********************************************************************************* */
/* WRDS Macro: WINSORIZE                                                             */
/* Summary   : Winsorizes or Trims Outliers                                          */
/* Date      : April 14, 2009                                                        */
/* Author    : Rabih Moussawi, WRDS                                                  */
/* Variables : - INSET and OUTSET are input and output datasets                      */
/*             - SORTVAR: sort variable used in ranking                              */
/*             - VARS: variables to trim and winsorize                               */
/*             - PERC1: trimming and winsorization percent, each tail (default=1%)   */
/*             - TRIM: trimming=1/winsorization=0, default=0                         */
/* ********************************************************************************* */
%MACRO WINSORIZE (INSET=,OUTSET=,SORTVAR=,VARS=,PERC1=1,TRIM=0);
	/* List of all variables */
	%let vars = %sysfunc(compbl(&vars));

	/*compbl(): removes multiple blanks from a character string. */
	%include mymacro('nwords.sas');
	%let nvars = %nwords(&vars);

	/* Display Output */
	%put ### WINSORIZING/TRIMMING START.;

	/* Trimming / Winsorization Options */
	%if &trim=0 %then
		%put ### Winsorization;
	%else %put ### Trimming;
	%put ### Number of Variables:  &nvars;
	%put ### List of Variables:  &vars;
	options nonotes;

	/* Ranking within &sortvar levels */
	%put ### Sorting...;

	proc sort data=&inset;
		by &sortvar;
	run;

	/* 2-tail winsorization/trimming */
	%let perc2 = %eval(100-&perc1);
	%let var2 = %sysfunc(tranwrd(&vars,%str( ),%str(__ )))__;

	/*No blank at the end of the string --> __ at the end once again*/
	/*tranwrd(): Replaces all occurrences of a substring in a character string. */
	/*tranwrd("aabcc", "a", "e") = eebcc */
	%let var_p1 = %sysfunc(tranwrd(&vars,%str( ),%str(__&perc1 )))__&perc1;
	%let var_p2 = %sysfunc(tranwrd(&vars,%str( ),%str(__&perc2 )))__&perc2;

	/*No blank at the end of the string --> __&perc1 at the end once again*/
	/* Calculate upper and lower percentiles */
	proc univariate data=&inset noprint;
		by &sortvar;
		var &vars;
		output out=_perc pctlpts=&perc1 &perc2 pctlpre=&var2;

		/*pctlpts: 50, 95 to 100 by 2.5 */
		/*pctlpre: percentile prefix */
	run;

	%if &trim=1 %then
		%let condition = %str(if myvars(i)>=perct2(i) or myvars(i)<=perct1(i) then myvars(i)=. );
	%else %let condition = %str(myvars(i)=min(perct2(i), max(perct1(i), myvars(i)) ) );

	%if &trim=0 %then
		%put ### Winsorizing at &perc1.%...;
	%else %put ### Trimming at &perc1.%...;

	/* Save output with trimmed/winsorized variables */
	data &outset;
		merge &inset (in=a) _perc;

		/*a=1 if an observation is read from _perc. */
		/*IN= dataset option: Creates a Boolean variable that indicates whether */
		/* the data set contributed data to the current observation. */
		/*These variables are not included in the SAS data set that is being created,*/
		/*unless they are assigned to a new variable. */
		by &sortvar;

		if a;
		array myvars {&nvars} &vars;

		/*ARRAY syntax: ARRAY  array-name { subscript } <$> <length> 
		<array-elements> <(initial-value-list)> ; */
		array perct1 {&nvars} &var_p1;
		array perct2 {&nvars} &var_p2;

		do i = 1 to &nvars;
			if not missing(myvars(i)) then
				do;
					&condition;
				end;
		end;

		drop i &var_p1 &var_p2;
	run;

	/* House Cleaning */
	proc sql;
		drop table _perc;
	quit;

	options notes;
	%put ### WINSORIZING/TRIMMING DONE .;
	%put;
%MEND WINSORIZE;

/* ********************************************************************************* */
/* *************  Material Copyright Wharton Research Data Services  *************** */
/* ****************************** All Rights Reserved ****************************** */
/* ********************************************************************************* */
