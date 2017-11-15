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

proc sql;
create table dateSeries_Wed as
select distinct date from
/*OpFull.Spxcall_dly*/
myOption.SpxCall_mnth
where date=intnx('week',date,0)+3;
quit;

proc sql;
create table vixdata as
select a.* from
myvix.vixdata as a,
dateSeries_Wed as b
where a.caldt=b.date and ~missing(a.tb_m3);
quit;

proc export data = vixdata
outfile = "D:\Dropbox\GitHub\TRP\data\rawdata\VIXData.xlsx"
DBMS = xlsx REPLACE;
run;
