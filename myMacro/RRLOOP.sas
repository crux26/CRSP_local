/*RUN the code and see permno=93432 for an ERROR*/
/*THIS IS NOT AN ERROR: THIS NATURALLY ARISES AS REG WINSIZE IS 36 AND MINWIN IS 12*/
/*IF FIRM EXISTS BETWEEN 12M and 36M, THEN IT WILL YIELD THE SAME REGRESSION RESULTS*/
/*--> NO! SHOULDN'T THE WINDOW START W.R.T. EACH FIRM? IF SO, THEN THIS IS AN UNDESIRED RESULT*/
/*HOWEVER, IF THE WINDOW HAS TO MOVE AT ONCE, THEN IT IS UNAVOIDABLE*/

/*"date2" is "Today"*/
%macro rrloop( data= , out_ds= , model_equation= , id= , date=date ,
             start_date= , end_date= , freq=month, s=1, n=12, regprint=noprint, minwin= );
 
* Start with empty output data sets;
proc datasets nolist;
  delete _all_ds _outest_ds;
run; 

* Prepare input data for by-id-date use;  
proc sort data=&data;
  by &id &date;
run; 
 
* Set the 'by-id' variable;
%let by_id= ; *blank default, no by variable; 
%if %length(&id) > 0 %then %let by_id= by &id;
 
* Determine date range variables;
%let year_date=0;
%let sdate1 =  &start_date;
%let sdate2 =  &end_date;
 
* Make start and end date if missing;
%if &start_date = %str() | &end_date = %str() %then %do;
  proc sql noprint;
    create table _dx1 as 
    select min(&date) as min_date, max(&date) as max_date
    from &data where not missing(&date);
    select min_date into : min_date from _dx1;
    select max_date into : max_date from _dx1;
  quit;
%end;
 
 * SDATE1 and SDATE2 put in sas date number form (1/1/1960=0);
%if &sdate1 = %str() %then %do;
     %let sdate1= &min_date;
%end;

%if &sdate2 = %str() %then %do;
     %let sdate2= &max_date;
%end;

 
*Determine loop frequency parameters;
%if %eval(&n)= 0 %then %let n= &s;
*  if n blank use 1 period (=&s) assumption;
 
* Preliminary date setting for each iteration/loop;
* First end date (idate2) is n periods after the start date;

/*%let idate2= %sysfunc(intnx(&freq,&sdate1,(&n-1),end));*/
/*%let idate1= %sysfunc(intnx(&freq,&idate2,-&n+1,begin));*/

%let idate1= %sysfunc(intnx(&freq,&sdate1,-&n+1,begin));
%let idate2= %sysfunc(intnx(&freq,&idate1,(&n-1),end));

/*%put First loop: &idate1 -- &idate2; */
/*%put   Loop through: &sdate2; */

/*%put _user_; */

%if (&idate2 > &sdate2) %then %do;  
* Dates are not acceptable-- show problem, do not run loop;
  %put PROBLEM-- end date for loop exceeds range  : ( &idate2 > &sdate2 );
%end;

%else %do;  *Dates are accepted-- run loops;
/*  %do %while(&idate2 <= &sdate2);  */
  %do %while(&idate2 <= &sdate2);  
 
  *Define loop start date (idate1) based on inherited end date (idate2);
    
/*    %let idate1= %sysfunc(intnx(&freq,&idate2,-&n+1,begin));*/
/*    %let idate1= %sysfunc(max(&sdate1,&idate1));*/

	
/*    %let idate2= %sysfunc(min(&sdate2,&idate2));*/
 
/*    %put Loop:  &jj -- &date1c &date2c;*/
    %put  Loop: -- &idate1 &idate2;
   
  proc datasets nolist;
    delete _outest_ds;
  run; 
   
  ***** analysis code here -- for each loop;
  * noprint to just make output set;
  %let noprint= noprint;
  %if %upcase(&noprint) = yes | %upcase(&noprint) = print %then %let noprint= ;
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
    regobs= _p_ + _edf_;  * number of observations in regression;
    date1= %sysfunc(max(&sdate1,&idate1));
/*    date2= %sysfunc(min(&idate2,&sdate2));*/
	date2 = &idate2;
    format date1 date2 date9.;
/*BOTH BELOW DO NOT WORK: calculated variable cannot be implemented w/i that data step*/
/*	%if  regobs < &minwin %then delete;*/
/*	%if regobs >= &minwin %then;*/
  run;
   
  * Append results;
  proc datasets nolist;
    append base=_all_ds data=_outest_ds;
	where regobs >= &minwin;
  run; 
   
  * Set next loop end date;
/*  %let idate2= %sysfunc( intnx(&freq,&idate2,&s,end) );*/
  %let idate1= %sysfunc( intnx(&freq,&idate1,&s,end) );
  %let idate2= %sysfunc(intnx(&freq,&idate1,(&n-1),end));
  %end; *end of loop;
   
   
  * Save outout set to desired location; 
  data &out_ds;
    set _all_ds;
  run;
  proc sort data=&out_ds;
    by &id date2;
  run; 
   
%end; * end for date check pass section;  
 
 
%mend rrloop;
