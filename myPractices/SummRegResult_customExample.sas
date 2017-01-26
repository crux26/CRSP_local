/*------------------*/
/*------------------*/

proc means data=mysas.beta noprint nway;
output out=mysas.PrdcStat2(drop=_TYPE_ _FREQ_) 
mean= std= skew= kurt=
min= p5= p25= median= p75= p95= max= n= /autoname;
var intercept vwretd;
by year;
run;

/*------------------*/

proc transpose data=mysas.PrdcStat2 out=mysas.temp;
id year;
run;

data mysas.temp1;
set mysas.temp;
varname=scan(_name_,1,'_');
stat=scan(_name_,2,'_');
drop _name_ _label_;
run;

proc sort data=mysas.temp1;
by stat;
run;

proc transpose data=mysas.temp1 out=mysas.temp3; /*(drop=_name_)*/
by stat ;
id varname;
run;

data mysas.temp4; set mysas.temp3;
_name_ = tranwrd(_name_, "_", "");
year = input(_name_, 8.);
drop _name_;
run;

proc means data=mysas.beta noprint nway;
output out=mysas.PrdcStat(drop=_TYPE_ _FREQ_)  ;
var intercept vwretd;
by year;
run;
