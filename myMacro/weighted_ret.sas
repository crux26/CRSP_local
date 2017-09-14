%macro weighted_ret(freq=freq, datain=, dataout=&datain._PF_ret, weight=ME);

proc sort data=&datain out=&datain._00; by permno date; run;
/**/


data &datain._0; set &datain._00; by permno;
year=year(date); month=month(date); day=day(date);
%if &freq=m %then %do;
	if year>2007 or (year=2007 and month=12) then ME = abs(prc) * shrout/1000; /* ME in $1m unit */
%end;

%else %do;
	if year>2007 or (year=2007 and month=12 and day=31) then ME = abs(prc) * shrout/1000; /* ME in $1m unit */
%end;
run;

proc sort data=&datain._0 out=&datain._1; by permno date; run;

data &datain._2; set &datain._1; by permno;
lag_ME = lag(ME);
if first.permno then lag_ME=. ;
run;

proc sort data=&datain._2 out=&datain._3; by date permno; run;

/* ewret */
proc means data=&datain._3 noprint;
where year>=2008;
by date; var ret;
output out=&datain._ewret(drop=_TYPE_ _FREQ_) mean=ewret n=n_firms;
run;

/* vwret */
proc means data=&datain._3 noprint;
where year>=2008;
by date; var ret; weight lag_ME;
output out=&datain._vwret(drop=_TYPE_ _FREQ_) mean=vwret n=n_firms;
run;

proc sql;
create table &datain._PF_ret as
select a.*, b.vwret
from &datain._ewret as a
left join
&datain._vwret as b
on a.date=b.date
order by date;
quit;

proc sql;
drop table &datain._00, &datain._0, &datain._1, &datain._2, &datain._3, &datain._ewret, &datain._vwret ;
quit;

%mend weighted_ret;
