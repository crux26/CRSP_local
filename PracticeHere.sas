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


proc sort data=optionm.optionmnames out=want nodupkey;
by secid;
run;

data want_;
set want;
if find(issuer, 'VIX') or find(issuer, 'VOLATILITY')>= 1;
/*if find(issuer, '500') or find(issuer, 'index') or find(issuer, 'vix') >= 1;*/
run;

data want__;
set want;
/*if ticker =: 'VIX';*/
if find(issuer, 'CBOE') or find(issuer, 'S&P') or find(issuer, 'S & P')  >= 1;
run;

data want3;
set want;
if secid=108105;
run;

data want4;
set want;
if ticker='VIX' or ticker='VIXW';
run;

/*TICKER=VIX and starts at 20060224 --> seems to be a VIX options (which only supports near 3-months, for unit of 2.5 (or 5, 10) VIX level)*/
/*Might be a option on OEX (S&P 100), not SPX (S&P 500)*/

/*Inconsistency in ticker and issuer. TICKER='VXO' w/ issuer="CBOE MARKET VOLATILITY INDEX"*/
/*while TICKER='VIX' w/ issuer='CBOE OEX VOLATILITY INDEX'*/
/*and TICKER='VXS' w/ issuer='CBOE VOLATILITY INDEX NEW' (<-- this will correspond to VIX futures, not options)*/
data raw;
set OpFull.call_cmpt(where=(secid=117801) sortedby=secid date exdate strike_price );
run;

proc contents data=OpFull.call_cmpt;
run;



/**/
%let wrds=wrds.wharton.upenn.edu 4016;
options comamid=TCP remote=WRDS;
signon username=crux273 password='Dhssnfl2@';

rsubmit;
data mytaq;
set taq.ct_201301:(where=(SYMBOL='MSFT' and time between '09:30:00't and '16:00:00't)) open=defer;
run;

endrsubmit;

/*proc means data=vix.cboe;*/
/*var vix;*/
/*output out=want;*/
/*run;*/

data _;
set a_treas.tfz_dly_ts2;
where kytreasnox=2000067;
run;



/*===================*/
data secprd;
set optionm.secprd;
where secid=108105;
run;

data vix;
set vix.cboe;
keep date vix;
run;

proc sql;
create table mrg as
select a.*, b.vix
from
secprd as a
left join
vix as b
on
a.date = b.date;
quit;

data mrg_;
set mrg;
vix_l = lag(vix);
close_l = lag(close);
return_l = lag(return);
run;


proc corr data=mrg_ out=want noprint;
	var close return vix close_l return_l vix_l;
run;
