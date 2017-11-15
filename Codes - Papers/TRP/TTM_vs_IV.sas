/*%include myMacro('SetDate.sas'); WILL NOT work unless */
/*-SASINITIALFOLDER "D:\Dropbox\GitHub\CRSP_local" added to sasv9.cfg in ...\nls\en and \ko*/
libname a_index "D:\Dropbox\WRDS\CRSP\sasdata\a_indexes";
libname a_stock "D:\Dropbox\WRDS\CRSP\sasdata\a_stock";
libname a_ccm "D:\Dropbox\WRDS\CRSP\sasdata\a_ccm";
libname a_treas "D:\Dropbox\WRDS\CRSP\sasdata\a_treasuries";
libname comp "D:\Dropbox\WRDS\comp\sasdata\naa";
libname ff "D:\Dropbox\WRDS\ff\sasdata";
libname frb "D:\Dropbox\WRDS\frb\sasdata";
libname mysas "D:\Dropbox\WRDS\CRSP\mysas";
libname myMacro "D:\Dropbox\GitHub\CRSP_local\myMacro";
libname optionm "\\Egy-labpc\WRDS\optionm\sasdata";
libname myOption "D:\Dropbox\WRDS\CRSP\myOption";
libname BEM "D:\Dropbox\GitHub\CRSP_local\Bali, Engle, Murray - replications";
libname ff_repl "D:\Dropbox\WRDS\CRSP\ff_repl";
libname op_dorm "E:\opprcd2016";
libname op2016 "D:\Dropbox\GitHub\op2016";
/* To automatically point to the macros in this library within your SAS program */
options sasautos=('D:\Dropbox\GitHub\CRSP_local\myMacro\', SASAUTOS) MAUTOSOURCE;


data SPXCall; set myoption.SPXCall(drop=delta gamma vega theta ss_flag);
where secid=108105;
strike_price = strike_price / 1000;
daysdif = intck('weekday', date, exdate);
if daysdif>64 then delete;
run;


data SPXPut; set myoption.SPXPut(drop=delta gamma vega theta ss_flag);
where secid=108105;
strike_price = strike_price / 1000;
daysdif = intck('weekday', date, exdate);
if daysdif>64 then delete;
run;

proc sort data=SPXCall out=spxCall_sort; by descending daysdif strike_price; run;

proc sort data=SPXPut out=spxPut_sort; by descending daysdif strike_price; run;

proc means data=spxCall_sort noprint;
by descending daysdif strike_price; var impl_volatility volume; output out=spxCall_means mean= std= n= / autoname;
run;

proc means data=spxPut_sort noprint;
by descending daysdif strike_price; var impl_volatility volume; output out=spxPut_means mean= std= n= / autoname;
run;

/*--------------*/

proc means data=spxCall_sort noprint;
by descending daysdif; var impl_volatility volume; output out=spxCall_means_ mean= std= n= / autoname;
run;

proc means data=spxPut_sort noprint;
by descending daysdif; var impl_volatility volume; output out=spxPut_means_ mean= std= n= / autoname;
run;



/**/
proc export data = spxCall_means
outfile = "D:\Dropbox\GitHub\TRP\op2016\SPXCall_means.xlsx"
DBMS = xlsx REPLACE;
run;

proc export data = spxCall_means_
outfile = "D:\Dropbox\GitHub\TRP\op2016\SPXCall_means_.xlsx"
DBMS = xlsx REPLACE;
run;


proc export data = spxPut_means
outfile = "D:\Dropbox\GitHub\TRP\op2016\SPXPut_means.xlsx"
DBMS = xlsx REPLACE;
run;

proc export data = spxPut_means_
outfile = "D:\Dropbox\GitHub\TRP\op2016\SPXPut_means_.xlsx"
DBMS = xlsx REPLACE;
run;
