/* Checking Done! (2017.Jun.13). Compare with "FF factors replication.sas" */
/* Note that calculation details are slightly different. */

/*%SIZE_BM(bdate='01JAN1962'd, edate='31Dec2016'd, link=a_ccm.ccmxpf_linktable) < 5 minutes*/

/* Note that "SIZE" is not from "ME" of BM=BE/ME. (Date of the data are different.) */

/* Fama, French(1992): "In June of each year, all NYSE stocks on CRSP are sorted by size(ME) */
/* to determine the NYSE decile breakpoints..." */

/*Fama, French(1992): To ensure that the accounting variables are known before the returns they
are used to explain, we match the accounting data for all fiscal yearends in
calendar year t - 1 (1962-1989) with the returns for July of year t to June of
t + 1. The 6-month (minimum) gap between fiscal yearend and the return
tests is conservative.*/

/* The identification of a fiscal year is the calendar year in which it ends.*/
/* FY: from t-1, July to t, June prior to 1976.*/
/*ex) FY17: Oct, 2016 ~ Sep, 2017. */
/*ex) datadate=20080531, fyear=2007, fyr=5 --> Jun, 2006 ~ May, 2007 written at 20080531. */
/*ex) datadate=20090930, fyear=2009, fyr=9 --> Aug, 2008 ~ Sep, 2009 written at 20090930. */

/*BM ratio in year t (Daniel, Titman, 2006): */
/*BE: at the end of the firm's fiscal year ending anywhere in year t-1. */
/*ME: last trading day of calendar year t-1. */

/* (LHS) of cross-sectional reg. of monthly ret. b/w July of year t and June of year t+1 */
/* all use the same set of (RHS), BM ratio in year t ("constant" b/w July, year t and June, year t+1..) */
/* Hence, this "size_bm_port" should be merged with monthly returns of test assets.*/

/*comp.aco_pnfnda: .../comp/sasdata/naa/pension/ */
/* Daniel, Titman (2006) uses comp.aco_pnfnda for BM calculation. This is "FASB106 adjustment" in the appendix.*/

/*a_ccm.ccmxpf_linktable: almost equivalent to a_ccm.ccmxpf_lnkhist */

/* Although the description of the source of calculating COMPUSTAT data are stated as*/
/* Daniel, Titman (JF, 2006) in both this file and "B2M ratio.sas", the detailed calculation are */
/* slightly different. I may have changed "B2M ratio.sas" a bit, so be cautious. */

/* Read "S&P Compustat Xpressfeed - Understanding The Data" for the method to calculate */
/* COMPUSTAT variables. */

/* ********************************************************************************* */
/* ************** W R D S   R E S E A R C H   A P P L I C A T I O N S ************** */
/* ********************************************************************************* */
/* Program   : SIZE_BM.SAS                                                           */
/* Summary   : Assign stocks into 6 Size-BM portfolios                               */
/* Date      : February 2008. Modified Mar 2011                                      */
/* Author    : Denys Glushkov, WRDS                                                  */
/*                                                                                   */
/* Details   : Macro assigns the stocks into six Size-BM portfolios based on the     */
/*             methodology outlined on Ken French webiste at                         */
/*             http://mba.tuck.dartmouth.edu/pages/faculty/ken.french/Data_Library   */
/*             /six_portfolios.html                                                  */ 
/*                                                                                   */
/* The size breakpoint for year t is the median NYSE market equity at the end of June*/ 
/* of year t. BE/ME for June of year t is the book equity for the last fiscal year   */
/* end in t-1 divided by ME for December of t-1. The BE/ME breakpoints are the 30th  */
/* and 70th NYSE percentiles.                                                        */
/*                                                                                   */
/* Parameters : - BDATE: Sample Start Date                                           */
/*              - EDATE: Sample End Date                                             */
/*              - Link : Dataset containing map b/w IBES Ticker and Compustat GVKEY  */
/*                                                                                   */
/* To run the program, a user should have access to CRSP daily and monthly stock,    */
/* Compustat Annual and Quarterly sets, IBES and CRSP/Compustat Merged database      */
/* ********************************************************************************* */

