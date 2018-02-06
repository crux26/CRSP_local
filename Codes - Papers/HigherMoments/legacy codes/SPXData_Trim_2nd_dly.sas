/*SPXOpprcd_Merge -> SPXCallPut_Merge -> SPXData_Trim_2nd_dly (or _MnthEnd) */
/*Using SPXData_Trim_2nd_dly.*/
proc sql;
	create table OpFull.exdateseries
	as select distinct(exdate) as exdate
	from OpFull.spxcall_cmpt;
run;
quit;

proc sql;
create table OpFull.spxcall_dly as
select a.*, min(datedif) as min_datedif
from
OpFull.spxcall_cmpt as a
group by date
order by date, datedif, strike_price;
quit;

/*BELOW SHOULD BE RE-CONSIDERED. START AGAIN FROM HERE.*/

/*Excludes 1st month only. Contains 2nd & 3rd month.*/
proc sql;
create table OpFull.spxcall_dly_2 as
select distinct a.*, a.datedif as datedif_2nd_excluded
from 
OpFull.spxcall_dly as a,
OpFull.spxcall_dly as b
where a.date = b.date and a.strike_price = b.strike_price and
a.symbol=b.symbol and a.cp_flag=b.cp_flag and a.spindx=b.spindx
having a.datedif ~= b.min_datedif
order by a.date, a.datedif, a.strike_price;
quit;

/*Choose 1st, 2nd month only.*/
proc sql;
create table OpFull.spxcall_dly_2nd as
select distinct a.*, min(b.datedif) as min_datedif_2nd
from OpFull.spxcall_dly as a
left join
OpFull.spxcall_dly_2 as b
on a.date=b.date and a.symbol=b.symbol and a.cp_flag=b.cp_flag and a.spindx=b.spindx
group by a.date
order by a.date, a.datedif, a.strike_price;
quit;

/**/
/*Put case*/
/**/

proc sql;
create table OpFull.spxput_dly as
select a.*, min(datedif) as min_datedif
from
OpFull.spxput_cmpt as a
group by date
order by date, datedif, strike_price;
quit;
/**/

/*Excludes 1st month only. Contains 2nd & 3rd month.*/
proc sql;
create table OpFull.spxput_dly_2 as
select distinct a.*, a.datedif as datedif_2nd_excluded
from
OpFull.spxput_dly as a,
OpFull.spxput_dly as b
where a.date=b.date and a.strike_price=b.strike_price and
a.symbol=b.symbol and a.cp_flag=b.cp_flag and a.spindx=b.spindx
and a.datedif~=b.min_datedif
order by a.date, a.datedif, a.strike_price;
quit;

proc sql;
create table OpFull.spxput_dly_2nd as
select distinct a.*, min(b.datedif) as min_datedif_2nd
from
OpFull.spxput_dly as a
left join
OpFull.spxput_dly_2 as b
on a.date=b.date and a.symbol=b.symbol and a.cp_flag=b.cp_flag and a.spindx=b.spindx
group by a.date
order by a.date, a.datedif, a.strike_price;
quit;

proc datasets lib=OpFull nolist;
	delete spxcall_dly spxcall_dly_2 spxput_dly spxput_dly_2;
run;
quit;

proc export data = OpFull.exdateseries
outfile = "F:\Dropbox\GitHub\OptionsData\rawdata\exDateSeries.xlsx"
DBMS = xlsx REPLACE;
run;

/*#(rows) > 1m, the max num supported by EXCEL. SO used CSV.*/
proc export data = OpFull.spxCall_dly_2nd
outfile = "F:\Dropbox\GitHub\OptionsData\rawdata\SPXCall_dly_2nd.csv"
DBMS = csv REPLACE;
run;

/*------------------------------------------------------------------------*/
proc export data = OpFull.spxput_dly_2nd
outfile = "F:\Dropbox\GitHub\OptionsData\rawdata\SPXPut_dly_2nd.csv"
DBMS = csv REPLACE;
run;

/*Below is not calculated in Ambiguity_premium.*/
proc export data = myOption.spxdata
outfile = "F:\Dropbox\GitHub\OptionsData\rawdata\SPXData.xlsx"
DBMS = xlsx REPLACE;
run;