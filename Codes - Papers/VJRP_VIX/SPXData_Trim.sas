/*SPXOpprcd_Merge -> SPXData_Merge -> SPXCallPut_Merge -> SPXData_Trim -> SPXData_Export */
libname a_index "D:\Dropbox\WRDS\CRSP\sasdata\a_indexes";
libname a_stock "D:\Dropbox\WRDS\CRSP\sasdata\a_stock";
libname a_treas "D:\Dropbox\WRDS\CRSP\sasdata\a_treasuries";
libname ff "D:\Dropbox\WRDS\ff\sasdata";
libname frb "D:\Dropbox\WRDS\frb\sasdata";
libname mysas "D:\Dropbox\WRDS\CRSP\mysas";
libname myOption "D:\Dropbox\WRDS\CRSP\myOption";
libname myMacro "D:\Dropbox\GitHub\CRSP_local\myMacro";
libname optionm "\\Egy-labpc\WRDS\optionm\sasdata";

proc sql;
	create table myOption.exdateseries
	as select distinct(exdate) as exdate
	from myOption.spxcall_cmpt;
run;
quit;

/*data myOption.exdateseries;*/
/*set myOption.exdateseries;*/
/*if month(exdate) = lag(month(exdate)) then delete;*/
/*run;*/

proc sql;
	create table myOption.spxcall_mnth
	as select distinct a.*
	from myOption.spxcall_cmpt as a,
	myOption.spxcall_cmpt as b
	/*Adding the first 2 conditions drastically improves the computation speed*/
	where a.strike_price = b.strike_price &
	a.exdate = b.exdate &
	a.date = intnx('week',b.date,0) +3 ;	/*keep a.date = Wednesday only*/
run;
quit;

proc sql;
	create table myOption.spxput_mnth
	as select distinct a.*
	from myOption.spxput_cmpt as a,
	myOption.spxput_cmpt as b
	/*Adding the first 2 conditions drastically improves the computation speed*/
	where a.strike_price = b.strike_price &
	a.exdate = b.exdate &
	a.date = intnx('week',a.date,0) +3; /*keep Wednesday only*/
run;
quit;

proc sort data=myOption.spxcall_mnth;
	by date exdate strike_price;
run;

proc sort data=myOption.spxput_mnth;
	by date exdate strike_price;
run;

data myOption.call1m myOption.call2m myOption.call3m;
set myOption.spxcall_mnth;
if datedif <=22 then output myOption.call1m;
else if 22< datedif <=44 then output myOption.call2m;
else if 44 < datedif <= 64 then output myOption.call3m;
drop datedif;
run;

data myOption.put1m myOption.put2m myOption.put3m;
set myOption.spxput_mnth;
if datedif <= 22 then output myOption.put1m;
else if 22< datedif <=44 then output myOption.put2m;
else if 44< datedif < 64 then output myOption.put3m;
drop datedif;
run;
/**/
proc export data = myOption.exdateseries
outfile = "D:\Dropbox\GitHub\VJRP_VIX\myReturn_Data\exDateSeries.xlsx"
DBMS = xlsx REPLACE;
run;

proc export data = myOption.spxcall_mnth
outfile = "D:\Dropbox\GitHub\VJRP_VIX\myReturn_Data\rawData\SPXCall_Mnth.xlsx"
DBMS = xlsx REPLACE;
run;

proc export data = myOption.spxput_mnth
outfile = "D:\Dropbox\GitHub\VJRP_VIX\myReturn_Data\rawData\SPXPut_Mnth.xlsx"
DBMS = xlsx REPLACE;
run;

proc export data = myOption.exdateseries
outfile = "D:\Dropbox\GitHub\VJRP_VIX\myReturn_Data\rawData\exDateSeries.xlsx"
DBMS = xlsx REPLACE;
run;

proc export data = myOption.call1m
outfile = "D:\Dropbox\GitHub\VJRP_VIX\myReturn_Data\rawData\call1m.xlsx"
DBMS = xlsx REPLACE;
run;

proc export data = myOption.call2m
outfile = "D:\Dropbox\GitHub\VJRP_VIX\myReturn_Data\rawData\call2m.xlsx"
DBMS = xlsx REPLACE;
run;

proc export data = myOption.call3m
outfile = "D:\Dropbox\GitHub\VJRP_VIX\myReturn_Data\rawData\call3m.xlsx"
DBMS = xlsx REPLACE;
run;

proc export data = myOption.put1m
outfile = "D:\Dropbox\GitHub\VJRP_VIX\myReturn_Data\rawData\put1m.xlsx"
DBMS = xlsx REPLACE;
run;

proc export data = myOption.put2m
outfile = "D:\Dropbox\GitHub\VJRP_VIX\myReturn_Data\rawData\put2m.xlsx"
DBMS = xlsx REPLACE;
run;

proc export data = myOption.put3m
outfile = "D:\Dropbox\GitHub\VJRP_VIX\myReturn_Data\rawData\put3m.xlsx"
DBMS = xlsx REPLACE;
run;

proc export data = myOption.spxdata
outfile = "D:\Dropbox\GitHub\VJRP_VIX\myReturn_Data\rawData\SPXData.xlsx"
DBMS = xlsx REPLACE;
run;
