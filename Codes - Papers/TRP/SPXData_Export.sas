/*SPXOpprcd_Merge -> SPXData_Merge -> SPXCallPut_Merge -> SPXData_Trim -> SPXData_Export */
libname a_index "D:\Dropbox\WRDS\CRSP\sasdata\a_indexes";
libname a_stock "D:\Dropbox\WRDS\CRSP\sasdata\a_stock";
libname a_treas "D:\Dropbox\WRDS\CRSP\sasdata\a_treasuries";
libname ff "D:\Dropbox\WRDS\ff\sasdata";
libname frb "D:\Dropbox\WRDS\frb\sasdata";
libname mysas "D:\Dropbox\WRDS\CRSP\mysas";
libname myOption "D:\Dropbox\WRDS\CRSP\myOption";
libname myMacro "D:\Dropbox\GitHub\CRSP_local\myMacro";
libname optionm "\\Egy-labpc\WRDS\optionm\sasdata";

/*rate(=div), spxset contained in SPXCall, SPXPut dataset.*/
data spxdata;
set myoption.spxdata;
where '01JAN1995'd<=caldt<='31DEC2015'd;
drop rate spxset;
if tb_m3 =. then delete;
run;

proc export data = spxdata
outfile = "D:\Dropbox\GitHub\TRP\data\rawdata\SPXData.xlsx"
DBMS = xlsx REPLACE;
run;
