/*Checking Done! (2017.06.30) */
/*%include myMacro('SetDate.sas'); WILL NOT work unless */
/*-SASINITIALFOLDER "D:\Dropbox\GitHub\CRSP_local" added to sasv9.cfg in ...\nls\en and \ko*/

%let begdate = '01JAN1988'd;
%let enddate = '31DEC2012'd;
/*%let enddate = '31DEC1989'd;*/
%let vars = ticker comnam prc ret shrout shrflg;
%let mkt_index = vwretd;

%include myMacro('SetDate.sas');
%SetDate(data=BEM.msf, set=a_stock.msf, date=date, begdate=&begdate, enddate=&enddate);
%SetDate(data=BEM.msia, set=a_index.msia, date=caldt, begdate=&begdate, enddate=&enddate);

proc sql;
create table BEM.msf_common
as
select a.*, b.shrcd
from
BEM.msf as a, a_stock.stocknames as b
where a.permno = b.permno &
/*(b.shrcd = 10 or b.shrcd = 11) &*/
( b.shrcd in (10,11) ) &
b.namedt <= a.date <= b.nameenddt;
quit;

proc sql;
	create table BEM.msf_mrgd_whole
	as
	select a.*, b.vwretd as vwretd, b.ewretd as ewretd, c.mktrf as mktrf, c.smb as smb, c.hml as hml, c.umd as umd, c.rf as rf
	from
		BEM.msf_common as a
	left join
		BEM.msia as b
	on a.date = b.caldt
	left join
	ff.factors_monthly as c
	on a.date = c.dateff;
quit;

data BEM.msf_mrgd_subset;
	set BEM.msf_mrgd_whole(keep=permno date vol prc ret vwretd ewretd mktrf smb hml umd rf);
	date = intnx('month', date, 1)-1;
	year = year(date);
	month = month(date);
	day = day(date);

	vwexretd = vwretd - rf;
	ewexretd = ewretd - rf;
	exret = ret - rf;

	if exret = . then delete;
	if vwexretd =. then delete;
	if ewexretd =. then delete;
	label vwexretd = "Value-Weighted Excess Return-incl. dividends";
	label ewexretd = "Equal-Weighted Excess Return-incl. dividends";
	label exret = "Excess Return";
run;

proc sort data=BEM.msf_mrgd_subset;
	by permno date;
run;

/*WILL RUN REG. ONCE EVERY YEAR W.R.T. EACH FIRM IF (#DATA W/I A YEAR >= 10),*/
/*SO "FIRST.YEAR" IS THE RIGHT ONE, NOT "FIRST.PERMNO"*/
/*Note that this regression is non-overlapping, annual regression,*/
/*NOT an overlapping monthly regression with past 12 month*/
data BEM.msf_mrgd_subset;
	set BEM.msf_mrgd_subset;
	ObsNum+1;
	by permno year;
	if first.year then ObsNum=1;
run;

proc sql;
create table BEM.msf_mrgd_subset2 as
select *, max(ObsNum) as max_obs
from BEM.msf_mrgd_subset
group by permno, year;
quit;

proc datasets lib=BEM nolist;
	delete msf_mrgd_subset;
run;
quit;

proc datasets lib=BEM nolist;
	change msf_mrgd_subset2 = msf_mrgd_subset;
run;
quit;

proc sort data = BEM.msf_mrgd_subset;
by permno date;
run;

/*Regression not run if (a firm's #data in a given year < 10)*/
proc reg data=BEM.msf_mrgd_subset
	outest =BEM.FactorLoadingm edf noprint;
	model exret = mktrf smb hml umd;
	by permno year;
	where max_obs >= 10;
run;

data BEM.FactorLoadingm; set BEM.FactorLoadingm;
regobs = _p_ + _edf_;
run;

proc sort data = BEM.FactorLoadingm out=BEM.FactorLoadingm2;
	by year permno;
run;

proc datasets lib=BEM nolist; delete FactorLoadingm; run;
proc datasets lib=BEM nolist; change FactorLoadingm2=FactorLoadingm; run;

%include myMacro('SummRegResult_custom.sas');
%SummRegResult_custom(data=BEM.FactorLoadingm, out=BEM.FactorLoadingMPrdcStat, var=intercept mktrf smb hml umd, by=year);

%include myMacro('Trans.sas');
%Trans(data=BEM.FactorLoadingMPrdcStat, out=BEM.FactorLoadingMPrdcStat, var=intercept mktrf smb hml umd, id=_STAT_, by=year );

proc sort data=BEM.FactorLoadingMPrdcStat;
	by coeff year;
run;

data BEM.FactorLoadingMPrdcStat;
	retain year coeff mean StdDev Skew Kurt Min p5 p25 median p75 p95 max n;
	set BEM.FactorLoadingMPrdcStat;
run;

/*Avg of year is dropped as it is meaningless*/
%include myMacro('ObsAvg.sas');
%ObsAvg(data=BEM.FactorLoadingMPrdcStat, out=BEM.FactorLoadingMAvgStat, by=coeff, drop=_TYPE_ _FREQ_ year);
/*%ObsAvg(data=BEM.FactorLoadingMPrdcStat, out=BEM.FactorLoadingMAvgStat, by=descending coeff, drop=_TYPE_ _FREQ_ year);*/

data BEM.FactorLoadingMAvgStat;
	retain year coeff mean StdDev Skew Kurt Min p5 p25 median p75 p95 max n;
	set BEM.FactorLoadingMAvgStat;
run;

/**/
proc datasets lib=BEM nolist;
	delete msf_mrgd_subset msf_mrgd_whole;
run;
quit;