%MACRO SIZE_BM (bdate=, edate=, link=a_ccm.ccmxpf_linktable);
/*&link: used for LINKDT and LINKENDDT. 
Hence, both a_ccm.ccmxpf_linktable and a_ccm.ccmxpf_lnkhist can be used. */
/****************************************************************
Step 1. Extract CRSP Data for NYSE and AMEX Common Stocks  
Merge historical codes with CRSP Monthly Stock File      
Restriction on Share Code: common shares only            
****************************************************************/

%let filtr = (shrcd in (10,11));
/*SHRCD, first digit=1: Ordinary common shares */
/*SHRCD, second digit=0: Securities which have not been further defined. */
/*SHRCD, second digit=1: Securities which need not be further defined. */
 
* Selected variables from the CRSP Monthly Stock File;     
%let fvars =  prc ret shrout;                                
*  Selected variables from the CRSP Monthly Event File;
%let evars =  exchcd shrcd dlret;                            
* Modify beginning and ending dates;
/*%let begdate=intck('year',&begindate,-1); */
%let begdate=intck('year',&bdate,-1); 

/* Invoke CRSPMERGE WRDS Research Macro. Data Output: CRSP_M */
libname myMacro "D:\Dropbox\SAS_scripts\myMacro";
%include myMacro('crspmerge.sas');
%crspmerge(s=m, start=&bdate, end=&edate, sfvars=&fvars, sevars=&evars, filters=&filtr, outset=crsp_&s.); 
/*%crspmerge(): Merges a_stock.msf, a_stock.mseall, a_stock.msenames. */
/* &sfvars from msf, &sevars from mseall */


data msex2;
  set crsp_m;
  by permno date;
  * Create size variable;
  size=abs(prc)*shrout; 
/*PRC<0 if mid price is written which is not traded*/
  size_lag=lag(size); *Lag Size for weights;
  ldate = lag(date);
  if first.permno then size_lag = size / (1+ret); 
/* To proxy for prior period's size, discount current period's size. */
/* As it is reasonable to assume that the size will grow w/ the mean of its realized return. */

  * Option for Delisting Returns;
/*  ret = sum(ret,dlret);*/
/* DLRET: calculated using DLAMT (not DLPRC) */
/* In the delisting month, RET set to missing and DLRET set to some number */
  * Comment previous line not to adjust for delisting events;

  if size > 0; * Keep only whose size is larger than 0;
  drop prc shrout ldate;
run;

/************************************************
Step 2. Assign Stocks to NYSE Size-Based groups 
************************************************/
proc sort data=msex2 (keep=date size exchcd) out=msex3;
  where month(date)=6 and exchcd=1;
  by date;
run;
/* Keep June only and NYSE only (exchcd=1: NYSE) */
/* SIZE of June is a reference point for Small/Big classification. */
/* Even if non-NYSE stocks are used, size breakpoints are often calculated using NYSE stocks only */
/* as NASDAQ stocks are much smaller compared to NYSE stocks. */

/* Below should be adjusted to sort size into other percentiles (e.g. quintiles, deciles, ...) */
/* Use PROC UNIVARIATE for breakpoints using other percentiles (other than just median). */
/* See "DGTW.sas" for this. */
proc means data=msex3 noprint;
  var size;
  by date;
  output out=nyse (drop=_freq_ _type_) median=/autoname;
/* Calculate median, and automatically name it w.r.t. its variable name */
/* (Newvarname would be size_median) */
run;

/*Keep JUN only below. */
proc sql;
  create table size_assign
  as select a.permno, a.date, a.size,
  case when size <= size_median then 'Small' else 'Big'
  end as size_port
/*varname: size_port, value: 'Small', 'Big'*/
  from msex2 (keep=permno date size where = (month(date)=6)) as a
/*Compare size_median of firm's SIZE on JUN as above. */
  left join nyse as b
  on a.date= b.date;
quit;
/*Keep June only as in msex3, where the SIZE in June is a reference point of Small/Big classification. */

