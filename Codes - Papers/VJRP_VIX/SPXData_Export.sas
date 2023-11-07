/*SPXOpprcd_Merge -> SPXData_Merge -> SPXCallPut_Merge -> SPXData_Trim -> SPXData_Export */
libname a_index "E:\Dropbox\WRDS\CRSP\sasdata\a_indexes";
libname a_stock "E:\Dropbox\WRDS\CRSP\sasdata\a_stock";
libname a_treas "E:\Dropbox\WRDS\CRSP\sasdata\a_treasuries";
libname ff "E:\Dropbox\WRDS\ff\sasdata";
libname frb "E:\Dropbox\WRDS\frb\sasdata";
libname mysas "E:\Dropbox\WRDS\CRSP\mysas";
libname myOption "E:\Dropbox\WRDS\CRSP\myOption";
libname myMacro "E:\Dropbox\GitHub\CRSP_local\myMacro";
libname optionm "\\Egy-labpc\WRDS\optionm\sasdata";

data spxdata;
set myoption.spxdata;
where '01JAN1995'd<=caldt<='31DEC2015'd;
drop rate spxset;
if tb_m3 =. then delete;
run;

proc export data = spxdata
outfile = "E:\Dropbox\GitHub\VJRP_VIX\myReturn_Data\rawData\SPXData.csv"
DBMS = csv REPLACE;
run;
