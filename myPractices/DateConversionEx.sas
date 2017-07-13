/*sdate1, sdate2 below are not comparable to numeric dates in macro. */
/* Should be converted into numeric dates explicitly by intnx(). */

%let begdate = '03JAN1988'd;
%put %sysfunc(intnx(day, &begdate, 0, same));
%put %sysfunc(intnx(month, &begdate, 0, same));
%put %sysfunc(intnx(month, &begdate, 1, begin));
%put %sysfunc(intnx(month, '03FEB1988'd, 0, same));

%let enddate = '31DEC2012'd;
%let freq = month;
%put begdate: &begdate;
%put enddate: &enddate;

%let sdate1 = &begdate;
%let sdate2 = &enddate;
%put sdate1: &sdate1;
%put sdate2: &sdate2;

%let idate1 = %sysfunc(intnx(&freq, &begdate, 0, begin) );
%let idate2 = %sysfunc(intnx(&freq, &enddate, 0, end) ); 
%put idate1: &idate1;
%put idate2: &idate2;

data _null_;
if &idate2 > &sdate2 then call symputx("tf",0);
else call symputx("tf",1);
run;

%put tf: &tf;

%let sdate1 = %sysfunc(intnx(day, &begdate, 0) );
%let sdate2 = %sysfunc(intnx(day, &enddate, 0) );
%put sdate1: &sdate1;
%put sdate2: &sdate2;

data _null_;
if &idate2 > &sdate2 then call symputx("tf",0);
else call symputx("tf",1);
run;

%put tf: &tf;

%put _user_;