/*************************************************************
2. Create Book Equity(BE) measure 
from Compustat (definition from Daniel and Titman (JF, 2006)
"Market Reactions to Tangible and Intangible Information"
*************************************************************/
/* Above definition of BE is same as "B2M ratio.sas". Cross-check for the details of calculation. */
/* No consideration for fiscal year, calendar year match below. */
/* For the given calendar date (DATADATE. Note that fyear is the fiscal year.), */
/* calculate that year's value and write it with calendar date or DATADATE.*/
data comp_extract;
  set comp.funda 
  (where=(fyr > 0 and at > 0 and consol='C' and 
    indfmt='INDL' and datafmt='STD' and popsrc='D'));
/*AT: Assets - Total or Liabilities and Stockholders' Equity - Total */
/* For the details for below items, search Dropbox/.../WRDS/compustat/ */
/* CONSOL: Level of consolidation - company annual descriptor. C: consolidated */
/*INDFMT: Industry format. INDL: Industrial (International and North America companies) */
/*DATAFMT: Data format. STD: Standardized */
/*POPSRC: Population source. D: Domestic (North America companies only) */

  if missing(SEQ)=0 then she=SEQ; else
/*SHE: Shareholder's equity */
/*SEQ: Stockholders' equity - parent */
  if missing(CEQ)=0 and missing(PSTK)=0 then she=CEQ+PSTK;else /*if both not missing */
/*CEQ: Common/Ordinary equity - total */
/*PSTK: Preferred Stock - Carrying value OR preferred/preference stock (capital) - total */
/**/
  if missing(AT)=0 and missing(LT)=0 and missing(MIB)=0 then she=AT-(LT+MIB);
/*AT: Assets - total */
/*LT: Liabilities - total */
/*MIB: Noncontrolling Interest (Balance Sheet) OR Redeemable noncontrolling interest (Balance Sheet)  */
  else she=.; *ELSE, let SHE be missing;
  if missing(PSTKRV)=0 then BE0=she-PSTKRV;else 
/*PSTKRV: Preferred stock - redemption value */
  if missing(PSTKL)=0 then BE0=she-PSTKL; else 
/*PSTKL: Preferred stock - liquidating value */
  if missing(PSTK)=0 then BE0=she-PSTK; else BE0=.;
/*PSTK: Preferred Stock - Carrying value OR preferred/preference stock (capital) - total */
/* Can use BE0 = she - coalesce(PSTKRV,PSTKL,PSTK,.) <-- if all first three missing, then set to last argument, which is missing.  */
/* (Note that Subtraction/addition of missing data is also missing) */

/*----------------------------------------------------------------------------------*/
  * Converts fiscal year into calendar year data;
/* NOTE THAT firms w/ FYR b/w [1,5], their "FYEAR" = "Calendar year" - 1 whereas */
/* firms w/ FYR b/w [6,12] have "FYEAR" = "Calendar year". */

  /* That is, if FYR = May, then at DATADATE=(t, May), FYEAR=t-1, data b/w [t-2 May, t-1 May] are written. */
/* If FYR = June, then at DATADATE=(t,June), FYEAR=t, data b/w [t-1 June, t June] are written. */

/* Hence, below procedures are "consistent." */
/* Thus, in fact, "data_fyend" = "datadate" by construction. */
/* Note that DATADATE is from comp.funda, so writes the data of fiscal year end month annually only.*/

  if (1 <= fyr <= 5) then date_fyend=intnx('month',mdy(fyr,1,fyear+1),0,'end');
/*mdy(month, day, year): converts date into SAS datenum */
/*ex) mdy(7, 11, 2001) = 15167 */
/*Hence, date_fyend: last calendar day where year=fyear+1, month=fyr */
/*FYEAR: Data year - fiscal */
/*FYR: fiscal-year end "month" */
/* Above means FYR is b/w JAN and MAY. */
  else if (6 <= fyr <= 12) then date_fyend=intnx('month',mdy(fyr,1,fyear),0,'end');
/* If FYR is b/w JUNE and DEC. */
  calyear=year(date_fyend);
/* DATE_FYEND = DATADATE in fact, so CALYEAR is current calendar year. */
  format date_fyend date9.;

  * Accounting data since calendar year 't-1';
/*  if (year(date_fyend) >= year(&begindate) - 1) */
/*  and (year(date_fyend) <= year(&enddate) + 1);*/
  if (year(date_fyend) >= year(&bdate) - 1) 
  and (year(date_fyend) <= year(&edate) + 1);
