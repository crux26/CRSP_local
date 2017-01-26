/*Converting day to month's end not needed for daily data*/

libname a_index "D:\Dropbox\WRDS\CRSP\sasdata\a_indexes";
libname a_stock "D:\Dropbox\WRDS\CRSP\sasdata\a_stock";
libname ff "D:\Dropbox\WRDS\ff\sasdata";
libname mysas "D:\Dropbox\WRDS\CRSP\mysas";
libname myMacro "D:\Dropbox\GitHub\CRSP_local\myMacro";

%let begdate = '01JAN1988'd;
%let enddate = '31DEC2012'd;
%let vars = ticker comnam prc vol ret shrout shrflg;
%let mkt_index = vwretd;
%let begyear = year(&begdate);
%let endyear = year(&enddate);

/*As the codes below takes too much time to run every time I test this whole code,*/
/*I commented the codes below.*/
/*------------------------------------------------*/
/*------------------------------------------------*/
%include myMacro('SetDate.sas');
%SetDate(data=mysas.dsf, set=a_stock.dsf, date=date, begdate=&begdate, enddate=&enddate);
%SetDate(data=mysas.dsia, set=a_index.dsia, date=caldt, begdate=&begdate, enddate=&enddate);

proc sql;
create table mysas.dsf_mrgd
as 
select a.*, b.vwretd as vwretd, b.ewretd as ewretd
from
	mysas.dsf as a
left join
	mysas.dsia as b
on a.date = b.date;
quit;

/*-------------*/
/*Subsample used; condition on permno*/
%let begdate = '01JAN1988'd;
%let enddate = '31DEC1992'd;

data mysas.dsf_smaller;
set mysas.dsf_mrgd;
where 10000 <= permno <= 15000 &
&begdate <= date <= &enddate;
run;
/*------------------------------------------------*/
/*------------------------------------------------*/

/*%include myMacro('nonMissing.sas');*/
/*%nonMissing(data=mysas.dsf_mrgd2, set=mysas.dsf_mrgd(keep=permno date vol prc ret vwretd ewretd), var=prc ret vwretd ewretd);*/
/*Above macro not used below as it cannot allow year, month, prc calculation*/

data mysas.dsf_mrgd2; 
set mysas.dsf_mrgd(keep=permno date vol prc ret vwretd ewretd);
year = year(date);
month = month(date);
prc = abs(prc);
where prc ^= . &
ret ^= . &
vwretd ^=. &
ewretd ^=. ;
run;

/*Start again from here*/

proc sort data=mysas.dsf_smaller2;
	by permno date;
run;

data mysas.dsf_smaller3; set mysas.dsf_smaller2;
ObsNum+1;
by permno year;
if first.year then ObsNum=1;
run;


proc reg data=mysas.dsf_smaller3
outest =mysas.beta noprint;
model ret = vwretd;
by permno year;
where ObsNum >= 200;
run;

proc sort data = mysas.beta;
by year permno;
run;

%include myMacro('SummRegResult_custom.sas');
%SummRegResult_custom(data=mysas.beta, out=mysas.PrdcStat, var=intercept vwretd, by=year);

%include myMacro('Trans.sas');
%Trans(data=mysas.PrdcStat, out=mysas.PrdcStat2, var=intercept vwretd, id=_STAT_, by=year );

proc sort data=mysas.PrdcStat2;
by coeff year;
run;

/*Avg of year is dropped as it is meaningless*/
%include myMacro('ObsAvg.sas');
%ObsAvg(data=mysas.PrdcStat2, out=mysas.AvgStat, by=coeff, drop=_TYPE_ _FREQ_ year);


/**/
proc datasets lib=mysas nolist;
delete dsf_smaller dsf_smaller2 PrdcStat ;
quit;
run;

proc datasets lib=mysas nolist;
change dsf_smaller3 = dsf_smaller PrdcStat2 = PrdcStat;
quit;
run;
