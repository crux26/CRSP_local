data dusty;
input dept $ name $ salary @@;
datalines;
bedding Watlee 18000 bedding Ives 16000
bedding Parker 9000 bedding George 8000
bedding Joiner 8000 carpet Keller 20000
carpet Ray 12000 carpet Jones 9000
gifts Johnston 8000 gifts Matthew 19000
kitchen White 8000 kitchen Banks 14000
kitchen Marks 9000 kitchen Cannon 15000
tv Jones 9000 tv Smith 8000
tv Rogers 15000 tv Morse 16000
;
proc means noprint;
class dept;
var salary;
output out=stats sum=s_sal;
run;

proc print data=stats;
var dept s_sal;
title "Summary of Salary Information";
title2 "For Dusty Department Store";
run;

%put _user_;

/*Below generates a series of macro variable names by combining*/
/*the character string "S" and values contained in "DEPT" variable in dataset "stats"*/

data _null_;
set stats;
if _n_=1 then call symput('s_tot',s_sal);
else call symput('s'||dept,s_sal);
run;

%put _user_;

data new;
set dusty;
pctdept=(salary/symget('s'||dept))*100;
pcttot=(salary/&s_tot)*100;
run;

proc print data=new split="*";
label dept ="Department"
name ="Employee"
pctdept="Percent of *Department* Salary"
pcttot ="Percent of * Store * Salary";
format pctdept pcttot 4.1;
title "Salary Profiles for Employees";
title2 "of Dusty Department Store";
run;
