/*Checking done! (2017.06.07)*/

/* Original program in fact implemented Daniel, Titman (2006)'s way. */
/* However, I altered BE calculation to that of Fama, French (1992, 1993). */
/* As the calculation of BE is the only difference, the rest of the codes below are the same. */

/* This yields a lot less nonmissing data than "B2M ratio - DT.sas". */
/* Too many are considered as missing using "B2M ratio - FF.sas". */

/*Compustat data: moved from /d_na to /naa */

/* Although the description of the source of calculating COMPUSTAT data are stated as*/
/* Daniel, Titman (JF, 2006) in both this file and "B2M ratio.sas", the detailed calculation are */
/* slightly different. I may have changed "B2M ratio.sas" a bit, so be cautious. */

/* Read "S&P Compustat Xpressfeed - Understanding The Data" for the method to calculate */
/* COMPUSTAT variables. */

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

/*Do not delete above*/

/* *************************************************************************** */
/* ********* W R D S   R E S E A R C H   A P P L I C A T I O N S ************* */
/* *************************************************************************** */
/*  Program      : market_to_book.sas                                          */
/*  Author       : Denys Glushkov, WRDS                                        */
/*  Date Created : Aug 2011                                                    */
/*  Last Modified: Aug 2011                                                    */
/*                                                                             */
/*  Description  : Calculate Raw and Industry Adjusted Market-to-Book Ratio    */
/*                 using separately Compustat only and CRSP-Compustat Merged   */
/*                 Compares the coverage, compute industry-level M/B ratios as */
/*                 well as industry-adjusted M/B at the company level          */
/* Output        : The output table INDADJMB contains firm-level raw M/B Ratios*/
/*                 using both approaches as well as their industry-adjusted    */
/*                 counterparts                                                */
/*                                                                             */
/*  Notes        : The program is based on a book-equity definition used by    */
/*                 Daniel and Titman in their "Market Reactions to Tangible    */
/*                 and Intangible Information" (Journal of Finance, 2006).     */
/*                 RA focuses on US companies, but can be extended to include  */
/*                 Canadian and international companies                        */
/*                                                                             */
/*                 Compustat Xpressfeed Total Liabilities(LT) no longer include*/              
/*                 the minority interest (MIB).Therefore, the new balance sheet*/
/*                 equation Total Assets (AT) = Total Liabilities (LT) +       */
/*                 Minority Interest (MIB) + Stockholders' Equity (SEQ)        */
/* *************************************************************************** */
   
/* Calculating Market-to-Book using Compustat only                             */
/* Advantage: captures many firms that are in Compustat, but not in CRSP       */
%let begdate=01jun1983; %let enddate=31dec2012;
/*%let begdate=01jan2008; %let enddate=31dec2015;*/
%let comp=comp; 
%let crsp=a_stock;
/* Standard Compustat Filter*/
%let comp_filter=consol='C' and indfmt='INDL' and datafmt='STD' and popsrc='D';
%let ind=10; *number of FF industries for which to compute median M/B ratio;
/*ind=5, 10, 12, 17, 30, 38, 48, 49 used   */

/* Step 1. Create Book Equity (BE) measure                                     */
/* CSHO: a company level item and includes all classes of common stock       */
/* prcc_c: the price as of Dec of the FISCAL year. So, for instance, if a    */
/* company's fiscal year end falls b/w jan and may 1990, then prcc_c will be   */
/* the Dec end price as of Dec 1989. However, if the fiscal year end falls b/w */
/* june and dec 1990, then prcc_c will be the price as of Dec 1990             */
 
data comp_extract/view=comp_extract; set &comp..funda;
/*	where (at>0 or not missing(sale)) and &comp_filter and fic='USA';*/
	where (at>0 or not missing(sale)) and &comp_filter and fic in ('USA', 'CAN');
	calyear=year(datadate);
	mcap_c = prcc_c * csho; /*Market Value of Equity at Dec end of fiscal year t  */

	if nmiss(SEQ,TXDB)>=1 then BE = 0;
	if missing(ITCB) then ITCB = 0;
   
   /*coalesce returns first non-missing value. If all first three missing, then return 0*/
	BVPS = coalesce(PSTKRV,PSTKL,PSTK,0); 
	BE = SEQ + TXDB + ITCB - BVPS;
	if BE < 0 then BE=.;
 
   /* Accounting data since calendar year 't-1'*/
	if year("&begdate"d) - 1<=calyear<=year("&enddate"d) + 1;
   	keep gvkey datadate calyear fyr fyear mcap_c prcc_c prcc_f 
			BE curcd sich;
/*	SEQ TXDB ITCB BVPS PSTKRV PSTKL PSTK;*/
label mcap_c="prcc_c*csho. Market Value of Equity at Dec end of fiscal year t";	
run;

