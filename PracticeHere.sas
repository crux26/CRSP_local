/*START AGAIN FROM /AMBIGUITY_CODES/SPXDATA_TRIM_2ND (2017.10.26)*/

/* Currently working on <indadjbm to portfolios>. */
/* # of result firms from <B2M ratio - DT> are too small compared to <B2M ratio - FF>. */

/* WARNING: in PROC SORT, NODUPKEY and NODUPLICATES are DIFFERENT. */
/* NODUPLICATES (=NODUP): delete duplicated observations (records identical to each other). */
/* NODUPKEY: delete observations with duplicate BY values (the sort BY variables). */


/* After that, re-check FF factors replication.sas, and find a way to form portfolio returns */
/* using indadjbm (industry-adjusted B2M). (2017.08.28) */

/*COMPUSTAT: NO MORE /d_na, but /naa (use /nam instead)*/

/*a_ccm.ccmxpf_linktable: almost equivalent to a_ccm.ccmxpf_lnkhist */

/* The identification of a fiscal year is the calendar year in which it ends.*/
/* FY: from t-1, July to t, June prior to 1976.*/
/*ex) FY17: Oct, 2016 ~ Sep, 2017. */
/*ex) datadate=20080531, fyear=2007, fyr=5 --> Jun, 2006 ~ May, 2007 written at 20080531. */
/*ex) datadate=20090930, fyear=2009, fyr=9 --> Aug, 2008 ~ Sep, 2009 written at 20090930. */

/*%include myMacro('SetDate.sas'); WILL NOT work unless */
/*-SASINITIALFOLDER "D:\Dropbox\GitHub\CRSP_local" added to sasv9.cfg in ...\nls\en and \ko*/

/* To automatically point to the macros in this library within your SAS program */
options sasautos=('E:\Dropbox\GitHub\CRSP_local\myMacro\', SASAUTOS) MAUTOSOURCE;
%liblist_lab;
options mstored sasmstore=myMacro;

options sasautos=('E:\Dropbox\GitHub\CRSP_local\myMacro\', SASAUTOS) MAUTOSOURCE;
%liblist_dorm;
options mstored sasmstore=myMacro;

%let begdate = '01MAY1961'd;
%let enddate = '31DEC1965'd;

data dsf_subset;
set bem.dsf_dlret_ff3f;
where date between '01JUL1961'd and '31DEC1966'd;
run;

proc sort data=dsf_subset;
by permno date;
run;

/*WARNING: The range of variable mktrf is so small relative to its mean that there may be loss of accuracy in the computations. You 
         may need to rescale the variable to have a larger value of RANGE/abs(MEAN), for example, by using PROC STANDARD M=0;*/
/*This WARNING is inevitable; standardizing MKTRF would change beta.*/
proc printto log=junk; run;
%let oldoptions=%sysfunc(getoption(mprint)) %sysfunc(getoption(notes)) %sysfunc(getoption(source)); 
%let errors=%sysfunc(getoption(errors));
options nomprint nonotes nosource nosource2 errors=0;
ods results off;
ods listing close;
ods exclude all;
ods graphics off;
%rrloop(data=dsf_subset, out_ds=beta1m, model_equation=exret=mktrf, id=permno, date=date,
start_date=&begdate, end_date=&enddate, freq=month, step=1, n=3, regprint=noprint, minwin=15);

ods listing;
ods exclude none;
ods graphics;
options &oldoptions errors=&errors;
proc printto; run;
/**/









/**/
%let wrds=wrds.wharton.upenn.edu 4016;
options comamid=TCP remote=WRDS;
signon username=ex1k password='Dhssnfl2@';

rsubmit;
data mytaq;
set taq.ct_201301:(where=(SYMBOL='MSFT' and time between '09:30:00't and '16:00:00't)) open=defer;
run;

endrsubmit;
