/*SPXOpprcd_Merge -> SPXData_Merge -> SPXCallPut_Merge -> SPXData_Trim_2nd -> SPXData_Export */
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
	create table myOption.spxcall_mnth_Wed
	as select distinct a.*
	from myOption.spxcall_cmpt as a,
	myOption.spxcall_cmpt as b
	/*Adding the first 2 conditions drastically improves the computation speed*/
	where a.strike_price = b.strike_price &
	a.exdate = b.exdate &
	a.date = intnx('week',b.date,0) +3 /*keep a.date = Wednesday only*/
	order by date, exdate, strike_price;
run;
quit;

proc sql;
	create table myOption.spxput_mnth_Wed
	as select distinct a.*
	from myOption.spxput_cmpt as a,
	myOption.spxput_cmpt as b
	/*Adding the first 2 conditions drastically improves the computation speed*/
	where a.strike_price = b.strike_price &
	a.exdate = b.exdate &
	a.date = intnx('week',b.date,0) +3 /*keep Wednesday only*/
	order by date, exdate, strike_price;
run;
quit;


/*Above parts are copied from SPXData_Trim.*/
/**/
/*----------------------Below is the new part.--------------------------------------*/
data spxcall_mnth_Wed; set myoption.spxcall_mnth_Wed; run;
data spxput_mnth_Wed; set myoption.spxput_mnth_Wed; run;

proc sort data=spxcall_mnth_Wed; by date datedif strike_price; run;
proc sort data=spxput_mnth_Wed; by date datedif strike_price; run;

/*------------------------------------------------------------*/

proc sql;
create table spxcall_mnth_Wed_2nd_only as
select a.*, min(datedif) as min_datedif
from
spxcall_mnth_Wed as a
group by date
order by date, datedif, strike_price;
quit;

/*Excludes 1st month only. Contains 2nd & 3rd month.*/
proc sql;
create table spxcall_mnth_Wed_2nd_only_2 as
select distinct a.*, a.datedif as datedif_2nd_excluded
from 
spxcall_mnth_Wed_2nd_only as a,
spxcall_mnth_Wed_2nd_only as b
where a.date = b.date and a.strike_price = b.strike_price 
having a.datedif ~= b.min_datedif
order by a.date, a.datedif, a.strike_price;
quit;

/*Choose 1st, 2nd month only.*/
proc sql;
create table spxcall_mnth_Wed_2nd as
select distinct a.*, min(b.datedif) as min_datedif_2nd
from spxcall_mnth_Wed_2nd_only as a
left join
spxcall_mnth_Wed_2nd_only_2 as b
on a.date=b.date and a.symbol=b.symbol
group by a.date
having min_datedif=datedif or calculated min_datedif_2nd=datedif
/*Above selects 1st, 2nd month only.*/
order by a.date, a.datedif, a.strike_price;
quit;

/**/
/*Put case*/
/**/

proc sql;
create table spxput_mnth_Wed_2nd_only as
select a.*, min(datedif) as min_datedif
from
spxput_mnth_Wed as a
group by date
order by date, datedif, strike_price;
quit;
/**/

/*Excludes 1st month only. Contains 2nd & 3rd month.*/
proc sql;
create table spxput_mnth_Wed_2nd_only_2 as
select distinct a.*, a.datedif as datedif_2nd_excluded
from
spxput_mnth_Wed_2nd_only as a,
spxput_mnth_Wed_2nd_only as b
where a.date=b.date and a.strike_price=b.strike_price
group by a.date
having a.datedif~=b.min_datedif
order by a.date, a.datedif, a.strike_price;
quit;

proc sql;
create table spxput_mnth_Wed_2nd as
select distinct a.*, min(b.datedif) as min_datedif_2nd
from
spxput_mnth_Wed_2nd_only as a
left join
spxput_mnth_Wed_2nd_only_2 as b
on a.date=b.date and a.symbol=b.symbol
group by a.date
having min_datedif=datedif or calculated min_datedif_2nd=datedif
/*Above selects 1st, 2nd month only.*/
order by a.date, a.datedif, a.strike_price;
quit;

proc datasets lib=work nolist;
	delete spxcall_mnth_Wed_2nd_only spxcall_mnth_Wed_2nd_only_2 
spxput_mnth_Wed_2nd_only spxput_mnth_Wed_2nd_only_2;
run;
quit;

data myoption.spxcall_mnth_Wed_2nd; set spxcall_mnth_Wed_2nd; run;
data myoption.spxput_mnth_Wed_2nd; set spxput_mnth_Wed_2nd; run;

proc export data = myOption.exdateseries
outfile = "D:\Dropbox\GitHub\TRP\data\rawdata\exDateSeries.xlsx"
DBMS = xlsx REPLACE;
run;

proc export data = spxcall_mnth_Wed_2nd
outfile = "D:\Dropbox\GitHub\TRP\data\rawdata\SPXCall_Mnth_2nd.xlsx"
DBMS = xlsx REPLACE;
run;

proc export data = spxput_mnth_Wed_2nd
outfile = "D:\Dropbox\GitHub\TRP\data\rawdata\SPXPut_Mnth_2nd.xlsx"
DBMS = xlsx REPLACE;
run;

proc export data = myOption.spxdata
outfile = "D:\Dropbox\GitHub\TRP\data\rawData\SPXData.xlsx"
DBMS = xlsx REPLACE;
run;
