/*Checking Done! (2017.06.09)*/
/* Only the result is stored in "mysas" library, as "mysas.dgtw_returns". */
/* Not macro, in fact*/

/* ********************************************************************************* */
/* ************** W R D S   R E S E A R C H   A P P L I C A T I O N S ************** */
/* ********************************************************************************* */
/* Program	: DGTW.sas																		*/
/* Summary   : Construct Daniel Grinblatt Titman and Wermers(1997) Benchmarks        */
/* Date      : January, 2011                                                         */
/* Author    : Rabih Moussawi and Gjergji Cici                                       */
/* Variables : - BEGDATE: Sample Start Date                                          */
/*             - ENDDATE: Sample End Date                                            */
/* ********************************************************************************* */

libname a_index "D:\Dropbox\WRDS\CRSP\sasdata\a_indexes";
libname a_stock "D:\Dropbox\WRDS\CRSP\sasdata\a_stock";
libname a_ccm "D:\Dropbox\WRDS\CRSP\sasdata\a_ccm";
libname ff "D:\Dropbox\WRDS\ff\sasdata";
libname comp "D:\Dropbox\WRDS\comp\sasdata\naa";
libname mysas "D:\Dropbox\WRDS\CRSP\mysas";
libname myMacro "D:\Dropbox\SAS_scripts\myMacro";

%include myMacro('FFI5.sas');
%include myMacro('FFI10.sas');
%include myMacro('FFI12.sas');
%include myMacro('FFI17.sas');
%include myMacro('FFI30.sas');
%include myMacro('FFI38.sas');
%include myMacro('FFI48.sas');
%include myMacro('FFI49.sas');

 
/* Step 1. Specifying Options */
%let begdate = 01JAN1962;
/*%let enddate = &sysdate9.; *&sysdate: "TODAY";*/
%let enddate = 31DEC2015;  

/* Create a CRSP Subsample with Monthly Stock and Event Variables */
/* Restriction on the type of shares (common stocks only: shrcd in (10,11)) */
%let sfilter = (shrcd in (10,11));
/*SHRCD, first digit=1: Ordinary common shares */
/*SHRCD, second digit=0: Securities which have not been further defined. */
/*SHRCD, second digit=1: Securities which need not be further defined. */

/* Selected variables from the CRSP monthly data file (crsp.msf file) */
%let msfvars = permco prc ret vol shrout cfacpr cfacshr;
%let msevars = ncusip exchcd shrcd siccd ;
/* Procedure below creates a Monthly CRSP dataset named "CRSP_M"  */
%include mymacro('crspmerge.sas');
%crspmerge(s=m,start=&begdate,end=&enddate,sfvars=&msfvars,sevars=&msevars,filters=&sfilter, outset=crsp_&s.);
 
/* Adjust Share and Price in Monthly Data */
data crsp_m;
set crsp_m;
DATE = INTNX("MONTH",date,0,"E"); *set date to month's last day;
/*Returns are already adjusted for splits and other corporate actions, but prices and shrout are not.*/
P = abs(prc)/cfacpr;
/*CFACPR: Cumulative Factor to Adjust Prices*/
TSO=shrout*cfacshr*1000;
/*SHROUT: quoted in unit of thousands, so multiply by 1000 to make the unit to be unity */
/* CFACSHR: Cumulative Factor to Adjust Shares/Vol */
/*Note that CFACSHR is NOT always equal to CFACPR.*/
if TSO<=0 then TSO=.;
ME = P*TSO/1000000;
/*ME: quoted in unit of dollar, so divide it by 1m to make the unit to be in million dollars */
label P = "Price at Period End, Adjusted";
label TSO = "Total Shares Outstanding, Adjusted";
label ME = "Issue-Level Market Capitalization, unit of $1m";
drop ncusip prc cfacpr shrout shrcd;
format ret percentn8.4 ME P dollar12.3 TSO comma12.;
run;
 
/* Create Total Market Capitalization at the Company Level */
proc sql  undo_policy=none;
/*UNDO_POLICY=NONE: does not undo any updates or inserts*/
/*While one's updating or inserting rows in a table, one might receive an error message that the update*/
/*or insert cannot be performed. By using UNDO_POLICY= option, one can control whether*/
/*the changes that have already been made will be permanent*/
create table crsp_m
as select *, sum(me) as me_comp "Company-Level Market Cap, $million" format dollar12.3
from crsp_m
group by permco, date
order by permno, date;
/*Each observation is unique in its (permco, date) pair --> sum(ME) actually same as just ME only */
quit;
 
/* Get Book Value of Equity from Compustat to Create B/P Rankings */
data comp1;
set comp.funda (keep=gvkey datadate cusip indfmt datafmt consol popsrc
    SICH SEQ PSTKRV PSTKL PSTK TXDB ITCB);
