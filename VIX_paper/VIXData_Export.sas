libname a_index "D:\Dropbox\WRDS\CRSP\sasdata\a_indexes";
libname a_stock "D:\Dropbox\WRDS\CRSP\sasdata\a_stock";
libname a_treas "D:\Dropbox\WRDS\CRSP\sasdata\a_treasuries";
libname ff "D:\Dropbox\WRDS\ff\sasdata";
libname frb "D:\Dropbox\WRDS\frb\sasdata";
libname mysas "D:\Dropbox\WRDS\CRSP\mysas";
libname myOption "D:\Dropbox\WRDS\CRSP\myOption";
libname myMacro "D:\Dropbox\GitHub\CRSP_local\myMacro";
libname optionm "\\Egy-labpc\WRDS\optionm\sasdata";
libname VIX "D:\Dropbox\WRDS\cboe\sasdata";
libname myVIX "D:\Dropbox\WRDS\CRSP\myVIX";

data vixdata;
set myvix.vixdata;
where '01JAN1995'd<=caldt<='31DEC2015'd;
run;

proc export data = vixdata
outfile = "D:\Dropbox\GitHub\VJRP_VIX\VIX\VIXData\rawData\VIXData.xlsx"
DBMS = xlsx REPLACE;
run;