/* Removed TXDITC (deferred taxes), PRBA (FASB106 adjustment) of Daniel, Titman (2006). */
/* So just defining a new dataset with the same contents. */
data comp_be;
set comp_extract;
run;

/* Step 2: calculate the market value as of Dec end                 */
/* Curcdm is the currency in which the monthly prices are available */
/* Primiss='P' is the primary issue with the highest average trading*/
/* volume over a period of time                                     */
data mvalue/view=mvalue; set &comp..secm;
  where month(datadate)=12 and primiss='P' and fic='USA'
  and "&begdate"d<=datadate<="&enddate"d;
  mcap_dec=prccm*cshoq;
  rename prccm=prc_dec;
  keep gvkey datadate prccm curcdm mcap_dec;
  label mcap_dec="prccm*cshoq. Alternative to mcap_c. Use it only when missing(mcap_c)";
run;
   
/* Step 3a. Create Book to Market (BM) ratios using Compustat only   */
/* This step is needed, because sometimes PRCC_C or CSHO is missing  */
/* in Compustat Fundamentals Annual dataset, so bring December market*/
/* value calculated from Compustat Security file                     */
/* BE: book equity reported in fiscal year t                         */
/* MCAP: market equity as of Dec of fiscal year t if available      */
/* BM_COMP contains the B/M ratios for the entire Compustat Universe */

proc sql; create table bm_comp
as select a.gvkey, a.datadate format date9., a.calyear, a.fyr, a.fyear, 
          a.prcc_f, a.prcc_c,b.prc_dec, a.curcd, a.sich,
          a.BE, a.mcap_c, b.mcap_dec, mdy(12,31,a.fyear) as fyear_end, 
       	  coalesce( ((BE>0)*BE)/mcap_c, ((BE>0)*BE)/mcap_dec) as bm_comp 
		  /*BE<0 are considered as missing, so discarded*/
from comp_be a left join mvalue b
on a.gvkey=b.gvkey and a.fyear=year(b.datadate) and a.curcd=b.curcdm
order by a.gvkey, a.datadate;
quit;
   
/* Step 3b. Alternatively, one can use Market value from CRSP as of  */
/* Dec end of fiscal year. Note that this will restrict the sample   */
/* to CRSP stocks only                                               */
/* Select Compustat's SICH as primary SIC code, if not available     */
/* then use CRSP's historical SICCD                                  */
proc sql; create table bm_comp_crsp
  as select a.*, b.lpermno as permno,
			b.lpermco as permco, 
          	((a.be>0)*a.be) / (abs(c.prc*c.shrout)/1000 ) as bm_crsp, 
          	coalesce(a.sich,d.siccd) as sic
   from bm_comp a left join &crsp..ccmxpf_linktable b
/*CCM is used here for merge*/
   on a.gvkey=b.gvkey and b.linkdt<=a.datadate and b.usedflag=1
   and linkprim in ('P','C')
   and (a.datadate<=b.linkenddt or missing(b.linkenddt)) 
   
  /* market value from CRSP as the Dec end of fiscal year end*/
  left join &crsp..msf (keep=permno date prc shrout) c 
  /*dsf is more than needed as Dec end is the only relevant*/

/*put(source,format) returns character, converting source into specified format*/
/*input(source,format) returns numeric*/
  on b.lpermno=c.permno and put(a.fyear_end, yymmn6.) = put(c.date, yymmn6.)
  /*Merge in historical SIC code from CRSP*/
  left join (select distinct permno, siccd, min(namedt) as mindate, 
          max(nameenddt) as maxdate
          from &crsp..stocknames group by permno, siccd) d
  on b.lpermno=d.permno and d.mindate<=a.fyear_end<=d.maxdate
  order by a.gvkey, a.datadate, sic;
quit;
 
/* Step 4. Invoke FF industry classification                  */
/* BM_COMP_CRSP contains B/M ratios based on "Compustat only" */
/* and CRSP-Compustat Merged database                         */
data bm_comp_crsp; set bm_comp_crsp;
 by gvkey datadate;
 if last.datadate; /*selects the record with non-zero SIC code*/
  %ffi&ind(sic);
run;
   
/*trimming extreme values of Book-to-Market within industries*/
proc sort data=bm_comp_crsp;
  by calyear ffi&ind._desc; 
run;

proc rank data=bm_comp_crsp out=bm_comp_crsp groups=100;
  by calyear ffi&ind._desc; var bm_comp bm_crsp;
  ranks rbm_comp rbm_crsp; /* ranks 2 variables independently. Default: ASCENDING. */
 /* Hence, rank=1 has the smallest, rank=99 has the biggest value. */
 /* DESCENDING: rank=1 has the biggest value. */
 /* rank missing if var missing */