where indfmt='INDL' and datafmt='STD' and consol='C' and popsrc='D'
  and datadate>="&begdate"d;
  if SEQ>0;                         /* Shareholders' Equity */
  PREF=PSTKRV;                      /* Preferred stock : Redemption Value */
  if missing(pref) then PREF=PSTKL; /* Preferred stock : Liquidating Value */
  if missing(pref) then PREF=PSTK;  /* Preferred stock : Carrying Value, Stock (Capital) - Total */
  BE = sum(SEQ, TXDB, ITCB, -PREF); /* Deferred taxes and Investment Tax Credit */
/* sum(4, 9, . ) = 13 (NOT ".") */
/* On the other hand, 4+9+. = "." */
  label BE = "Book Value of Equity";
  if BE>=0;
  /* Daniel and Titman (JF 1997):                                                   */
  /* BE = stockholders' equity + deferred taxes + investment tax credit - Preferred Stock */
/*That is, BE = SEQ + TXDB + ITCB - PREF */
 label datadate = "Fiscal Year End Date";
 keep gvkey sich datadate BE;
run;
 
/* Add Historical PERMCO identifier */
proc sql;
  create table comp2
  as select a.*, b.lpermco as permco, b.linkprim
/*LINKPRIM: Primary issue marker for the link. P, J, C, N.*/
  from comp1 as a, a_ccm.ccmxpf_linktable as b
  where a.gvkey = b.gvkey and
  b.LINKTYPE in ("LU","LC") and
/* LC: Link research complete. Standard connection between databases */
/* LU: Unresearched link to issue by CUSIP */
/*LINKTYPE: LC, LU, LX, LD, LN, LS, NR, NU*/
 (b.LINKDT <= a.datadate) and (a.datadate <= b.LINKENDDT or missing(b.LINKENDDT));
/*LINKDT: first effective date of the current link*/
/*LINKENDDT: last effective date of the current link record. If the name represents the current link info.,*/
/*the LINKENDDT is set to 99,999,999*/
quit;
 
/* Sorting into Buckets is done in July of Each Year t               */
/* Additional Requirements:                                          */
/* - Compustat data is available for at least 2 years                */
/* - CRSP data available on FYE (Fiscal Year End) of year t-1 and June of year t       */
/* - at least 6 months of returns in CRSP between t-1 and t          */
/* - size weights are constructed using the market value in June     */
/* - B/M Ratio uses the market cap at FYE of the year t-1            */
/* - Momentum factor is the 12 month return with 1 month reversal    */
 
/* Construct Book to Market Ratio Each Fiscal Year End               */
proc sql;
  create table comp3
  as select distinct b.permno, a.gvkey, year(a.datadate) as YEAR, a.datadate, a.linkprim,
  a.BE, b.me, a.sich, b.siccd, a.be/b.me_comp as BM "Book-to-Market Ratio" format comma8.2
/*SICCD: Standard Industrial Classification Code */
/*SICH: Standard Industrial Classification - Historical */
  from comp2 as a, crsp_m as b
  where a.permco=b.permco and datadate=intnx("month",date,0,"E")
/*datadate: month-end day of date*/
order by permno,datadate;
quit;
 
/* Use linkprim='P' for selecting just one permno-gvkey combination   */
/* Also, if a company changes its FYE month, choose the last report   */

/*LINKPRIM='P': Primary, identified by COMPUSTAT in monthly security data */
proc sort data=comp3 nodupkey; by permno year datadate linkprim bm; run;

data comp3;
set comp3;
by permno year datadate;
if last.year;
drop linkprim;
run;

/*START AGAIN FROM HERE*/

/* Industry-Adjust the B/M Ratios using F&F(1997) 48-Industries */
data comp4;
	set comp3;
	/* First, use historical Compustat SIC Code */
	if sich>0 then SIC=sich;
	/* SICH: from COMPUSTAT */
	/* Then, if missing, use historical CRSP SIC Code */
	else if siccd>0 then sic=siccd;
	/* SICCD: from CRSP */
	/* and adjust some SIC code to fit F&F 48 ind delineation (=description) */
	if SIC in (3990,9995,9997) and siccd>0 and siccd ne SIC then SIC = siccd;
	/* siccd>0: to check siccd is not null */
	if SIC in (3990,3999) then SIC = 3991;
	/* SIC in (2000-3999): Manufacturing */
	/* SIC = 3990: Miscellaneous Manufacturing Industries*/
	/* SIC = 3999: Manufacturing Industries, Not Elsewhere Classified*/
	/* SIC = 3991: Brooms and Brushes */
	/* SIC in (9900-9999): Nonclassifiable Establishments */
	/* SIC = 9995: Non-Operating Establishments */
	/* SIC = 9997: Conglomerates (GV only) */

	/* F&F 48 Industry Classification Macro */
	%FFI48(sic);
