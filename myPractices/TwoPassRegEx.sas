/*NOTE THAT THIS IS NOT FAMA-MACBETH REGRESSION*/
/*STANDARD ERROR NOT ADJUSTED*/

/*SHOULD ADD IDENTIFIER FOR EACH PORTFOLIO RETURN*/
/*AND THEN RUN REGRESSION "BY IDENTIFIER".*/
/*IF NOT, THE CALCULATION TIME WILL TAKE PAINFULLY LONG - */
/*A LOT LONGER THAN ONE CAN IMAGINE*/
libname a_index "D:\Dropbox\WRDS\CRSP\sasdata\a_indexes";
libname a_stock "D:\Dropbox\WRDS\CRSP\sasdata\a_stock";
libname a_treas "D:\Dropbox\WRDS\CRSP\sasdata\a_treasuries";
libname ff "D:\Dropbox\WRDS\ff\sasdata";
libname frb "D:\Dropbox\WRDS\frb\sasdata";
libname mysas "D:\Dropbox\WRDS\CRSP\mysas";
libname myMacro "D:\Dropbox\GitHub\CRSP_local\myMacro";
libname optionm "\\Egy-labpc\WRDS\optionm\sasdata";

/*proc sql;*/
/*create table ff_mrgd*/
/*as select a.*, b.**/
/*from ff.portfolios25 as a, ff.factors_monthly as b*/
/*where*/
/*a.date = b.dateff;*/
/*run;*/

data ff_PF25; set ff.portfolios25;
	keep s1b1_vwret -- s5b5_vwret date;
	if date=. then delete;
run;

proc transpose data=ff_PF25 out=_trsp(drop=_label_ rename=(col1=RET));
by date;
run;

proc sort data=_trsp;
by _name_ date;
run;

data _trsp; set _trsp;
	by _name_;
	rename _name_=var;
	retain id 0;
	if first._NAME_ then id=id+1;
run;

proc sql;
create table have0
as select a.*, b.mktrf, b.smb, b.hml, b.umd, b.rf
from _trsp as a, ff.factors_monthly as b
where
a.date = b.dateff;
run;

data have0; set have0;
if umd=. then delete;
ret = ret - rf;
rename ret=exret;
run;

proc sort data=have0;
by id date;
run;

/*FIRST-PASS TIME-SERIES REGRESSION*/
/*INDVARS: MKTRF SMB HML UMD*/
proc reg data=have0 outest=_result edf noprint;
model exret = mktrf smb hml umd;
by id;
run;

/*Calculating (LHS) for second-pass regression*/
/*For Fama-MacBeth, proc means should not be done*/
proc means data=have0 noprint nway;
output out=_tmp_avg;
by id;
run;

/*Retain mean(exret) only*/
data _tmp_avg; set _tmp_avg;
if _STAT_ = 'MEAN' ;
keep id exret;
run;

/*Merge betas and mean(exret) */
proc sql;
create table have1
as select a.id, b.exret, a.mktrf, a.smb, a.hml, a.umd /*b.* are betas*/
from 
_result as a,
_tmp_avg as b
where
a.id = b.id;
run;

/*null_id for by variable for second-pass regression*/
data have1; set have1;
null_id = 1;
run;

proc reg data=have1 outest=_final edf noprint;
model exret = mktrf smb hml umd;
by null_id;
run;
