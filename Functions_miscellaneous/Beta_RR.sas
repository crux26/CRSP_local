/*Beta, rolling regression, 1963-2016, daily ret, monthly regression.*/

libname a_index "D:\Dropbox\WRDS\CRSP\sasdata\a_indexes";
libname a_stock "D:\Dropbox\WRDS\CRSP\sasdata\a_stock";
libname a_ccm "D:\Dropbox\WRDS\CRSP\sasdata\a_ccm";
libname a_treas "D:\Dropbox\WRDS\CRSP\sasdata\a_treasuries";
libname comp "D:\Dropbox\WRDS\comp\sasdata\naa";
libname ff "D:\Dropbox\WRDS\ff\sasdata";
libname frb "D:\Dropbox\WRDS\frb\sasdata";
libname mysas "D:\Dropbox\WRDS\CRSP\mysas";
libname myMacro "D:\Dropbox\GitHub\CRSP_local\myMacro";
libname optionm "\\Egy-labpc\WRDS\optionm\sasdata";
libname myOption "D:\Dropbox\WRDS\CRSP\myOption";
libname BEM "D:\Dropbox\GitHub\CRSP_local\Bali, Engle, Murray - replications";
libname ff_repl "D:\Dropbox\WRDS\CRSP\ff_repl";

/* To automatically point to the macros in this library within your SAS program */
options sasautos=('D:\Dropbox\GitHub\CRSP_local\myMacro\', SASAUTOS) MAUTOSOURCE;


/*%RRLOOP()*/
proc format;
picture myfmt low-high = '%Y%0m%0d_%0H%0M%0S' (datatype=datetime);
run;
%put timestamp=%sysfunc(datetime(), myfmt.);

/*crsp_dsix_smaller2: Generated through CRSPMERGE() with dsix and FactorLoadingStatsDaily.*/
%RRLOOP(data= crsp_dsix_smaller2,
			out_ds= betad_crspmrgd_1M,
			model_equation=ret=mktrf ,
			id=permno , date=date ,
			start_date='01jan1963'd , 
			end_date='31dec2016'd , 
			freq=month, step=1, n=1,
			regprint=noprint, minwin=15
				);
%put timestamp=%sysfunc(datetime(), myfmt.);

data mysas.betad_crsp_dsix_1M; set betad_crspmrgd_1M; run;


/*----------------------------------------------------------------------------------------------------*/
/*----------------------------------------------------------------------------------------------------*/
/*The following is the copy&pasted part for the above to generate crsp_dsix_smaller2.*/
/*----------------------------------------------------------------------------------------------------*/
/*----------------------------------------------------------------------------------------------------*/

%let begdate = '01JAN1963'd;
%let enddate = '31DEC2016'd;
%let vars = ticker comnam prc vol ret shrout shrflg;
%let mkt_index = vwretd;
%let begyear = year(&begdate);
%let endyear = year(&enddate);

%let WINDOW = 252;
%let MINWIN = 200;

%include myMacro('SetDate.sas');
%SetDate(data=dsf, set=a_stock.dsf, date=date, begdate=&begdate, enddate=&enddate);
%SetDate(data=dsix, set=a_index.dsix, date=caldt, begdate=&begdate, enddate=&enddate);

%CRSPMERGE (s=d,START=01JAN1963,END=31DEC2016,SFVARS=vol prc ret shrout, SEVARS=ticker cusip ncusip permco permno exchcd shrcd siccd dlret,FILTERS=,OUTSET=crsp_&s.);


proc sql;
	create table crsp_dsix_common
	as
	select a.*, b.shrcd
	from
	crsp_dsix as a, a_stock.stocknames as b
	where a.permno = b.permno &
	(b.shrcd = 10 or b.shrcd = 11) &
	b.namedt <= a.date <= b.nameenddt;
quit;

proc sql;
create table crsp_dsix_mrgd
as 
select a.*, b.vwretd as vwretd, b.ewretd as ewretd,
	c.mktrf as mktrf, c.smb as smb, c.hml as hml, c.umd as umd, c.rf as rf,
	(abs(a.ret)>=0) as count 
from
	crsp_dsix_common as a
left join
	dsix as b
on a.date = b.date
left join
	ff.factors_daily as c
on a.date = c.date
order by permno, date;
quit;

data crsp_dsix_smaller; 
set crsp_dsix_mrgd(keep=permno date vol prc ret vwretd ewretd mktrf smb hml umd rf);
year = year(date);
month = month(date);
day = day(date);
prc = abs(prc);

vwexretd = vwretd - rf;
ewexretd = ewretd - rf;
exret = ret - rf;

  if exret = . then delete;
  if vwexretd =. then delete;
  if ewexretd =. then delete;
  label vwexretd = "Value-Weighted Excess Return-incl. dividends";
  label ewexretd = "Equal-Weighted Excess Return-incl. dividends";
  label exret = "Excess Return";
run;

proc sort data=crsp_dsix_smaller;
	by permno date;
run;

data crsp_dsix_smaller2 /view=crsp_dsix_smaller2; set crsp_dsix_smaller;
ObsNum+1;
by permno year;
if first.year then ObsNum=1;
run;

proc sql;
create table crsp_dsix_smaller3 as
select *, max(ObsNum) as max_obs
from crsp_dsix_smaller2
group by permno, year
order by permno, date;
quit;

/*should specify memtype=view to delete view table*/
proc datasets lib=work memtype=view nolist;
  delete crsp_dsix_smaller2;
run;
quit;

proc datasets lib=work nolist;
  change crsp_dsix_smaller3 = crsp_dsix_smaller2;
run;
quit;

data mysas.crsp_dsix_smaller2; set crsp_dsix_smaller2; run;
