/*Converting day to month's end not needed for daily data*/
/*%include myMacro('SetDate.sas'); WILL NOT work unless */
/*-SASINITIALFOLDER "D:\Dropbox\GitHub\CRSP_local" added to sasv9.cfg in ...\nls\en and \ko*/

libname a_index "D:\Dropbox\WRDS\CRSP\sasdata\a_indexes";
libname a_stock "D:\Dropbox\WRDS\CRSP\sasdata\a_stock";
libname a_treas "D:\Dropbox\WRDS\CRSP\sasdata\a_treasuries";
libname ff "D:\Dropbox\WRDS\ff\sasdata";
libname frb "D:\Dropbox\WRDS\frb\sasdata";
libname mysas "D:\Dropbox\WRDS\CRSP\mysas";
libname myMacro "D:\Dropbox\GitHub\CRSP_local\myMacro";
libname optionm "\\Egy-labpc\WRDS\optionm\sasdata";

%let begdate = '01JAN1988'd;
%let enddate = '31DEC1989'd;
%let vars = ticker comnam prc vol ret shrout shrflg;
%let mkt_index = vwretd;
%let begyear = year(&begdate);
%let endyear = year(&enddate);
/*WINDOW, MINWIN needed for rolling regression, which is not run here*/
%let WINDOW = 252; /*Rolling regression needs a window "cap", as it runs overlapping regressions daily*/
%let MINWIN = 200;

/*As the codes below takes too much time to run every time I test this whole code,*/
/*run the codes below with care.*/
/*------------------------------------------------*/
/*------------------------------------------------*/
%include myMacro('SetDate.sas');
%SetDate(data=mysas.dsf, set=a_stock.dsf, date=date, begdate=&begdate, enddate=&enddate);
%SetDate(data=mysas.dsia, set=a_index.dsia, date=caldt, begdate=&begdate, enddate=&enddate);

/* # of rows: 88786347 -> 35963497 for Jan.01.1988 - Dec.31.2012 */
proc sql;
create table mysas.dsf_common
as
select a.*, b.shrcd
from
mysas.dsf as a, a_stock.stocknames as b
where a.permno = b.permno &
(b.shrcd = 10 or b.shrcd = 11) &
b.namedt <= a.date <= b.nameenddt;
quit;

proc sql;
create table mysas.dsf_mrgd
as 
select a.*, b.vwretd as vwretd, b.ewretd as ewretd,
	c.mktrf as mktrf, c.smb as smb, c.hml as hml, c.umd as umd, c.rf as rf,
	(abs(a.ret)>=0) as count 
from
	mysas.dsf_common as a
left join
	mysas.dsia as b
on a.date = b.date
left join
	mysas.factors_daily as c
on a.date = c.date
order by permno, date;
quit;

/*-------------*/
/*Subsample used; condition on permno*/
/*%let begdate = '01JAN1988'd;*/
/*%let enddate = '31DEC1992'd;*/
/**/
/*data mysas.dsf_smaller;*/
/*set mysas.dsf_mrgd;*/
/*where 10000 <= permno <= 15000 &*/
/*&begdate <= date <= &enddate;*/
/*run;*/
/*------------------------------------------------*/
/*------------------------------------------------*/

/*%include myMacro('nonMissing.sas');*/
/*%nonMissing(data=mysas.dsf_mrgd2, set=mysas.dsf_mrgd(keep=permno date vol prc ret vwretd ewretd), var=prc ret vwretd ewretd);*/
/*Above macro not used below as it cannot allow year, month, prc calculation*/

/*"n" created by proc expand can be used alternatively for rolling regression*/
/*in lieu of "max_obs"*/
/*proc printto log=junk; run;*/
/*proc expand data=mysas.dsf_mrgd out=mysas.dsf_smaller method=none;*/
/*by permno;*/
/*id date;*/
/*convert count=n / transformout = (MOVSUM &WINDOW.);*/
/*quit;*/
/*run;*/
/*proc printto; run;*/

data mysas.dsf_smaller; 
set mysas.dsf_mrgd(keep=permno date vol prc ret vwretd ewretd mktrf smb hml umd rf);
year = year(date);
month = month(date);
prc = abs(prc);

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
/* Instead of deleting the null file, can use the indicator variable count = abs(ret)>=0 */
/* For the max_obs, count can be aggregated via moving average through proc expand*/
/* Advantage of this: no "missing date" in observations*/

proc sort data=mysas.dsf_smaller;
	by permno date;
run;

/*WILL RUN REG. ONCE EVERY YEAR W.R.T. EACH FIRM IF (#DATA W/I A YEAR >= 10),*/
/*SO "FIRST.YEAR" IS THE RIGHT ONE, NOT "FIRST.PERMNO"*/
data mysas.dsf_smaller2 /view=mysas.dsf_smaller2; set mysas.dsf_smaller;
ObsNum+1;
by permno year;
if first.year then ObsNum=1;
run;

proc sql;
create table mysas.dsf_smaller3 as
select *, max(ObsNum) as max_obs
from mysas.dsf_smaller2
group by permno, year;
quit;

/*should specify memtype=view to delete view table*/
proc datasets lib=mysas memtype=view nolist;
  delete dsf_smaller2;
run;
quit;

proc datasets lib=mysas nolist;
  change dsf_smaller3 = dsf_smaller2;
run;
quit;

proc sort data = mysas.dsf_smaller2;
by permno date;
run;


/*Regression not run if (a firm's #data in a given year < 200)*/
/*For the rolling regression, */
proc reg data=mysas.dsf_smaller2
outest =mysas.betad edf noprint;
model ret = mktrf smb hml umd;
by permno year;
where max_obs >= 200;
run;

data mysas.betad; set mysas.betad;
regobs = _p_ + _edf_;
run;

proc sort data = mysas.betad;
by year permno;
run;

%include myMacro('SummRegResult_custom.sas');
%SummRegResult_custom(data=mysas.betad, out=mysas.BetaDPrdcStat, var=intercept mktrf smb hml umd, by=year);

%include myMacro('Trans.sas');
%Trans(data=mysas.BetaDPrdcStat, out=mysas.BetaDPrdcStat, var=intercept mktrf smb hml umd, id=_STAT_, by=year );

proc sort data=mysas.BetaDPrdcStat;
by coeff year;
run;

/*Avg of year is dropped as it is meaningless*/
%include myMacro('ObsAvg.sas');
%ObsAvg(data=mysas.BetaDPrdcStat, out=mysas.BetaDAvgStat, by=coeff, drop=_TYPE_ _FREQ_ year);

data mysas.BetaDPrdcStat;
retain year coeff mean StdDev Skew Kurt Min p5 p25 median p75 p95 max n;
set mysas.BetaDPrdcStat;
run;

data mysas.BetaDAvgStat;
retain year coeff mean StdDev Skew Kurt Min p5 p25 median p75 p95 max n;
set mysas.BetaDAvgStat;
run;


/**/
proc datasets lib=mysas memtype=view nolist;
delete dsf_smaller ;
run;
quit;


proc datasets lib=mysas nolist;
change dsf_smaller2 = dsf_smaller ;
run;
quit;
