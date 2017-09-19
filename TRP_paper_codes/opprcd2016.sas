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

data SPX16; set optionm.opprcd2016(drop=delta gamma vega theta cfadj ss_flag root suffix);
where secid=108105;
strike_price = strike_price / 1000;
daysdif = intck('weekday', date, exdate);
if daysdif>64 then delete;
run;


/*data SPX16; set op_dorm.opprcd2016(drop=delta gamma vega theta cfadj ss_flag root suffix);*/
/*where secid=108105;*/
/*strike_price = strike_price / 1000;*/
/*daysdif = intck('weekday', date, exdate);*/
/*if daysdif>64 then delete;*/
/*run;*/

proc sort data=SPX16 out=spx16_sort; by descending daysdif strike_price; run;

proc means data=spx16_sort noprint;
by descending daysdif strike_price; var impl_volatility volume; output out=spx16_means mean= std= n= / autoname;
run;

proc means data=spx16_sort noprint;
by descending daysdif; var impl_volatility volume; output out=spx16_means_ mean= std= n= / autoname;
run;

proc export data = spx16_means
outfile = "D:\Dropbox\GitHub\TRP\op2016\spx16_means.xlsx"
DBMS = xlsx REPLACE;
run;

proc export data = spx16_means_
outfile = "D:\Dropbox\GitHub\TRP\op2016\spx16_means_.xlsx"
DBMS = xlsx REPLACE;
run;



data op2016.spx16; set spx16; run;
data op2016.spx16_sort; set spx16_sort; run;
data op2016.spx16_means; set spx16_means; run;
data op2016.spx16_means_; set spx16_means_; run;