/* If &bdate > Jan or &edate < Dec, then data_fyend > &bdate or data_fyend < &edate may not hold */
/* for some observations. Not to discard those observations, above conditions were used. */
  keep gvkey calyear fyr fyear BE0 date_fyend indfmt consol datafmt popsrc datadate TXDITC;
run;

/*comp.aco_pnfnda: .../comp/sasdata/naa/pension/ */
/* Below part is from Daniel, Titman (2006), "Appendix: Data Construction"*/
/* "Finally, if not missing, we add to this value balance sheet deferred taxes (item 35) */
/* and subtract off the FASB106 adjustment (item330)." */
/* FASB106 adjustment is about postretirement benefit. */
proc sql; 
create table comp_extract
/* No duplicates here unlike BM0 below. --> no need of "select distinct". */
as   select a.gvkey, a.calyear, a.fyr, a.date_fyend, 
/* a.date_fyend = a.datadate in fact. As a.datadate is from comp.funda, */
/* so writes the data of the fiscal year end month annually only. */
/* Note that DATDATE is a calendar year. */

case when missing(TXDITC)=0 and missing(PRBA)=0 then BE0+TXDITC-PRBA else BE0
/*TXDIC: Deferred Taxes and Investment Tax Credit */
/*PRBA: Postretirement Benefit Asset (Liability) (Net) <--  from comp.aco_pnfnda located at .../naa/pension/ */
end as BE
from comp_extract as a left join 
comp.aco_pnfnda (keep=gvkey indfmt consol datafmt popsrc datadate prba) as b
on   a.gvkey=b.gvkey and a.indfmt=b.indfmt and 
a.consol=b.consol and a.datafmt=b.datafmt and 
a.popsrc=b.popsrc and a.datadate=b.datadate;
quit;

/******************************************************
Step 3. Create Book to Market (BM) ratios at December 
******************************************************/
/* Note that BE is not necessarily that of June's here. */
/* This will be considered in table BM below. */
/* Note that SIZE breakpoints are calculated via June's data. */
/* ME is from December, by the way. */
proc sql;
  create table BM0	(where=(BM>0))
/*  as select a.gvkey, a.calyear, c.permno, c.exchcd, c.date, */
  as select distinct a.gvkey, a.calyear, a.fyr, a.date_fyend, a.BE, c.permno, c.exchcd, c.date, 
/*c.date: MAIN DATE. */ 
/*(a.date_fyend, a.calyear: just to track to see merge was done in a right manner.) */
/* Found some duplicates (e.g. gvkey=186087, permno=12743), added "distinct" above */
  a.be/(abs(c.prc)*c.shrout/1000) as BM
/* Using BE (a.be. Book value at the end of the firm's fiscal year ending anywhere in (calendar) year t-1.) */
/* (Not necessarily that of June, because comp_extract writes BE with DATADATE, */
/* a calendar date, appearing only once in any year.) */
/* and December's ME (c.prc, c.shrout at c.date), calculate BE/ME at Decmber (c.date) */
  from comp_extract as a, 
  &link as b,		
  crsp_m (where=( month(date)=12)) as c
/*crsp_m: contains monthly data (not only one each year as in COMPUSTAT-based table)*/
/*For BM calculation, ME: the last calendar year's DEC value. */
/*BE: the last fiscal year end month (FYR, not FYEAR) (can be any month) */
/* --> not necessarily that of June (at this stage. Will be of June's in table BM below.) */
/*SIZE breakpoints: last calendar year's JUN value. */
  where a.gvkey=b.gvkey and 
  ((b.linkdt <= c.date <= b.linkenddt) or 
    (b.linkdt<=c.date and b.linkenddt=.E) or
    (c.date <= b.linkenddt and b.linkdt=.B)) and b.lpermno=c.permno
/*b.linkdt=.B: The link was valid before CRSP's earliest record. Hence set to the SAS missing code. */
/*b.linkenddt=.E: SAS missing code ".E" if a link is still valid. */
  and a.calyear = year(c.date) and (abs(c.prc)*c.shrout)>0;
quit;
/*&link: used for LINKDT and LINKENDDT. 
Hence, both a_ccm.ccmxpf_linktable and a_ccm.ccmxpf_lnkhist can be used. */

