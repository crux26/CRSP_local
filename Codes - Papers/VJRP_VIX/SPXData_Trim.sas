/*SPXOpprcd_Merge -> SPXData_Merge -> SPXCallPut_Merge -> SPXData_Trim -> SPXData_Export */
libname a_index "E:\Dropbox\WRDS\CRSP\sasdata\a_indexes";
libname a_stock "E:\Dropbox\WRDS\CRSP\sasdata\a_stock";
libname a_treas "E:\Dropbox\WRDS\CRSP\sasdata\a_treasuries";
libname ff "E:\Dropbox\WRDS\ff\sasdata";
libname frb "E:\Dropbox\WRDS\frb\sasdata";
libname mysas "E:\Dropbox\WRDS\CRSP\mysas";
libname myOption "E:\Dropbox\WRDS\CRSP\myOption";
libname myMacro "E:\Dropbox\GitHub\CRSP_local\myMacro";
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
data myOption.SPXCall_mnth;
set myOption.SPXCall_mnth;
format date exdate yymmddn8.;
run;

data myOption.SPXput_mnth;
set myOption.SPXput_mnth;
format date exdate yymmddn8.;
run;


data myOption.call1m;
set myOption.call1m;
format date exdate yymmddn8.;
run;

data myOption.call2m;
set myOption.call2m;
format date exdate yymmddn8.;
run;

data myOption.call3m;
set myOption.call3m;
format date exdate yymmddn8.;
run;

data myOption.put1m;
set myOption.put1m;
format date exdate yymmddn8.;
run;

data myOption.put2m;
set myOption.put2m;
format date exdate yymmddn8.;
run;

data myOption.put3m;
set myOption.put3m;
format date exdate yymmddn8.;
run;




proc export data = myOption.exdateseries
outfile = "E:\Dropbox\GitHub\VJRP_VIX\myReturn_Data\exDateSeries.csv"
DBMS = csv REPLACE;
run;

proc export data = myOption.spxcall_mnth
outfile = "E:\Dropbox\GitHub\VJRP_VIX\myReturn_Data\rawData\SPXCall_Mnth.csv"
DBMS = csv REPLACE;
run;

proc export data = myOption.spxput_mnth
outfile = "E:\Dropbox\GitHub\VJRP_VIX\myReturn_Data\rawData\SPXPut_Mnth.csv"
DBMS = csv REPLACE;
run;

proc export data = myOption.exdateseries
outfile = "E:\Dropbox\GitHub\VJRP_VIX\myReturn_Data\rawData\exDateSeries.csv"
DBMS = csv REPLACE;
run;

proc export data = myOption.call1m
outfile = "E:\Dropbox\GitHub\VJRP_VIX\myReturn_Data\rawData\call1m.csv"
DBMS = csv REPLACE;
run;

proc export data = myOption.call2m
outfile = "E:\Dropbox\GitHub\VJRP_VIX\myReturn_Data\rawData\call2m.csv"
DBMS = csv REPLACE;
run;

proc export data = myOption.call3m
outfile = "E:\Dropbox\GitHub\VJRP_VIX\myReturn_Data\rawData\call3m.csv"
DBMS = csv REPLACE;
run;

proc export data = myOption.put1m
outfile = "E:\Dropbox\GitHub\VJRP_VIX\myReturn_Data\rawData\put1m.csv"
DBMS = csv REPLACE;
run;

proc export data = myOption.put2m
outfile = "E:\Dropbox\GitHub\VJRP_VIX\myReturn_Data\rawData\put2m.csv"
DBMS = csv REPLACE;
run;

proc export data = myOption.put3m
outfile = "E:\Dropbox\GitHub\VJRP_VIX\myReturn_Data\rawData\put3m.csv"
DBMS = csv REPLACE;
run;

proc export data = myOption.spxdata
outfile = "E:\Dropbox\GitHub\VJRP_VIX\myReturn_Data\rawData\SPXData.csv"
DBMS = csv REPLACE;
run;
