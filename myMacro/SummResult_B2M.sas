%macro SummResult_B2M(data=, out=, var=, by=);

proc means data=&data noprint nway;
output out=tmp1(drop=_TYPE_ _FREQ_)
mean= std= skew= kurt= 
min= p5= p25= median= p75= p95= max= n= /autoname;
var &var;
by &by;
run;

proc transpose data=tmp1 out=tmp2;
id &by;
run;

data tmp3;
set tmp2;
varname = catx("_", scan(_name_, 1, '_'), scan(_name_, 2, '_'), scan(_name_, 3, '_') );
_stat_=scan(_name_,4,'_');
drop _name_ _label_;
run;

proc sort data=tmp3;
by _stat_;
run;

proc transpose data=tmp3 out=tmp4;
by _stat_;
id varname;
run;

data &out; set tmp4;
_name_ = tranwrd(_name_, "_","");
year = input(_name_, 8.);
drop _name_;
run;

proc sort data = &out;
by year;
run;

proc datasets lib=work nolist;
	delete tmp: ;
quit;
run;

%mend SummResult_B2M;
