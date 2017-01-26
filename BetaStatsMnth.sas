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

proc means data=mysas.beta noprint nway;
output out=mysas.PrdcStat(drop=_TYPE_ _FREQ_)  ;
var intercept vwretd;
by year;
run;

/**/
/**/

proc means data=mysas.beta noprint nway;
output out=mysas.PrdcStat2(drop=_TYPE_ _FREQ_) 
mean= std= skew= kurt=
min= p5= p25= median= p75= p95= max= n= /autoname;
var intercept vwretd;
by year;
run;

proc transpose data=mysas.PrdcStat2 out=mysas.temp;
/*by year;*/
run;

data mysas.temp1;
set mysas.temp;
varname=scan(_name_,1,'_');
stat=scan(_name_,2,'_');
drop _name_;
run;

proc sort data=mysas.temp1;
by stat;
run;

proc transpose data=mysas.temp1 out=mysas.temp3(drop=_name_);
by stat ;
id varname;
var col1;
run;

/*ods output summary=with_stackods(drop=_control_);*/
/*proc means data=mysas.beta stackodsoutput noprint nway mean std skew kurt min p5 p25 median p75 p95 max n;*/
/*var intercept vwretd;*/
/*by year;*/
/*run;*/


%include myMacro('SummRegResult.sas');
%SummRegResult(data=mysas.beta, out=mysas.PrdcStat, var=intercept vwretd, by=year);

%include myMacro('Trans.sas');
%Trans(data=mysas.PrdcStat, out=mysas.PrdcStat, var=intercept vwretd, id=_STAT_, by=year );

proc sort data=mysas.PrdcStat;
by coeff year;
run;

/*Avg of year is dropped as it is meaningless*/
%include myMacro('ObsAvg.sas');
%ObsAvg(data=mysas.PrdcStat, out=mysas.AvgStat, by=coeff, drop=_TYPE_ _FREQ_ year);


/**/
proc datasets lib=mysas nolist;
delete msf_mrgd_subset msf_mrgd_whole;
quit;
run;
