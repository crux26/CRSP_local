libname a_index "D:\Dropbox\WRDS\CRSP\sasdata\a_indexes";
libname a_stock "D:\Dropbox\WRDS\CRSP\sasdata\a_stock";
libname ff "D:\Dropbox\WRDS\ff\sasdata";
libname mysas "D:\Dropbox\WRDS\CRSP\mysas";
libname myMacro "D:\Dropbox\GitHub\CRSP_local\myMacro";

%let begdate = '01JAN1988'd;
%let enddate = '31DEC2012'd;
%let vars = permno date prc vol ret shrout;
%let mkt_index = vwretd;
%let begyear = year(&begdate);
%let endyear = year(&enddate);

%include myMacro('SetDate.sas');
%SetDate(data=mysas.msf, set=a_stock.msf, date=date, begdate=&begdate, enddate=&enddate);
%SetDate(data=mysas.msia, set=a_index.msia, date=caldt, begdate=&begdate, enddate=&enddate);

/*This date manipulation only works for MONTHLY data (not for DAILY data)*/
data mysas.msf2; set mysas.msf;
/*where 10000 <= permno <= 14955;*/
date = intnx('month',date,1)-1;
year = year(date);
month = month(date);
if month = 12 & shrout ^=0 then
	MktCap = abs(prc) * shrout / 1000000;
run;

data mysas.MktCap; set mysas.msf2(keep=&vars year month mktcap)  ;
run;

proc sort data=mysas.MktCap;
by permno year descending month;
run;

data mysas.MktCap2; set mysas.MktCap;
by permno year;
retain _MktCap ;
if missing(MktCap) =0 then _MktCap = MktCap;
if missing(MktCap) then MktCap = _MktCap;
drop _MktCap;
size = log(MktCap);
run;
quit;

proc datasets lib=mysas nolist;
delete MktCap msf2;
quit;
run;

proc datasets lib=mysas nolist;
change MktCap2 = MktCap;
quit;
run;

proc sort data=mysas.MktCap;
by year month permno;
run;


%include myMacro('SummRegResult_custom.sas');
%SummRegResult_custom(data=mysas.MktCap, out=mysas.MktCapPrdcStat, var=MktCap, by=year);

%include myMacro('Trans.sas');
%Trans(data=mysas.MktCapPrdcStat, out=mysas.MktCapPrdcStat, var=MktCap, id=_STAT_, by=year );

%include myMacro('ObsAvg.sas');
%ObsAvg(data=mysas.MktCapPrdcStat, out=mysas.MktCapAvgStat, by=coeff, drop=_TYPE_ _FREQ_ year);
