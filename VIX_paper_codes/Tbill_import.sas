/*tbill3M_ts and tbill3M are essentially the same*/
/*tfz_mth_ts or tfz_dly_ts2 are merged dataset of various interest rates*/

libname a_index "D:\Dropbox\WRDS\CRSP\sasdata\a_indexes";
libname a_stock "D:\Dropbox\WRDS\CRSP\sasdata\a_stock";
libname a_treas "D:\Dropbox\WRDS\CRSP\sasdata\a_treasuries";
libname ff "D:\Dropbox\WRDS\ff\sasdata";
libname mysas "D:\Dropbox\WRDS\CRSP\mysas";
libname myMacro "D:\Dropbox\GitHub\CRSP_local\myMacro";
libname optionm "\\Egy-labpc\WRDS\optionm\sasdata";

%let head = optionm.Opprcd;

data mysas.Tbill4W;
set a_treas.Tfz_dly_rf2;
where kytreasnox = 2000061;
run;

data mysas.Tbill13W;
set a_treas.Tfz_dly_rf2;
where kytreasnox = 2000062;
run;

data mysas.Tbill1M;
set a_treas.Tfz_mth_rf;
where kytreasnox = 2000001;
run;

data mysas.Tbill3M;
set a_treas.Tfz_mth_rf;
where kytreasnox = 2000002;
run;

data mysas.Tbill3M_ts;
set a_treas.tfz_dly_ts2;
where kytreasnox = 2000076;
keep kytreasnox caldt tdyld tdduratn;
run;