run; 

data bm_comp_crsp; set bm_comp_crsp;
  if rbm_comp=99 then bm_comp=.; /* Discard only the biggest <-- why not rbm_comp=1 as well? */
  if rbm_crsp=99 then bm_crsp=.;
run;
   
/* Step 6. Number of distinct companies with non-missing B/M
/* based on Compustat only and based on Crsp-Compustat products*/
proc sql; 
  create table bmcomp
  as select distinct calyear,ffi&ind._desc, 
            count(distinct gvkey) as ngvkeys
  from bm_comp_crsp where not missing(bm_comp)  and curcd='USD'
  group by calyear, ffi&ind._desc;
    
  create table mysas.bmcrsp
  as select distinct calyear,ffi&ind._desc, 
            count(distinct permco) as npermnos
  from bm_comp_crsp where not missing(bm_crsp)  and curcd='USD'
  group by calyear, ffi&ind._desc;
quit;

data comparebmcov; 
  merge bmcomp mysas.bmcrsp;
    by calyear ffi&ind._desc;
    diff=(ngvkeys-npermnos)/npermnos;
    format diff percent7.4;
/*    if 1980<=calyear<=2010;*/
/*Above condition is not obvious, so commented*/
run;

proc transpose data=comparebmcov out=comparebmcov 
 (drop=_name_ label='Comparing Book-to-Market coverage between two methods');
  by calyear; id ffi&ind._desc;
  var diff;
run;
   
/*Step 7.  B/M ratios for different FF industries over time*/
/*Step 8. Industry-adjusted B/M ratios at the firm-year level*/
proc means data=bm_comp_crsp noprint;
  class calyear ffi&ind._desc;
  var bm_comp bm_crsp; where not missing(ffi&ind);
  output out=medians median=/autoname;
run;

proc sort data=medians; by calyear ffi&ind._desc; run;

proc transpose data=medians out=temp
  (label="Median Book-to-Market ratios for &ind  FF industries");
  by calyear; id ffi&ind._desc;
/*  where 1970<=calyear<=2010; */
/*Above condition is not obvious, so commented*/
  var bm_comp_median;
run;

/*-----------------------------------------------Plotting example--------------------------------------------------*/
/*options orientation=landscape device=pdf; */
/*symbol1 interpol =join ci =green co =green w = 3 ; */
/*symbol2 interpol =join ci =blue co =blue w=3; */
/*symbol3 interpol =join ci =red co =red w=3; */
/**/
/*proc gplot data =mysas.temp;*/
/*  Title 'Median B/M ratios of sample industries' ;  */
/*  plot hitec*calyear= 1 hlth*calyear= 2 manuf*calyear=3/ overlay legend ; */
/*run; quit; */
/*---------------------------------------------------------------------------------------------------------------------*/

 
/* Take out the industry component                            */
/* INDADJBM contains the firm-level raw and industry-adjusted */
/* Book-to-Market ratios calculated using Compustat Only      */
/* as well as CRSP-Compustat Merged Product                   */
data indadjbm_FF; merge bm_comp_crsp medians;
  by calyear ffi&ind._desc;
  bm_comp_indadj = bm_comp - bm_comp_median;
  bm_crsp_indadj = bm_crsp - bm_crsp_median;
  if missing(ffi&ind._desc) then do;
  bm_comp_indadj=. ; bm_crsp_indadj=. ; end;
/*  keep gvkey datadate permco permno fyear calyear bm_comp bm_crsp; */
/*  keep bm_comp_indadj bm_crsp_indadj ffi&ind._desc sic;*/
/* Discard all columns not specified by KEEP. */
  label calyear='Calendar year of the fiscal period end'
      bm_comp='B/M ratio (Compustat Only)'
      bm_crsp='B/M ratio (CRSP-Compustat Merged)'
      bm_comp_indadj='Industry-adjusted B/M ratio (Compustat Only)'
      bm_crsp_indadj='Industry-adjusted B/M ratio (CRSP-Compustat Merged')
      sic='Historical SIC code';
      if not missing(gvkey);
run;

proc sort data=indadjbm_FF; by gvkey datadate; run;

data indadjbm_FF; set indadjbm_FF;
retain count;
if first.gvkey then count=1;
else count=count+1;
label count="# of observations in COMPUSTAT";
by gvkey datadate;
run;
 
/* Clean the house*/
proc sql; 
drop table comparebmcov, comp_be, bmcomp, bm_comp,
           bm_comp_crsp, medians, temp
      view comp_extract, mvalue;
quit; 
 
/* ********************************************************************************* */
/* *************  Material Copyright Wharton Research Data Services  *************** */
/* ****************************** All Rights Reserved ****************************** */
/* ********************************************************************************* */
