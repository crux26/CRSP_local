libname a_stock "D:\Dropbox\WRDS\CRSP\sasdata\a_stock\";
libname a_index "D:\Dropbox\WRDS\CRSP\sasdata\a_indexes\";
libname mysas "D:\Dropbox\WRDS\CRSP\mysas\";

/*proc print data = a_index.asia;*/
/*run;*/

data mysas.a_index_asia;
set a_index.asia;	* copying real data "a_index.asia" to my data "a_index_asia" is much safer, instead of using it directly;
run;

proc reg
outest = mysas.reg_result tableout;
model vwretd = decind1;
model vwretd = decind3;
model vwretd = decind1 decind2;
model vwretd = decind1 decind3;
model vwretd = decind2 decind3;
model vwretd = decind1 decind2 decind3;
run;

/*proc print ;*/
/*run;*/

/*  deleting statistics not necessarily needed;  */
data mysas.reg_result_t;
set mysas.reg_result;
if _TYPE_ = 'STDERR' then delete;
if _TYPE_ = 'PVALUE' then delete;
if _TYPE_ = 'L95B' then delete;
if _TYPE_ = 'U95B' then delete;
run;
/*proc print; run;*/

/*  reordering variables  */
data mysas.reg_result_t_reorder;
retain _MODEL_ _TYPE_ _DEPVAR_ _RMSE_ Intercept vwretd decind1-decind3;  * <-- same as decind1 decind2 decind3;
	set mysas.reg_result_t;
run;

/*  sum of variables appears at the bottom  */
/*proc print;*/
/*sum decind3;*/
/*run;*/

data mysas.reg_result_t_reorder2;
set mysas.reg_result_t_reorder;
if _TYPE_ = 'T' then delete;
drop _TYPE_;
drop _DEPVAR_;
drop _RMSE_;
drop vwretd;
run;

/*proc print; run;*/

proc transpose data=mysas.reg_result_t_reorder2
out = tmp1
prefix = model;
/*var _MODEL_ _TYPE_ _DEPVAR_ _RMSE_ Intercept vwretd decind1-decind3;*/
run;

/*proc print; run;*/

data tmp1;
set tmp1;
drop _label_;
if _name_ = 'vwretd' then delete;

proc print; run;

quit;

/*PROC EXPORT DATA= MYSAS.REG_RESULT */
/*            OUTFILE= "C:\Users\EG.Y\Desktop\reg_result.xls" */
/*            DBMS=EXCEL REPLACE;*/
/*     SHEET="reg_result"; */
/*RUN;*/
/**/
/*quit;*/
