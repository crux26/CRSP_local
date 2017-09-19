/*SPXOpprcd_Merge -> SPXData_Merge -> SPXCallPut_Merge -> SPXData_Trim2S -> SPXData_Export */
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
/*Above parts are copied from SPXData_Trim.*/
/**/
/*----------------------Below is the new part.--------------------------------------*/
data spxcall_mnth; set myoption.spxcall_mnth; run;
data spxput_mnth; set myoption.spxput_mnth; run;

proc sort data=spxcall_mnth; by date datedif strike_price; run;
proc sort data=spxput_mnth; by date datedif strike_price; run;

/*------------------------------------------------------------*/
proc sql;
create table spxcall_mnth_1st as
select a.*, min(datedif) as min_datedif from
spxcall_mnth as a
group by date
having calculated min_datedif=datedif
order by date, datedif, strike_price;
quit;

proc sql;
create table spxput_mnth_1st as
select a.*, min(datedif) as min_datedif from
spxput_mnth as a
group by date
having calculated min_datedif=datedif
order by date, datedif, strike_price;
quit;

proc export data = myOption.exdateseries
outfile = "D:\Dropbox\GitHub\TRP\data\rawdata\exDateSeries.xlsx"
DBMS = xlsx REPLACE;
run;

proc export data = spxcall_mnth_1st
outfile = "D:\Dropbox\GitHub\TRP\data\rawdata\SPXCall_Mnth_1st.xlsx"
DBMS = xlsx REPLACE;
run;

proc export data = spxput_mnth_1st
outfile = "D:\Dropbox\GitHub\TRP\data\rawdata\SPXPut_Mnth_1st.xlsx"
DBMS = xlsx REPLACE;
run;

proc export data = myOption.spxdata
outfile = "D:\Dropbox\GitHub\TRP\data\rawData\SPXData.xlsx"
DBMS = xlsx REPLACE;
run;
