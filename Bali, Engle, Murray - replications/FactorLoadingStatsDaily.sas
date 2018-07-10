/*Checking Done! (2017.06.30) */
/*Converting day to month's end not needed for daily data*/
/*%include myMacro('SetDate.sas'); WILL NOT work unless */
/*-SASINITIALFOLDER "D:\Dropbox\GitHub\CRSP_local" added to sasv9.cfg in ...\nls\en and \ko*/

%let begdate = '01JAN1963'd;
%let enddate = '31DEC2012'd;
%let vars = ticker comnam prc vol ret shrout shrflg;
%let mkt_index = vwretd;
%let begyear = year(&begdate);
%let endyear = year(&enddate);
/*WINDOW, MINWIN needed for rolling regression, which is NOT run here.*/
/*When using Rolling regression, missing data shouldn't be discarded. */
%let WINDOW = 252; /*Rolling regression needs a window "cap", as it runs overlapping regressions daily*/
%let MINWIN = 200;

/*As the codes below takes too much time to run every time I test this whole code,*/
/*run the codes below with care.*/
/*------------------------------------------------*/
/*------------------------------------------------*/
%include myMacro('SetDate.sas');
%SetDate(data=BEM.dsf, set=a_stock.dsf, date=date, begdate=&begdate, enddate=&enddate);
%SetDate(data=BEM.dsia, set=a_index.dsia, date=caldt, begdate=&begdate, enddate=&enddate);

/* # of rows: 88786347 -> 35963497 for Jan.01.1988 - Dec.31.2012 */
proc sql;
	create table BEM.dsf_common
	as
	select a.*, b.shrcd
	from
	BEM.dsf as a, a_stock.stocknames as b
	where a.permno = b.permno &
	(b.shrcd = 10 or b.shrcd = 11) &
	b.namedt <= a.date <= b.nameenddt;
quit;

proc sql;
create table BEM.dsf_mrgd
as 
select a.*, b.vwretd as vwretd, b.ewretd as ewretd,
	c.mktrf as mktrf, c.smb as smb, c.hml as hml, c.umd as umd, c.rf as rf,
	(abs(a.ret)>=0) as count 
from
	BEM.dsf_common as a
left join
	BEM.dsia as b
on a.date = b.date
left join
	ff.factors_daily as c
on a.date = c.date
order by permno, date;
quit;

/*-------------*/
/*Subsample used; condition on permno*/
/*%let begdate = '01JAN1988'd;*/
/*%let enddate = '31DEC1992'd;*/
/**/
/*data BEM.dsf_smaller;*/
/*set BEM.dsf_mrgd;*/
/*where 10000 <= permno <= 15000 &*/
/*&begdate <= date <= &enddate;*/
/*run;*/
/*------------------------------------------------*/
/*------------------------------------------------*/

/*%include myMacro('nonMissing.sas');*/
/*%nonMissing(data=BEM.dsf_mrgd2, set=BEM.dsf_mrgd(keep=permno date vol prc ret vwretd ewretd), var=prc ret vwretd ewretd);*/
/*Above macro not used below as it cannot allow year, month, prc calculation*/

/*"n" created by proc expand can be used alternatively for rolling regression*/
/*in lieu of "max_obs"*/
/*proc printto log=junk; run;*/
/*proc expand data=BEM.dsf_mrgd out=BEM.dsf_smaller method=none;*/
/*by permno;*/
/*id date;*/
/*convert count=n / transformout = (MOVSUM &WINDOW.);*/
/*quit;*/
/*run;*/
/*proc printto; run;*/

data BEM.dsf_smaller; 
set BEM.dsf_mrgd(keep=permno date vol prc ret vwretd ewretd mktrf smb hml umd rf);
year = year(date);
month = month(date);
day = day(date);
prc = abs(prc);

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
/* Instead of deleting the null file, can use the indicator variable count = abs(ret)>=0 */
/* For the max_obs, count can be aggregated via moving average through proc expand*/
/* Advantage of this: no "missing date" in observations*/

proc sort data=BEM.dsf_smaller;
	by permno date;
run;

/*WILL RUN REG. ONCE EVERY YEAR W.R.T. EACH FIRM IF (#DATA W/I A YEAR >= 10),*/
/*SO "FIRST.YEAR" IS THE RIGHT ONE, NOT "FIRST.PERMNO"*/
data BEM.dsf_smaller2 /view=BEM.dsf_smaller2; set BEM.dsf_smaller;
ObsNum+1;
by permno year;
if first.year then ObsNum=1;
run;

proc sql;
create table BEM.dsf_smaller3 as
select *, max(ObsNum) as max_obs
from BEM.dsf_smaller2
group by permno, year
order by permno, date;
quit;

/*should specify memtype=view to delete view table*/
proc datasets lib=BEM memtype=view nolist;
  delete dsf_smaller2;
run;
quit;

proc datasets lib=BEM nolist;
  change dsf_smaller3 = dsf_smaller2;
run;
quit;

/*Regression not run if (a firm's #data in a given year < 200)*/
/*For the rolling regression, */
proc reg data=BEM.dsf_smaller2
outest =BEM.FactorLoadingd edf noprint;
model exret = mktrf smb hml umd;
by permno year;
where max_obs >= 200;
run;

data BEM.FactorLoadingd; set BEM.FactorLoadingd;
regobs = _p_ + _edf_;
run;

proc sort data = BEM.FactorLoadingd;
by year permno;
run;

%include myMacro('SummRegResult_custom.sas');
%SummRegResult_custom(data=BEM.FactorLoadingd, out=BEM.FactorLoadingDPrdcStat, var=intercept mktrf smb hml umd, by=year);

%include myMacro('Trans.sas');
%Trans(data=BEM.FactorLoadingDPrdcStat, out=BEM.FactorLoadingDPrdcStat, var=intercept mktrf smb hml umd, id=_STAT_, by=year );

proc sort data=BEM.FactorLoadingDPrdcStat;
by coeff year;
run;

/*Avg of year is dropped as it is meaningless*/
%include myMacro('ObsAvg.sas');
%ObsAvg(data=BEM.FactorLoadingDPrdcStat, out=BEM.FactorLoadingDAvgStat, by=coeff, drop=_TYPE_ _FREQ_ year);

data BEM.FactorLoadingDPrdcStat;
retain year coeff mean StdDev Skew Kurt Min p5 p25 median p75 p95 max n;
set BEM.FactorLoadingDPrdcStat;
run;

data BEM.FactorLoadingDAvgStat;
retain year coeff mean StdDev Skew Kurt Min p5 p25 median p75 p95 max n;
set BEM.FactorLoadingDAvgStat;
run;


/**/
proc datasets lib=BEM nolist;
delete dsf_smaller ;
run;
quit;

proc datasets lib=BEM nolist;
change dsf_smaller2 = dsf_smaller ;
run;
quit;
