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

/*WARNING: tb_m3<0 happens occasionally. Even missing for some dates.*/
data myOption.FRB_tb3m;
    set frb.rates_daily;
    keep date tb_m3;
run;

proc expand data=myOption.FRB_tb3m out=tmp_FRB_tb3m;
	id date;
	convert tb_m3 / method=join;
run;

/*proc import datafile = "E:\Dropbox\GitHub\VJRP_local\Particle\myReturn_Data\SPXSET.xlsx"*/
proc import datafile = "E:\Dropbox\GitHub\TRP\data\rawdata\SPXSET.xlsx"
dbms = xlsx REPLACE out = myOption.SPXSET ;
range='Sheet1$A2:B7504'; /*Range includes column names.*/
run;

/*PX_LAST: convert from character to numeric*/
data myOption.SPXSET; set myOption.SPXSET; px_last_=input(px_last, 8.); drop px_last; rename px_last_=px_last; run;

proc sql;
    create table myOption.spxData
    as select a.caldt, a.spindx, a.sprtrn, b.tb_m3, c.rate, d.px_last as spxset
    from
    a_index.dsp500 as a
    left join
    tmp_frb_tb3m as b
    on a.caldt = b.date
    left join 
    optionm.idxdvd as c
    on c.secid = 108105 and a.caldt = c.date
    left join
    myOption.SPXSET as d
    on a.caldt = d.date;
quit;

data myOption.spxdata;
    set myOption.spxdata;
    if sprtrn =. then delete;
    if spxset =. then delete;
    if TB_M3 =. then delete;
    rate = rate / 100;
    TB_m3 = TB_m3 / 100;
run;
