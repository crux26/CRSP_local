libname a_index "D:\Dropbox\WRDS\CRSP\sasdata\a_indexes";
libname a_stock "D:\Dropbox\WRDS\CRSP\sasdata\a_stock";
libname a_treas "D:\Dropbox\WRDS\CRSP\sasdata\a_treasuries";
libname ff "D:\Dropbox\WRDS\ff\sasdata";
libname frb "D:\Dropbox\WRDS\frb\sasdata";
libname mysas "D:\Dropbox\WRDS\CRSP\mysas";
libname myOption "D:\Dropbox\WRDS\CRSP\myOption";
libname myMacro "D:\Dropbox\GitHub\CRSP_local\myMacro";
libname optionm "\\Egy-labpc\WRDS\optionm\sasdata";

data spxdata;
set myoption.spxdata;
where '01JAN1995'd<=caldt<='31DEC2012'd;
drop rate spxset;
if tb_m3 =. then delete;
run;

proc export data = spxdata
outfile = "D:\Dropbox\GitHub\VJRP_local\Particle\myReturn_Data\rawData\SPXData.xlsx"
DBMS = xlsx REPLACE;
run;