/* Classify companies into 48 classifications */
	if missing (FFI48) or missing(BM) then delete;
	drop sich siccd datadate;
run;
 
 /* Calculate BM Industry Average Each Period */
proc sort data=comp4; by FFI48 year; run;

proc means data = comp4 noprint;
where FFI48>0 and bm>=0;
  by FFI48 year;
  var bm;
  output out = BM_IND (drop=_Type_ _freq_)  mean=bmind;
run;
 
/* Calculate Long-Term Industry B2M Average */
data BM_IND;
	set BM_IND;
	by FFI48 year;
	retain avg n;
	if first.FFI48 then do;
	  avg=bmind;
	  n=1;
	  bmavg=avg;
	end;
	else do;
		bmavg=((avg*n)+bmind)/(n+1);
		n+1;
		avg=bmavg;
	end;
format bmavg comma8.2;
/* bmavg: cumulative average from the first.year to last.year w/i each FFI48 classification */
/* NOT moving average, but average over the whole series */
drop avg n bmind;
run;
 
/* Adjust Firm-Specific BtM with Industry Averages */
proc sql;
create table comp5
as select a.*, (a.bm-b.bmavg) as BM_ADJ "Adjusted Book-to-Market Ratio"
 format comma8.2
from comp4 as a, BM_IND as b
where a.year=b.year and a.FFI48=b.FFI48;
quit;
 
proc printto log=junk; run;
/* Create (12,1) Momentum Factor with at least 6 months of returns */
proc expand data=crsp_m (keep=permno date ret me exchcd) out=sizmom method=none;
by permno;
id date;
convert ret = cret_12m / transformin=(+1) transformout=(MOVPROD 12 -1 trimleft 6);
/*TRANSFORMIN=(+1): convert from net return into gross return*/
/*MOVPROD 12 -1: After taking the moving product w/ window size 12, subtract 1 to make it net return again*/
/* TRIMLEFT 6: Deem the first 6 observations as null */
/* That is, calculate momentum return w/ at least 6 months of returns, w/ the window length of 12 */
quit;
proc printto; run;
 
/* Keep Momentum Factor and Size at the End of June - which is the formation date */
data sizmom;
set sizmom;
by permno date;
/* First, add the one month reversal gap ( by lag() ) */
MOM=lag(cret_12m);
/* lag(): lag 1. lag(Jan-Mar): write at Apr */
if first.permno then MOM=.;
/* Then, keep Momentum Factor at the End of June */
if month(date)=6; * <-- why keep June only? ;
label MOM="12-Month Momentum Factor with one month reversal";
label date="Formation Date"; format MOM RET percentn8.2;
drop cret_12m; rename me=SIZE;
run;
 
/* Get Size Breakpoints for NYSE firms */
proc sort data=sizmom nodupkey; by date permno; run;
 
proc univariate data=sizmom noprint;
where exchcd=1;
/* EXCHCD=1: NYSE, =2: NYSE MKT, =3: NASDAQ, =4: Arca, ..., =13: Chicago Stock Exchange, */
/* =20: Over-the-Counter (Non-NASDAQ Dealer Quotations)*/
by date;
var size;
output out=NYSE pctlpts = 20 to 80 by 20 pctlpre=dec;
/* Above are breakpoints for given percentile set */
run;
/* -->Why not just use PROC RANK instead of PROC UNIVARIATE? */
/* --> If most of the firms are concentrated at small size, then PROC RANK will result in*/
/* distorted breakpoints (Will yield equal number of firms in each rank, by the way). */

/* Thus, by using breakpoints whose values are 20, 40, 60, 80 percentiles of */
/* the whole SIZE distribution, it will be highly likely that group=1,2 will contain far more firms than */
/* group=5 does. */
 
/* Add NYSE Size Breakpoints to the Data*/
data sizmom;
merge sizmom NYSE;
by date;
if size>0 and size < dec20 then group = 1;
else if size >= dec20 and size < dec40 then group =2;
else if size >= dec40 and size < dec60 then group =3;
else if size >= dec60 and size < dec80 then group =4;
else if size >= dec80                  then group =5;
drop dec20 dec40 dec60 dec80;
label group = "Size Portfolio Group";
/* Aboves are size quintiles */
run;

/* Adjusted B2M from the calendar year preceding the formation date */
proc sql;
  create table comp6
  as select distinct a.permno, a.gvkey, b.date, b.group, b.size, b.mom, a.year, a.bm_adj
  from comp5 as a, sizmom as b
  where a.permno=b.permno and year(b.date)=a.year+1
/* SIZE, MOM from today's data (from "sizmom"). YEAR, BM_ADJ is last year's June (from "comp5") */
/* Hence, "YEAR" corresponds to fiscal year end, which is last year's June at the latest */
   and not missing(size+mom+bm_adj+ret);
