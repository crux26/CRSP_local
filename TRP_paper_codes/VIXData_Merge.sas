/*SPXOpprcd_Merge -> SPXData_Merge -> SPXCallPut_Merge -> SPXData_Trim*/
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

data myVIX.FRB_tb3m;
    set frb.rates_daily;
    keep date tb_m3;
run;

proc sql;
    create table myVIX.vixData
    as select a.caldt, a.spindx, a.sprtrn, b.tb_m3, c.rate, d.vix
    from
    a_index.dsp500 as a
    left join
    myVIX.frb_tb3m as b
    on a.caldt = b.date
    left join 
    optionm.idxdvd as c
    on c.secid = 108105 and a.caldt = c.date
    left join
    vix.cboe as d
    on a.caldt = d.date;
quit;

data myVIX.vixData;
    set myVIX.vixData;
    if sprtrn =. then delete;
    rate = rate / 100;
    TB_m3 = TB_m3 / 100;
    vix = vix / 100;
    format vix 6.4;
run;

proc sql;
create table myVIX.VIXData
as select a.*, b.vix as vix_bus21
from
myVIX.VIXData as a
left join
myVIX.VIXData as b
on a.caldt = intnx('weekday',b.caldt,21);
quit;

data myVIX.VIXData;
set myVIX.VIXData;
vix_lag21 = lag21(vix);
run;

data myVIX.VIXData;
set myVIX.VIXData;
if tb_m3 =. then delete;
if vix =. then delete;
if vix_bus21 =. then delete;
if vix_lag21 =. then delete;
run;
