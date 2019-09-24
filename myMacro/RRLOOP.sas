/*Fixed date1, date2 to be the real window. Given window is win_beg, win_end (2018.06.11).*/

/* Checking done! (2017.07.06) */

/*%RRLOOP(data= dsf_smaller2, out_ds= betad_1M, model_equation=ret=mktrf, id=permno , date=date, start_date='01jan1986'd, end_date='31dec2012'd, 
freq=month, step=1, n=1, regprint=noprint, minwin=15);*/

/*Above took 2h 03m for 1986-2012. */
/*%RRLOOP(data= crsp_dsix_smaller2, out_ds= betad_crspmrgd_1M, model_equation=ret=mktrf, id=permno, date=date, start_date='01jan1963'd, end_date='31dec2016'd, */
/*          freq=month, step=1, n=1, regprint=noprint, minwin=15);*/
/*Above took 4h 19m for 1963-2016. */
/*"date2(=min(&idate2,&sdate2))" is "Today"*/
%macro rrloop(data= , out_ds= , model_equation= , id= , date=date ,
			start_date= , end_date= , freq=month, step=1, n=12, regprint=noprint, minwin=, noint=);
	/*%macro rrloop(data= , out_ds= , model_equation= , id= , date=date ,*/
	/*			start_date= , end_date= , freq=month, step=1, n=12, regprint=noprint, minwin=) / store des="Rolling regression";*/
	* Start with empty output data sets;
	proc datasets nolist;
		delete _all_ds _outest_ds;
	run;

	* Prepare input data for by-id-date use;
	proc sort data=&data out=tmp;
		by &id &date;
	run;

	* Set the 'by-id' variable;
	%let by_id=;

	*blank default, no by variable;
	%if %length(&id) > 0 %then
		%let by_id= by &id;

	* Determine date range variables;
	%let sdate1 = %sysfunc(intnx(&freq, &start_date, 0, same));
	%let sdate2 = %sysfunc(intnx(&freq, &end_date, 0, same));

	* Make start and end date if missing;
	%if &start_date = %str() | &end_date = %str() %then
		%do;

			proc sql noprint;
				create table _dx1 as 
					select min(&date) as min_date, max(&date) as max_date
						from tmp where not missing(&date);
				select min_date into : min_date from _dx1;
				select max_date into : max_date from _dx1;

				/* Assign a local variable min_date whose value is _dx1.min_date. */
			quit;

		%end;

	* SDATE1 and SDATE2 put in sas date number form (1/1/1960=0);
	/* sdate1 = &start_date --> missing(sdate1)=1 if missing(start_date)=1. */
	%if &sdate1 = %str() %then
		%do;
			%let sdate1= &min_date;
		%end;

	%if &sdate2 = %str() %then
		%do;
			%let sdate2= &max_date;
		%end;

	*Determine loop frequency parameters;
	%if %eval(&n)= 0 %then
		%let n= &step;

	*  if n blank use 1 period (=&step) assumption;
	* Preliminary date setting for each iteration/loop;
	* First end date (idate2) is n periods after the start date;
	/*Defines idate1 first, w.r.t. &sdate1. Then defines idate2 w.r.t. &idate1. */
	/* By doing so, "idate2" is "today". */
	/*"Floor" idate1 by sdate1 and "Cap" idate2 by sdate2.*/
	/*    %let idate1 = %sysfunc(intnx(&freq, &sdate1,-&n, begin));*/
	%let idate1 = %sysfunc(intnx(&freq, &sdate1,-&n+1, begin));
	%let idate1 = %sysfunc(max(&idate1., &sdate1.));

	/*%put First loop: &idate1 -- &idate2; */
	/*%put Loop through: &sdate2; */
	/*Before below code runs, sdate1='ddmmmyyy'd, which is NOT "numeric date".*/
	/* Hence, "(&idate2 > &sdate2)" returns an error. */
	/* However, if the above comparison is made outside the macro, it runs without an error. */
	%if (&idate1 > &sdate2) %then
		%do;
			* Dates are not acceptable-- show problem, do not run loop;
			%put PROBLEM -- end date for loop exceeds range  : ( &idate2 > &sdate2 );
		%end;
	%else
		%do;
			*Dates are accepted-- run loops;
			%put RRLOOP running...;

            options nosource nosource2 nonotes;
/*			proc printto log=junk new;*/
/*			run;*/

			%do %while(&idate1 <= &sdate2);

				/* Define loop end date (idate2) based on inherited start date (idate1). */
				%let idate2= %sysfunc(intnx(&freq, &idate1, (&n-1), end));

				/*				%let idate2= %sysfunc(intnx(&freq, &idate1, &n, end));*/
				/*  %put  Loop: -- &idate1 &idate2;*/
				proc datasets nolist;
					delete _outest_ds;
				run;

				***** analysis code here -- for each loop;
				* noprint to just make output set;
				/*  %let noprint= noprint;*/
				/*  %if %upcase(&noprint) = yes | %upcase(&noprint) = print %then %let noprint= ;*/

				proc reg data=tmp outest=_outest_ds edf noprint;
					where &date between &idate1 and %sysfunc(min(&idate2,&sdate2));
					model &model_equation / &noint.;
					&by_id;
				run;

				/* Above reg. runs w/o errors even if (&idate1<&sdate1) or (&idate2>&sdate2), */
				/* as reg. uses all available points only and returns no error. */
				* Add loop date range variables to output set;
				data _outest_ds_final;
					set _outest_ds;
					regobs= _p_ + _edf_;
					win_beg = &idate1;
					win_end = &idate2;
					date1 = max(&idate1, &sdate1);
					date2 = min(&idate2, &sdate2);
					by permno;
/*					by &id;*/
					format date1 date2 win_beg win_end date9.;

					/*BOTH BELOW DO NOT WORK: CALCULATED variable cannot be implemented w/i that data step*/
					/*%if regobs < &minwin %then delete;*/
					/*%if regobs >= &minwin %then output;*/
				run;

				* Append results;
				proc datasets nolist;
					append base=_all_ds data=_outest_ds_final(where=(regobs>=&minwin));

					/*where regobs>=&minwin;*/
					/*WHERE in append does NOT work.*/
				run;

				* Set next loop end date;
				/*idate1 previously set as 'END', so 'SAME' here retains 'END'.*/
				%let idate1= %sysfunc( intnx(&freq, &idate1, &step, same) );
			%end;

			*end of loop;
			* Save outest set to desired location;
		%end;

	proc sql;
		create table date2_max
			as select distinct a.permno, min(a.date) as date1_min format date9., max(a.date) as date2_max format date9.
				from tmp as a
					group by a.permno;
	quit;

	proc sql;
		create table out_ds_final
			as select a.*, b.date1_min, b.date2_max
				from 
					_all_ds as a
				left join
					date2_max as b
					on a.permno = b.permno
				group by a.permno
					order by a.permno;
	quit;

	data &out_ds;
		set out_ds_final;
		date1 = max(date1, date1_min);
		date2 = min(date2, date2_max);
		by permno;
		format date1 date2 date9.;
		drop date1_min date2_max;

		/*BOTH BELOW DO NOT WORK: CALCULATED variable cannot be implemented w/i that data step*/
		/*%if regobs < &minwin %then delete;*/
		/*%if regobs >= &minwin %then output;*/
	run;

	proc sort data=&out_ds;
		by &id date2;
	run;

	* end for date check pass section;
	proc datasets lib=work nolist;
		delete tmp _all_ds _outest_ds: out_ds: date2_max;
	quit;

/*	proc printto; run;*/
	options source source2 notes;
	

	%put RRLOOP done.;
%mend rrloop;
