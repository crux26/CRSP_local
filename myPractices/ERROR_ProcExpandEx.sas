/*Problematic PROC EXPAND(): missing with "C" other than "." is the problem..*/
/*PROC EXPAND automatically interpolates between missing data (NOTAKNOT is the default).*/


data _63723;
	set a_stock.msf(where=(permno=63723) keep=permno date ret);
run;

proc sort data=_63723 out=_63723;
	by permno date;
run;

proc expand data=_63723 out=_63723_;
/*proc expand data=_63723 out=_63723_ method=none;*/
	id date;
	convert ret=ret_ld1 / transformout=(reverse lag 1 reverse);
	by permno;
run;

/*No problem with SQL.*/
proc sql;
create table _63723_ as
select a.*, b.ret as ret_ld1
from
_63723 as a
left join
_63723 as b
on
b.permno = a.permno and b.date = intnx('month', a.date, -1, 'e');
quit;





/*===========================*/
/*missing obs retained until the next ~missing obs.*/
data test1;
set _63723;
ret = .;
if date='31DEC1980'd then ret=1;
if date='30APR1985'd then ret=1;
run;

data test2;
set _63723;
ret = .;
if date='31DEC1980'd then ret=1;
if date='30APR1985'd then ret=1;
run;

proc sort data=test1;
by permno date;
run;

proc sort data=test2;
by permno date;
run;

proc expand data=test1 out=test1_;
	id date;
	convert ret=ret_l1 / transformout=(lag 1);
	by permno;
run;

proc expand data=test2 out=test2_;
	id date;
	convert ret=ret_ld1 / transformout=(reverse lag 1 reverse);
	by permno;
run;

/*====================================*/
data _1st _2nd;
set _63723;
/*if date <= '28NOV1980'd then output _1st;*/
/*if date='28Feb1973'd then ret=.;*/
/*if date='28NOV1980'd then ret=.;*/
if date <= '31DEC1980'd then output _1st;
else output _2nd;

run;

proc sort data=_1st;
by permno date;
run;

proc sort data=_2nd;
by permno date;
run;

proc expand data=_1st out=_1st_;
	id date;
	convert ret=ret_ld1 / transformout=(reverse lag 1 reverse);
	by permno;
run;

proc expand data=_2nd out=_2nd_;
	id date;
	convert ret=ret_ld1 / transformout=(reverse lag 1 reverse);
	by permno;
run;

/*==============*/
proc sort data=_63723 out=_63723_;
by permno date;
run;

proc expand data=_63723_ out=_63723__;
	id date;
	convert ret=ret_ld1 / transformout=(reverse lag 1 reverse);
	by permno;
run;
