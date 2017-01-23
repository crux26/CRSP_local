libname myMacro "D:\Dropbox\SAS_scripts\myMacro";

data first; set mysas.first (keep=permno date vol unsquared_ret);
	rename unsquared_ret = ret;
	squared_ret = unsquared_ret**2;
	pkey = _n_;
run;

proc sort data=first;
	by date permno;
run;

%include myMacro('XSCorr.sas');
%XSCorr(data=first, outP=outp, outS=_NULL_ , print=, var=vol ret, Date=Date);

data outp; set outp;
pkey = _n_;
run;

proc sort data=outp out=CorrSort;
by _type_ _name_ date;
run;

data CorrOnly; set CorrSort;
if _type_  ^= "CORR" then delete;
run;

proc sql;
create table CorrOnly_N
as 
select a.*, b.vol as NVol, b.ret as Nret
from 
	CorrOnly as a
left join
	CorrSort as b
on 	a.date = b.date &
		b._type_ = "N" ;
quit;


proc means data=CorrOnly_N noprint nway;
	var vol ret;
	output out=TSAvg(drop=_TYPE_ _FREQ_)
	mean(vol ret)= ;
	where NVol >1 & Nret > 1 ;
run;