/********************************************************
4. Keep only those cases with valid stock market in June 
********************************************************/
/* No matter what FYR is, write next calendar year's June's SIZE, SIZE_PORT in accordance with */
/* this year's December, a.date. */
proc sql;
  create table BM
/* No duplicates here, unlike BM0 above. */
  as select a.gvkey, a.permno, a.bm, a.calyear, a.date as decdate, 
/*DECDATE: a.date is DEC values only, as DEC value is used for ME (calendar year's last day: DEC 30 or 31) */
  a.exchcd, b.date, b.size, b.size_port
/*a.date or decdate: main date. (b.date: used for merge only, and will be discarded later on.) */
  from BM0 as a, size_assign as b
/*size_assign: contains JUN only */
  where a.permno=b.permno
  and intck('month',a.date,b.date)=6 and b.size>0; *<-- why NOT intck('month', b.date, a.date)=6? ;
/*--> Above is not wrong. "BE" for BM=BE/ME calculation uses BE at the end of the firm's fiscal year */
/* ending anywhere in (calendar) year t-1, whereas "ME" is from last trading day of calendar year t-1(usually Dec 31). */

/*"b.size" is not from "ME" of BM=BE/ME. */
/* Fama, French(1992): "In June of each year, all NYSE stocks on CRSP are sorted by size(ME) */
/* to determine the NYSE decile breakpoints..." */

/* where a.date + 6M = b.date. Hence, effectively, DECDATE (=a.date) + 6M = DATE(=b.date) */
/* Thus, "DATE" is "current(or next) calendar year's" "JUNDATE" */
/* and DECDATE will be interpreted as the last(or current) year's DEC. */
quit;


/***************************************************
5. Assign stocks to NYSE BM-based groups 
***************************************************/
proc sort data=BM out=nyse1 (keep=permno bm calyear decdate date);
  where exchcd=1;
  by decdate;
run;

/* Below splits data into terciles w.r.t. BM calculating 2 breakpoints. */
/* BM breakpoints w.r.t. DECDATE, not DATE(=DECDATE + 6M) */
proc univariate data=nyse1 noprint;
  var bm;
  by decdate;
  output out=nyse2 pctlpts = 30 70 pctlpre=per;
/* pctlpts = 20 to 80 by 20 */
run;

*Merge back with master file that contains all securities 
from NYSE, Nasdaq and AMEX;
proc sql;
  create table bm1
  as select a.permno, a.gvkey, a.bm, a.size, a.size_port, a.date, a.decdate,
/*a.date: "JUNDATE" used for Big/Small classification. */
  case when bm <= per30 then 'Low'
  when per30 < bm <= per70 then 'Medium'
  else 'High' 
  end as bm_port
/* varname: BM_PORT, value: Low, Medium, High */
  from BM as a, nyse2 as b
  where a.decdate=b.decdate;
  /* The 'date' variable refers to June, whereas                */
  /* 'decdate' variable refers to December of the previous (calendar) year */
quit;

proc sort data=bm1; by permno descending date; run;

/* LEADDATE: for what is it calculated? */
data size_bm_port; set bm1;
	by permno descending date;
    leaddate=lag(date);
/* leaddate: Later than date. As it contains annual data in this table, leaddate = lag(date) = date + 1Y. */
/*    if first.permno then leaddate=intnx('month',date,-12,'end');*/
	if first.permno then leaddate=intnx('month',date,12,'end');
/* Above intnx('month',date, "-12", 'end) seem to be wrong. It doesn't correspond to "lag(date)". */
    format date leaddate decdate date9.;
    rename date=size_date decdate=bm_date;
    label date='Valid date for firm size';
    label decdate='Valid date for Book-to-Market';
run;

proc sort data=size_bm_port; by permno size_date; run;

proc sql; drop table nyse1, nyse2, nyse, size_assign, 
    msex2, msex3, bm, bm0, bm1, comp_extract;
quit;
%MEND;

/* ********************************************************************************* */
/* *************  Material Copyright Wharton Research Data Services  *************** */
/* ****************************** All Rights Reserved ****************************** */
/* ********************************************************************************* */
