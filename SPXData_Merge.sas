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

data myOption.FRB_tb3m;
	set frb.rates_daily;
	keep date tb_m3;
run;

proc import datafile = "D:\Dropbox\GitHub\VJRP_local\Particle\myReturn_Data\SPXSET.xlsx"
dbms = xlsx REPLACE out = myOption.SPXSET ;
range='Sheet1$A2:B6525';
run;

proc sql;
	create table myOption.spxData
	as select a.caldt, a.spindx, a.sprtrn, b.tb_m3, c.rate, d.px_last as spxset
	from
	a_index.dsp500 as a
	left join
	myOption.frb_tb3m as b
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
	rate = rate / 100;
	TB_m3 = TB_m3 / 100;
run;