/*Above makes sure that nothing's missing. If anything is missing, then above "+" will yield missing. */
/*On the other hand, sum (A,B,C) will exclude missing and take the sum. */
quit;
 
/* Start the Triple Sort on Size, Book-to-Market, and Momentum */
proc sort data=comp6 out=port1 nodupkey; by date group permno; run;
/*NODUPKEY: deletes observations with duplicate BY values. */

proc rank data=port1 out=port2 group=5;
  by date group;
/* group: Breakpoints for size quintiles */
  var bm_adj;
  ranks bmr;
/* Sort bm_adj into quintiles, with the varname=bmr for each group for given date */
/* W.r.t. size quintile breakpoints "group", further sort into quintiles w.r.t. bm_adj */
run;

proc sort data=port2; by date group bmr; run;

proc rank data=port2 out=port3 group=5;
  by date group bmr;
  var mom;
  ranks momr;
/*For each (date, group, bmr) triple, rank MOM into quintiles and name it MOMR*/
run;
 
/* DGTW_PORT 1 for Bottom Quintile, 5 for Top Quintile */
data port4;
set port3;
bmr=bmr+1;
momr=momr+1;
/* As ranks starts from 0, add 1 above. */
DGTW_PORT=put(group,1.)||put(bmr,1.)||put(momr,1.);
/* Concatenate characters of GROUP(= SIZE RANK), BMR, MOMR in sequence. */
drop group bmr momr year;
if index(DGTW_PORT, '.') then delete;
/* Exclude which has null rank */
label DGTW_PORT="Size, B2M, and Momentum Portfolio Number";
run;
 
/* Use Size in June as Weights in the Value-Weighted Portfolios */
proc sql;
  create table crsp_m1
  as select a.*, b.date as formdate "Formation Date", b.dgtw_port, b.size as sizew
  from crsp_m (keep=permno date ret) as a, port4 as b
  where a.permno=b.permno and intnx('month', b.date,1,'e') <= a.date <= intnx('month', b.date,12,'e');
/* To track the historical return of specific DGTW_PORT, set a.date between intnx('month', b.date, ...)*/
/* Since the formdate, 1M jump for short-run reversal, and then track its historical return */
/* for the next 12M  */
/* SIZEW should remain the same during this 12M period, as SIZE is calculated once every year in June */
quit;
/*SIZEW would refer to SIZE Weight*/
 
/* Calculate Weighted Average Returns */
proc sort data=crsp_m1 nodupkey;  by date dgtw_port permno; run;

proc means data = crsp_m1 noprint;
by date dgtw_port;
where sizew>0;
var ret / weight=sizew ;
output out = dgtw_vwret(drop=_type_ _freq_)  mean= dgtw_vwret;
/*For each (date, dgtw_port), take avg. of RET, w/ the weight = sizew. That is, */
/* RET of size-weighted average, which is Value-Weighted avg. */
/*Here, dgtw_port=111,112 are different dgtw_port. So w.r.t. 5x5x5 portfolios (SIZE, BM_ADJ, MOM), */
/* DGTW_VWRET will be calculated. */
run;
 
/* Calculate DGTW Excess Return */
proc sql;
  create table mysas.dgtw_returns (index=(perm_dat=(permno date)))
  as select a.*,b.DGTW_VWRET format percentn8.4 "DGTW Benchmark Return",
    (a.ret-b.DGTW_VWRET) as DGTW_XRET "DGTW Excess Return" format percentn8.4
  from crsp_m1(drop=sizew) as a
  left join
  dgtw_vwret as b
/* crsp_m1 LEFT JOIN dgtw_vwret: crsp_m1 is "main". All the observations of dgtw_vwret which */
/* does not satisfy "ON" clause will be discarded. On the other hand, all the observations of crsp_m1 */
/* will remain no matter what. */
  on a.dgtw_port=b.dgtw_port and a.date=b.date
  order by permno, date;
quit;
 
/* House Cleaning */
proc sql;
drop table port1, port2, port3, port4, sizmom,
comp1, comp2, comp3, comp4, comp5, comp6,
crsp_m, crsp_m1, dgtw_vwret, nyse, bm_ind;
quit;
 
/* END */
 
/* Reference: Daniel , Kent , Mark Grinblatt, Sheridan Titman, and Russ Wermers,     */
/*   1997, "Measuring Mutual Fund Performance with Characteristic-Based Benchmarks," */
/*   Journal of Finance , 52, pp. 1035-1058.                                         */
 
/* ********************************************************************************* */
/* *************  Material Copyright Wharton Research Data Services  *************** */
/* ****************************** All Rights Reserved ****************************** */
/* ********************************************************************************* */
