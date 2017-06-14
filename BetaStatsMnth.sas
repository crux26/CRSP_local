/*%include myMacro('SetDate.sas'); WILL NOT work unless */
/*-SASINITIALFOLDER "D:\Dropbox\GitHub\CRSP_local" added to sasv9.cfg in ...\nls\en and \ko*/

libname a_index "D:\Dropbox\WRDS\CRSP\sasdata\a_indexes";
libname a_stock "D:\Dropbox\WRDS\CRSP\sasdata\a_stock";
libname a_treas "D:\Dropbox\WRDS\CRSP\sasdata\a_treasuries";
libname ff "D:\Dropbox\WRDS\ff\sasdata";
libname mysas "D:\Dropbox\WRDS\CRSP\mysas";
libname myMacro "D:\Dropbox\GitHub\CRSP_local\myMacro";
libname optionm "\\Egy-labpc\WRDS\optionm\sasdata";

%let begdate = '01JAN1988'd;
/*%let enddate = '31DEC2012'd;*/
%let enddate = '31DEC1989'd;
%let vars = ticker comnam prc ret shrout shrflg;
%let mkt_index = vwretd;

%include myMacro('SetDate.sas');
%SetDate(data=mysas.msf, set=a_stock.msf, date=date, begdate=&begdate, enddate=&enddate);
%SetDate(data=mysas.msia, set=a_index.msia, date=caldt, begdate=&begdate, enddate=&enddate);

proc sql;
create table mysas.msf_common
as
select a.*, b.shrcd
from
mysas.msf as a, a_stock.msenames as b
where a.permno = b.permno &
(b.shrcd = 10 or b.shrcd = 11) &
b.namedt <= a.date <= b.nameendt;
quit;

proc sql;
	create table mysas.msf_mrgd_whole
	as
	select a.*, b.vwretd as vwretd, b.ewretd as ewretd, c.mktrf as mktrf, c.smb as smb, c.hml as hml, c.umd as umd, c.rf as rf
	from
		mysas.msf_common as a
	left join
		mysas.msia as b
	on a.date = b.date
	left join
	mysas.factors_monthly as c
	on a.date = c.dateff;
quit;

data mysas.msf_mrgd_subset;
	set mysas.msf_mrgd_whole(keep=permno date vol prc ret vwretd ewretd mktrf smb hml umd rf);
	date = intnx('month', date, 1)-1;
	year = year(date);
	month = month(date);

	vwretd = vwretd - rf;
	ewretd = ewretd - rf;
	ret = ret - rf;

	if ret = . then delete;
	if vwretd =. then delete;
	if ewretd =. then delete;
	label vwretd = "Value-Weighted Excess Return-incl. dividends";
	label ewretd = "Equal-Weighted Excess Return-incl. dividends";
	label ret = "Excess Return";
run;

proc sort data=mysas.msf_mrgd_subset;
	by permno date;
run;

/*WILL RUN REG. ONCE EVERY YEAR W.R.T. EACH FIRM IF (#DATA W/I A YEAR >= 10),*/
/*SO "FIRST.YEAR" IS THE RIGHT ONE, NOT "FIRST.PERMNO"*/
/*Note that this regression is non-overlapping, annual regression,*/
/*NOT an overlapping monthly regression with past 12 month*/
data mysas.msf_mrgd_subset;
	set mysas.msf_mrgd_subset;
	ObsNum+1;
	by permno year;
	if first.year then ObsNum=1;
run;

proc sql;
create table mysas.msf_mrgd_subset2 as
select *, max(ObsNum) as max_obs
from mysas.msf_mrgd_subset
group by permno, year;
quit;

proc datasets lib=mysas nolist;
	delete msf_mrgd_subset;
run;
quit;

proc datasets lib=mysas nolist;
	change msf_mrgd_subset2 = msf_mrgd_subset;
run;
quit;

proc sort data = mysas.msf_mrgd_subset;
by permno date;
run;

/*Regression not run if (a firm's #data in a given year < 10)*/
proc reg data=mysas.msf_mrgd_subset
	outest =mysas.betam edf noprint;
	model ret = mktrf smb hml umd;
	by permno year;
	where max_obs >= 10;
run;

data mysas.betam; set mysas.betam;
regobs = _p_ + _edf_;
run;

proc sort data = mysas.betam;
	by year permno;
run;

%include myMacro('SummRegResult_custom.sas');
%SummRegResult_custom(data=mysas.betam, out=mysas.BetaMPrdcStat, var=intercept mktrf smb hml umd, by=year);

%include myMacro('Trans.sas');
%Trans(data=mysas.BetaMPrdcStat, out=mysas.BetaMPrdcStat, var=intercept mktrf smb hml umd, id=_STAT_, by=year );

proc sort data=mysas.BetaMPrdcStat;
	by descending coeff year;
run;

data mysas.BetaMPrdcStat;
	retain year coeff mean StdDev Skew Kurt Min p5 p25 median p75 p95 max n;
	set mysas.BetaMPrdcStat;
run;

/*Avg of year is dropped as it is meaningless*/
%include myMacro('ObsAvg.sas');
%ObsAvg(data=mysas.BetaMPrdcStat, out=mysas.BetaMAvgStat, by=descending coeff, drop=_TYPE_ _FREQ_ year);

data mysas.BetaMAvgStat;
	retain year coeff mean StdDev Skew Kurt Min p5 p25 median p75 p95 max n;
	set mysas.BetaMAvgStat;
run;

/**/
proc datasets lib=mysas nolist;
	delete msf_mrgd_subset msf_mrgd_whole;
run;
quit;

