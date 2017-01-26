libname a_index "D:\Dropbox\WRDS\CRSP\sasdata\a_indexes";
libname a_stock "D:\Dropbox\WRDS\CRSP\sasdata\a_stock";
libname ff "D:\Dropbox\WRDS\ff\sasdata";
libname mysas "D:\Dropbox\WRDS\CRSP\mysas";
libname myMacro "D:\Dropbox\GitHub\CRSP_local\myMacro";

%let begdate = '01JAN1988'd;
%let enddate = '31DEC2012'd;
%let vars = ticker comnam prc ret shrout shrflg;
%let mkt_index = vwretd;

%include myMacro('SetDate.sas');
%SetDate(data=mysas.msf, set=a_stock.msf, date=date, begdate=&begdate, enddate=&enddate);
%SetDate(data=mysas.msia, set=a_index.msia, date=caldt, begdate=&begdate, enddate=&enddate);

proc sql;
create table mysas.msf_mrgd_whole
as
select a.*, b.vwretd as vwretd, b.ewretd as ewretd
from
	mysas.msf as a
left join
	mysas.msia as b
on a.date = b.date;
quit;

data mysas.msf_mrgd_subset;
set mysas.msf_mrgd_whole(keep=permno date vol prc ret vwretd ewretd);
date = intnx('month', date, 1)-1;
year = year(date);
month = month(date);
where ret ^= . &
vwretd ^=. &
ewretd ^=. ;
run;

proc sort data=mysas.msf_mrgd_subset;
	by permno date;
run;

/*proc means data=mysas.msf_mrgd_subset;*/
/*run;*/

proc reg data=mysas.msf_mrgd_subset
outest =mysas.beta noprint;
model ret = vwretd;
by permno year;
run;

proc sort data = mysas.beta;
by year permno;
run;

%include myMacro('SummRegResult_custom.sas');
%SummRegResult_custom(data=mysas.beta, out=mysas.BetaPrdcStat, var=intercept vwretd, by=year);

%include myMacro('Trans.sas');
%Trans(data=mysas.BetaPrdcStat, out=mysas.BetaPrdcStat, var=intercept vwretd, id=_STAT_, by=year );

proc sort data=mysas.PrdcStat;
by coeff year;
run;

/*Avg of year is dropped as it is meaningless*/
%include myMacro('ObsAvg.sas');
%ObsAvg(data=mysas.BetaPrdcStat, out=mysas.BetaAvgStat, by=coeff, drop=_TYPE_ _FREQ_ year);


/**/
proc datasets lib=mysas nolist;
delete msf_mrgd_subset msf_mrgd_whole;
quit;
run;
