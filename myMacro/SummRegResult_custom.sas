/*BY: order should be year, month, date.*/
/*This is because in PROC TRANSPOSE, date's format is YYYYMMDD and reads this from left to right. */
%macro SummRegResult_custom(data=, out=, var=, by=);
%let lib_data = %sysfunc(scan(&data, 1, '.'));

proc means data=&data noprint nway;
output out=tmp1(drop=_TYPE_ _FREQ_)
mean= std= skew= kurt= 
min= p5= p25= median= p75= p95= max= n= /autoname;
var &var;
by &by;
run;

data tmp1; set tmp1;
if findw('&by', month, 'i') >1 & month<=9 then	month = cats(0,month);
/*'i': ignores character case. */
if findw('&by', day, 'i') > 1 & day<=9 then day = cats(0,day);
/*If month, day haven't existed, then month, day are missing. */
format month z2.; 
format day z2.;
/*format z2. : retains leading 0 in front of 1-digit months*/
run;

data _null_;
set tmp1;
if month=. then call symputx('drop1','month');
else call symputx('drop1','') ;
if day=. then call symputx('drop2', 'day');
else call symputx('drop2','') ;
run;

data tmp1;
set tmp1;
drop &drop1 &drop2;
run;
/*Drop missing variables month, day if it is NOT in &by. */

/**/
proc transpose data=tmp1 out=tmp2;
id &by;
run;

data tmp3;
set tmp2;
varname = scan(_name_,1,'_');
_stat_=scan(_name_,2,'_');
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
_name_ = tranwrd(_name_, '_', '');
/*year = input(_name_, 8.);*/
year = substr(_name_, 1, 5);
month = substr(_name_, 6, 2);
day = substr(_name_,8,2);
drop _name_;
year2= input(year, 8.); month2 = input(month, 8.); day2 = input(day, 8.);
/*year=intput(year, 8.) NOT working.*/
drop year month day;
rename year2=year month2=month day2=day;
run;

data _null_;
set &out;
if month=. then call symputx('drop1','month');
if day=. then call symputx('drop2', 'day');
run;

data &out.2;
set &out;
drop &drop1 &drop2;
run;

proc datasets lib=&lib_data nolist;
delete %sysfunc(scan(&out, -1, '.')) ;
quit;
run;

proc datasets lib=&lib_data nolist;
change %sysfunc(scan(&out.2,-1,'.')) = %sysfunc(scan(&out,-1,'.')) ;
quit;
run;

proc sort data = &out;
/*by year;*/
by &by;
run;

proc datasets lib=work nolist;
delete tmp: ;
quit;
run;

%mend SummRegResult_custom;

