/*Only at DEC to replicate BEM's table.*/

/* This MktCap is MktCap^FF, which calculates MktCap every June and keep the value constant */
/*until the following May. */

/* Although MktCap is much easier to calculate, trying MktCap^FF for practice. */
/* Bali, Engle, Murray says two methods yields more or less the same results for most of the cases. */

/* Note that this MktCap is NOT "ME" of "BE/ME". */
/* "ME": value of December of year t-1 */
%put _user_;
libname a_index "D:\Dropbox\WRDS\CRSP\sasdata\a_indexes";
libname a_stock "D:\Dropbox\WRDS\CRSP\sasdata\a_stock";
libname ff "D:\Dropbox\WRDS\ff\sasdata";
libname mysas "D:\Dropbox\WRDS\CRSP\mysas";
libname myMacro "D:\Dropbox\GitHub\CRSP_local\myMacro";
libname BEM "D:\Dropbox\GitHub\CRSP_local\Bali, Engle, Murray - replications";

%let begdate = '01JAN1988'd;
%let enddate = '31DEC2012'd;
%let vars = cusip permno permco date prc vol ret shrout;
%let mkt_index = vwretd;
%let begyear = year(&begdate);
%let endyear = year(&enddate);

/*shrcd in (10,11) only*/

%include myMacro('SetDate.sas');
%SetDate(data=BEM.msf, set=a_stock.msf, date=date, begdate=&begdate, enddate=&enddate);
%SetDate(data=BEM.msia, set=a_index.msia, date=caldt, begdate=&begdate, enddate=&enddate);

/*This date manipulation only works for MONTHLY data (not for DAILY data)*/
/*MktCap: See Bali, Engle, Murray, p.148-150 for details. */
/*Below uses "MktCap^FF" of Bali,Engle,Murray, not "MktCap".*/
proc sql;
create table BEM.msf_common
as
select a.*, b.shrcd
from
BEM.msf as a, a_stock.stocknames as b
where a.permno = b.permno &
( b.shrcd in (10,11) ) &
b.namedt <= a.date <= b.nameenddt;
/*( b.shrcd in (10,11) ): common stocks only*/
quit;

data BEM.msf2; set BEM.msf_common;
date = intnx('month',date,1)-1;
year = year(date);
month = month(date);
if month = 6 then do;
	MktCap = abs(prc) * shrout / 1000; 	/*MktCap: measured in $1m unit. */
													/*shrout: measured in #1k unit. */
/*if any(prc,shrout) is missing, then MktCap also missing.*/
	end;
run;

data BEM.MktCap_DEC; set BEM.msf2(keep=&vars year month mktcap) ; run;

proc sort data=BEM.MktCap_DEC; by permno year; run;

/* Keep June's MktCap constant until the following May. */
data BEM.MktCap_DEC2(drop=count _MktCap JuneCount cum_JuneCount); set BEM.MktCap_DEC;
by permno year;
if first.permno then count=0;
count+1;

retain _MktCap;
if missing(MktCap)=0 then _MktCap = MktCap;
if missing(MktCap) then MktCap = _MktCap;
SIZE = log(MktCap);

if month=6 then JuneCount=1;
else JuneCount=0;
retain cum_JuneCount;
if first.permno then cum_JuneCount=0;
cum_JuneCount+JuneCount;

/*cum_JuneCount: No June appearance up to now. */
if cum_JuneCount = 0 then do;
	MktCap=. ;
	SIZE=. ;
end;
run;

proc datasets lib=BEM nolist;
delete MktCap_DEC msf2;
quit;
run;

proc datasets lib=BEM nolist;
change MktCap_DEC2 = MktCap_DEC;
quit;
run;

proc sort data=BEM.MktCap_DEC;
by year month permno;
run;

data BEM.MktCap_DEC; set BEM.MktCap_DEC;
where month= 12;
run;

%include myMacro('SummRegResult_custom.sas');
%SummRegResult_custom(data=BEM.MktCap_DEC, out=BEM.MktCap_DECPrdcStat, var=MktCap, by=year);

%include myMacro('Trans.sas');
%Trans(data=BEM.MktCap_DECPrdcStat, out=BEM.MktCap_DECPrdcStat, var=MktCap, id=_STAT_, by=year );

/*Re-order variables.*/
data BEM.MktCap_DECPrdcStat;
retain year coeff mean StdDev Skew Kurt Min p5 p25 median p75 p95 max n;
set BEM.MktCap_DECPrdcStat;
run;

%include myMacro('ObsAvg.sas');
%ObsAvg(data=BEM.MktCap_DECPrdcStat, out=BEM.MktCap_DECAvgStat, by=coeff, drop=_TYPE_ _FREQ_ year);

/*Re-order variables.*/
data BEM.MktCap_DECAvgStat;
retain year coeff mean StdDev Skew Kurt Min p5 p25 median p75 p95 max n;
set BEM.MktCap_DECAvgStat;
run;

