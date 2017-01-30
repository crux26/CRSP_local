/*Last modification: 2017.01.11*/
/*Start again from Step 2 - check variable definitions */

libname a_index "D:\Dropbox\WRDS\CRSP\sasdata\a_indexes";
libname a_stock "D:\Dropbox\WRDS\CRSP\sasdata\a_stock";
libname a_ccm "D:\Dropbox\WRDS\CRSP\sasdata\a_ccm";
libname ff "D:\Dropbox\WRDS\ff\sasdata";
libname comp "D:\Dropbox\WRDS\comp\sasdata\naa";
libname mysas "D:\Dropbox\WRDS\CRSP\mysas";
libname myMacro "D:\Dropbox\SAS_scripts\myMacro";


data mysas.dsf_copy;
set mysas.dsf;
year = year(date);
run;

proc sort data=mysas.dsf_copy;
by year;
run;

proc means data=mysas.dsf_copy noprint nway;
output out = mysas.tmp1;
run;

proc means data=mysas.dsf_copy noprint nway;
output out = mysas.tmp2;
by year;
run;

proc sort data=mysas.dsf_copy;
by permno year;
run;

proc means data=mysas.dsf_copy noprint nway;
output out = mysas.tmp3;
by permno;
run;

proc means data=mysas.dsf_copy noprint nway;
output out = mysas.tmp4;
by permno year;
run;
