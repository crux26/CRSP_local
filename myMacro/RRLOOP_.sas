/************************************

* RRLOOP - Rolling Regresson Macro  (v1.1);
 * M Boldin WRDS February 2007;

Rolling regression:   least-squares equation is 
estimated multiple times using partially overlapping 
subsamples from a larger set.  This application keeps 
the sample length fixed and increases the beginning 
and ending dates by a particular 'date' increment. 

OLS coefficients from each iteration or loop are 
saved in a output set.

The dataset for the application can have both 
cross-sectional and time-series aspects that allow 
a 'BY' variable in PROC REG to estimate OLS coefficients 
(by company or stock).

The RRLOOP macro routine uses 'named' input arguments:

data =  input set

out_ds = output set for saving results, 
such as OLS coefficients.

model_equation  =  valid model statement 
for PROC REG

id = cross-sectional identifier  
(default: none, pure time series)

date = date variable name (default: date)

start_date= first date in analysis 
(default: first date in data)   

end_date= last date in analysis 
(default: last date in data)   

freq=  frequency of loop interval
(default: month, not necessary the same 
as data dates)
S= frequency periods for moving loop end date forward    
(default: 1, 1-month)

N= length of sample period in term of freq
(default: 12, 12-months) 

regprint= use yes to show regression output
(default: noprint)

Only first three inputs (data, out_ds, and model_equation) 
are required. The remainder have default settings. The 
data= and out_ds=  designations may be two-level names 
such as data=mylib.md and out_ds=mylib.mregout.

Date is the default or assumed date identifier in the 
input set.  If date=year or starts with 'year' (such as 
date=yeara), then the other date variables values must
be a 4 digit year. In all other cases, the date variable 
must be a SAS date, which is a numeric system that is 
oriented around January 1, 1960 as day 0. Valid formats 
for the date parameters are 01JAN2004, 1-1-20004, 
1/1//2004, JAN2004, and 2004. 

The parameters N and S and freq define the interval 
between the end of each sample period and the length 
of each sample period. The default looping frequency 
is months (i.e., monthly) such that all date counting 
to define the loops is based on months, even if the 
underlying data in the analysis is daily. 

To iterate forward one year at a time and to use 24 months 
as each loop sample length, you can use freq= month,
N=12, and S=24 or equivalently freq= year, N=1, and S=2.

Output example where ID=PERMNO and N=36 (months)

permno     date1        date2     _RMSE_       Intercept     VWRETD    regobs

10107     01JAN2002    31DEC2004    0.057470    -.005836843    0.97255      36  
10107     01FEB2002    31JAN2005    0.057446    -.004874504    0.95958      36  
10107     01MAR2002    28FEB2005    0.057358    -.004550887    0.92014      36  

In the output, 'date1' and 'date2' show the date range 
for the sample that corresponds to the estimates that 
are shown in each row. Regobs is a count of regression 
observations.

*********************************/
%macro RRLOOP_
			(  
			data= ,
			out_ds= ,
			model_equation= ,
			id= , date=date ,
			start_date= , 
			end_date= , 
			freq=month, s=1, n=12,
			regprint=noprint
				);
	* Start with empty output data sets;
	proc datasets nolist;
		delete _all_ds _outest_ds;
	run;

	* Prepare input data for by-id-date use;
	proc sort data=&data;
		by &id &date;
	run;

	* Set the 'by-id' variable;
	%let by_id=;

	*blank default, no by variable;
	%if %length(&id) > 0 %then
		%let by_id= by &id;

	* Determine date range variables;
	%if %lowcase(%substr(&date,1,4))= year %then
		%let year_date=1;
	%else %let year_date=0;
	%let sdate1 =  &start_date;
	%let sdate2 =  &end_date;

	* Make start and end date if missing;
	%if &start_date = %str() | &end_date = %str() %then
		%do;

			proc sql noprint;
				create table _dx1 as 
					select min(&date) as min_date, max(&date) as max_date
						from &data where not missing(&date);
				select min_date into : min_date from _dx1;
				select max_date into : max_date from _dx1;
			quit;

		%end;

	* SDATE1 and SDATE2 put in sas date number form (1/1/1960=0);
	%if &sdate1 = %str() %then
		%do;
			%let sdate1= &min_date;
		%end;
	%else
		%do;
			%if (%index(&sdate1,%str(-)) > 1) | (%index(&sdate1,%str(/)) > 1) %then
				%let sdate1= %sysfunc(inputn(&sdate1,mmddyy10.));
			%else %if ( %length(&sdate1)=7 ) %then
				%let sdate1= %sysfunc(inputn(01&sdate1,date9.));
			%else %if ( %length(&sdate1)=8 | %length(&sdate1)=9 ) %then
				%let sdate1= %sysfunc(inputn(&sdate1,date9.));
			%else %if ( %length(&sdate1)=4 ) %then
				%let sdate1= %sysfunc(inputn(01JAN&sdate1,date9.));

			%if &year_date=1 %then
				%let sdate1=%sysfunc(year(&sdate1));
		%end;

	%if &sdate2 = %str() %then
		%do;
			%let sdate2= &max_date;
		%end;
	%else
		%do;
			%if (%index(&sdate2,%str(-)) > 1) | (%index(&sdate2,%str(/)) > 1) %then
				%let sdate2= %sysfunc(inputn(&sdate2,mmddyy10.));
			%else %if ( %length(&sdate2)=7 ) %then
				%do;
					%let sdate2= %sysfunc(inputn(01&sdate2,date9.));
					%let sdate2= %sysfunc(intnx(month,&sdate2,0,end));
				%end;
			%else %if ( %length(&sdate2)=8 | %length(&sdate2)=9 ) %then
				%let sdate2= %sysfunc(inputn(&sdate2,date9.));
			%else %if ( %length(&sdate2)=4 ) %then
				%let sdate2= %sysfunc(inputn(31DEC&sdate2,date9.));

			%if &year_date=1 %then
				%let sdate2=%sysfunc(year(&sdate2));
		%end;

	*Determine loop frequency parameters;
	%if %eval(&n)= 0 %then
		%let n= &s;

	*  if n blank use 1 period (=&s) assumption;
	%if &year_date=1 %then
		%let freq=year;

	*  year frequency case;
	%put Date variable: &date   year_date:  &year_date;
	%put Start and end dates:  &start_date &end_date // &sdate1 &sdate2;

	%if &year_date=0 %then
		%put %sysfunc(putn(&sdate1,date9.)) %sysfunc(putn(&sdate2,date9.));
	%put Freq: &freq   s: &s   n: &n;

	* Preliminary date setting for each iteration/loop;
	* First end date (idate2) is n periods after the start date;
	%if &year_date=1 %then
		%let idate2= %eval(&sdate1+(&n-1));
	%else %let idate2= %sysfunc(intnx(&freq,&sdate1,(&n-1),end));

	%if &year_date=0 %then
		%let idate1= %sysfunc(intnx(&freq,&idate2,-&n+1,begin));
	%else %let idate1= %eval(&idate2-&n+1);
	%put First loop: &idate1 -- &idate2;
	%put   Loop through: &sdate2;

	%if (&idate2 > &sdate2) %then
		%do;
			* Dates are not acceptable-- show problem, do not run loop;
			%put PROBLEM-- end date for loop exceeds range  : ( &idate2 > &sdate2 );
		%end;
	%else
		%do;
			*Dates are accepted-- run loops;
			%let jj=0;

			%do %while(&idate2 <= &sdate2);
				%let jj=%eval(&jj+1);

				*Define loop start date (idate1) based on inherited end date (idate2);
				%if &year_date=0 %then
					%do;
						%let idate1= %sysfunc(intnx(&freq,&idate2,-&n+1,begin));
						%let date1c= %sysfunc(putn(&idate1,date9.));
						%let date2c= %sysfunc(putn(&idate2,date9.));
					%end;

				%if &year_date=1 %then
					%do;
						%let idate1= %eval(&idate2-&n+1);
						%let date1c= &idate1;
						%let date2c= &idate2;
					%end;

				%let idate1= %sysfunc(max(&sdate1,&idate1));
				%put Loop:  &jj -- &date1c &date2c;
				%put        &jj -- &idate1 &idate2;

				proc datasets nolist;
					delete _outest_ds;
				run;

				***** analysis code here -- for each loop;
				* noprint to just make output set;
				%let noprint= noprint;

				%if %upcase(®print) = yes | %upcase(®print) = print %then
					%let noprint=;

				proc reg data=&data 
					outest=_outest_ds  edf 
					&noprint;
					where &date between &idate1 and &idate2;
					model &model_equation;
					&by_id;
				run;

				* Add loop date range variables to output set;
				data _outest_ds;
					set _outest_ds;
					regobs= _p_ + _edf_;

					* number of observations in regression;
					date1= &idate1;
					date2= &idate2;

					%if &year_date=0 %then
						format date1 date2 date9.;
				run;

				* Append results;
				proc datasets nolist;
					append base=_all_ds data=_outest_ds;
				run;

				* Set next loop end date;
				%if &year_date=0 %then
					%let idate2= %sysfunc(intnx(&freq,&idate2,&s,end));
				%else %if &year_date=1 %then
					%let idate2= %eval(&idate2+&s);
			%end;

			* end of loop;
			* Save outout set to desired location;
			data &out_ds;
				set _all_ds;
			run;

			proc sort data=&out_ds;
				by &id date2;
			run;

		%end;

	* end for date check pass section;
%mend RRLOOP_;
