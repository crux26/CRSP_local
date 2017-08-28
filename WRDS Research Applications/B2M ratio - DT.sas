/*fic: contains many countries - 30-40. Use fic in ('USA', 'CAN') for North America. */
/*curcd: {'USD', 'CAD'} */

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
/*                 Compustat Xpressfeed Total Liabilities(LT) no longer include */               
/*                 the minority interest (MIB).Therefore, the new balance sheet */ 
/*                 equation Total Assets (AT) = Total Liabilities (LT) +       */
/*                 Minority Interest (MIB) + Stockholders' Equity (SEQ)        */
/* *************************************************************************** */
  
/* Calculating Market-to-Book using Compustat only                             */
/* Advantage: captures many firms that are in Compustat, but not in CRSP       */

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

%let bdate=01jan1962; %let edate=31dec2015; 
%let comp=mysas;  
%let crsp=mysas; 
/* Standard Compustat Filter*/
%let comp_filter=consol='C' and indfmt='INDL' and datafmt='STD' and popsrc='D'; 
/*consol: Level of consolidation. {C(onsolidated), I, N, P, D, E, R}*/
/*indfmt: Industry Format. {FS (Financial Services), INDL (Industrial), ISSUE (Issue-level FUndamentals)} */
/*datafmt: Data Format. {STD, HIST_STD, RST_STD, SUMM_STD, PRE_AMENDS, PRE_AMENDSS} */
/*popsrc: Population Source. {D(omestic - NA companies), I(nternational)}*/
%let ind=10; *number of FF industries for which to compute median M/B ratio;
/*ind=5, 10, 12, 17, 30, 38, 48, 49 used   */
 
/* Step 1. Create Book Equity (BE) measure                                     */
/* CSHO is a company level item and includes all classes of common stock.       */
/* prcc_c is the price as of Dec of the FISCAL year. So, for instance, if a    */
/* company's fiscal year end falls b/w jan and may 1990, then prcc_c will be   */
/* the Dec end price as of Dec 1989. However, if the fiscal year end falls b/w */
/* june and dec 1990, then prcc_c will be the price as of Dec 1990.             */
  
data comp_extract/view=comp_extract; set &comp..funda; 
/*   where (at>0 or not missing(sale)) and &comp_filter and fic='USA'; */
 where (at>0 or not missing(sale)) and &comp_filter and fic in ('USA', 'CAN'); 
   calyear=year(datadate); 
   mcap_c=prcc_c*csho; /*Market Value of Equity at Dec end of fiscal year t  */	

   /*to obtain shareholders equity (SHE), use stockholders equity (SEQ), if not missing  */
   if not missing(SEQ) then SHE=SEQ; else

   /*if SEQ missing, use Total Common Equity (CEQ) plus Preferred Stock Par Value (PSTK)  */
   if nmiss(CEQ,PSTK)=0 then SHE=CEQ+PSTK; else
/*nmiss(A,B)=1: A or B is missing, but not both */

   /*if CEQ or PSTK is missing, use                                          */
   /*Total Assets(AT) - (Total Liabilities (LT)+Minority Interest (MIB)), if all exist        */
   if nmiss(AT,LT)=0 then SHE=AT-sum(LT,MIB); 
/* sum(3, .) = 3 */
   else SHE=.; 
/* Compustat Xpressfeed Total Liabilities(LT) no longer include */               
/* the minority interest (MIB). Therefore, the new balance sheet equation */ 
/* Total Assets (AT) = Total Liabilities (LT) +  Minority Interest (MIB) + Stockholders' Equity (SEQ) */
/* This is why MIB appears in the code but not in the paper. */

   /* "To obtain book equity (BE), subtract from the shareholders' equity (SHE) the preferred*/ 
   /*stock value, using redemption (PSTKRV), liquididating (PSTKL) or */
   /*carrying value (also called par value, PSTK), in that order, if available." */ 
   PS = coalesce(PSTKRV, PSTKL, PSTK, .); 
/* "If all of the redemption, liquidating, or par values are missing from COMPUSTAT, then we */
/* treat the book equity value as missing for that year." */
   BE0 = SHE-PS; 
   /* PS: Preferred Stock Value */
   /* Accounting data since calendar year 't-1' */
   if year("&bdate"d) - 1<=calyear<=year("&edate"d) + 1; 
   keep gvkey calyear fyr fyear BE0 indfmt consol mcap_c sich  
        datafmt popsrc datadate TXDITC prcc_f prcc_c curcd; 
run; 
/*gvkey: global company key. Unique identifer that represents each company throughout Xpressfeed. */
/* All company data records are identified by a GVKEY. Except in rare circumstances, GVKEY do not change. */
/* calyear: year(datadate), fyr: fiscar year-end month, fyear: data year - fiscal */
/* indfmt: industry format, consol: level of consolidation, mcap_c: prcc_c*csho */
/* sich: Standard Industrial Classification - Historical */
/* datafmt: data format, popsrc: Population Source */
/* TXDITC: deferred taxes, prcc_f: Price Close - Annual - Fiscal, prcc_c: Price Close - Annual - Calendar */
/* curcd: ISO Currency Code*/


/* Finally, if not missing, add balance sheet deferred taxes (TXDITC) and */
/* subtract off the FASB106 adjustment (PRBA) */
/*&comp..aco_pnfnda: pension dataset */
proc sql; create table comp_be 
as select  
  a.gvkey, a.calyear, a.fyr, a.datadate, a.fyear, a.mcap_c, 
  a.prcc_f, a.prcc_c, sum(a.BE0, a.TXDITC, -b.PRBA) as BE, a.curcd, a.sich 
from comp_extract a left join  
     &comp..aco_pnfnda (where=(&comp_filter)) b 
on a.gvkey=b.gvkey and a.datadate=b.datadate; 
quit; 
  
/* Step 2: calculate the market value as of Dec end                 */
/* Curcdm is the currency in which the monthly prices are available. */
/* Primiss='P' is the primary issue with the highest average trading volume */
/* over a period of time.                                     */
data mvalue/view=mvalue; set &comp..secm; 
/*  where month(datadate)=12 and primiss='P' and fic='USA'*/
  where month(datadate)=12 and primiss='P' and fic in ('USA', 'CAN')
  and "&bdate"d<=datadate<="&edate"d; 
  mcap_dec=prccm*cshoq; 
  rename prccm=prc_dec; 
  keep gvkey datadate prccm curcdm mcap_dec; 
run; 
/*primiss: Primary/Joiner Flag. {P(rimary), J(oiner} */
/* P: The primary issue identifies the issue with the highest average trading volume over a period of time. */
/* J: THe joiner issue identifies secondary issues of a company. */

 
/* Step 3a. Create Book to Market (BM) ratios using COMPUSTAT only.   */
/* This step is needed, because sometimes PRCC_C or CSHO is missing  */
/* in Compustat Fundamentals Annual dataset (funda), so bring December market */
/* value calculated from COMPUSTAT Security file (secm <-- mvalue).  */
/* BE- book equity reported in fiscal year t                         */
/* MCAP - market equity as of Dec of fiscal year t if available.      */
/* Coalesce function returns the first non-missing value for the M/B */
/* the order of the listed arguments                                 */
/* MB_COMP contains the M/B ratios for the entire Compustat Universe */
proc sql; create table bm_comp 
as select a.gvkey, a.datadate format date9., a.calyear, a.fyear,  
          a.prcc_f, a.prcc_c,b.prc_dec, a.curcd, a.sich, 
          a.be, a.mcap_c, b.mcap_dec, mdy(12,31,a.fyear) as fyear_end,  
          coalesce( ( (be>0)*be/mcap_c), ( (be>0)*be)/mcap_dec ) as bm_comp 
from comp_be as a left join mvalue as b 
on a.gvkey=b.gvkey and a.fyear=year(b.datadate) and a.curcd=b.curcdm 
order by a.gvkey, a.datadate; 
quit; 
/* prc_dec: prccm where month(datadate)=12 */
/* mcap_c: prcc_c * csho. from funda. Market Value of Equity at Dec end of fiscal year t.  */
/* mcap_dec: prccm * cshoq. from secm. Alternative to mcap_c. */


/* Step 3b. Alternatively, one can use Market value from CRSP as of  */ 
/* Dec end of fiscal year (instead using that of COMPUSTAT). */
/*Note that this will restrict the sample to CRSP stocks only. */
/* Select Compustat's SICH as primary SIC code. If not available, then use CRSP's historical SICCD. */
proc sql; create table bm_comp_crsp 
  as select a.*, b.lpermno as permno, b.lpermco as permco,  
          ((a.be>0)*a.be) / (abs(c.prc*c.shrout)/1000) as bm_crsp,  
/*abs(c.prc*c.shrout)/1000 = ME. c.shrout: denoted in the unit of 1k number of shares. */
/* Dividing by 1000 results in ME measuring in $1m. */
          coalesce(a.sich,d.siccd) as sic 
/* sich: Standard Industrial Classification - Historical */
/* siccd: SIC Code- Reference */
   from bm_comp as a 

   left join &crsp..ccmxpf_linktable as b 
   on a.gvkey=b.gvkey and b.usedflag=1 
/* usedflag: Flag marking whether link is used in building composite record. */
/* usedflag=1: this link is applicable to the selected PERMNO and used to identify ranges of COMPUSTAT data*/
/* from a GVKEY used to build a composite GVKEY record corresponding to the PERMNO. */
/* usedflag=-1: this link is informational, indirectly related to the PERMNO, but not used.  */

   and b.linkdt<=a.datadate and (a.datadate<=b.linkenddt or missing(b.linkenddt))
   /*LINKDT: first effective date of the current link*/
   /*LINKENDDT: last effective date of the current link record. If the name represents the current link info.,*/
   /*the LINKENDDT is set to 99,999,999*/
   and linkprim in ('P','C')  
   /* LINKPRIM: Primary issue marker for the link. Based on COMPUSTAT Primary/Joiner flag (primiss), */
/* indicating whether this link is to COMPUSTAT's marked primary security during this range. */

/* {P (Primary), J (Secondary), C (Primary), N (Secondary)}. */
/* P: Primary, identified by COMPUSTAT in monthly security data (secm). */
/* C: Primary, assigned by CRSP to resolve ranges of overlapping or missing primary markers from COMPUSTAT */
/* in order to produce one primary security throughout the company history. */
  
  /* market value from CRSP as the Dec end of fiscal year end (instead of those from COMPUSTAT) */
  left join &crsp..msf (keep=permno date prc shrout) as c 
  on b.lpermno=c.permno and put(a.fyear_end,yymmn6.)=put(c.date,yymmn6.) 
  /* fyear_end: mdy(12, 31, a.fyear) */
  /* Merge in historical SIC code from CRSP */

  left join (select distinct permno, siccd, min(namedt) as mindate,  
          max(nameenddt) as maxdate 
          from &crsp..stocknames group by permno, siccd) as d 
  on b.lpermno=d.permno and d.mindate<=a.fyear_end<=d.maxdate
  order by a.gvkey, a.datadate, sic; 
quit; 
/* Isn't "namedt, nameenddt" checking through ccmxpf_linktable enough? */
/* Using both: #(sample)=382421, ccmxpf_linktable only: #(sample)=381448. */
/* This is "left join", which is essentially an addition of a database, */
/* so additional constraints results in more number of samples in the output dataset. */


/* Step 4. Invoke FF industry classification                  */
/* BM_COMP_CRSP contains B/M ratios based on "Compustat only" */
/* and CRSP-Compustat Merged database                         */
data bm_comp_crsp; set bm_comp_crsp;
 by gvkey datadate;
 if last.datadate; /*selects the record with non-zero SIC code*/
  %ffi&ind(sic); 
run; 

/*START AGAIN FROM HERE*/

 
/*trimming extreme values of Market-To-Book within industries*/
proc sort data=bm_comp_crsp; 
  by calyear ffi&ind._desc;  
run; 
proc rank data=mb_comp_crsp out=mb_comp_crsp groups=100; 
  by calyear ffi&ind._desc; var mb_comp mb_crsp; 
  ranks rmb_comp rmb_crsp; 
run;  
data mb_comp_crsp; set mb_comp_crsp; 
  if rmb_comp=99 then mb_comp=.; 
  if rmb_crsp=99 then mb_crsp=.; 
run; 
  
/* Step 6. Number of distinct companies with non-missing M/B 
/* based on Compustat only and based on Crsp-Compustat products*/
proc sql;  
  create table mbcomp 
  as select distinct calyear,ffi&ind._desc,  
            count(distinct gvkey) as ngvkeys 
/*  from mb_comp_crsp where not missing(mb_comp)  and curcd='USD'*/
  from mb_comp_crsp where not missing(mb_comp)  and curcd in ('USD', 'CAD')
  group by calyear, ffi&ind._desc; 
   
  create table mbcrsp 
  as select distinct calyear,ffi&ind._desc,  
            count(distinct permco) as npermnos 
/*  from mb_comp_crsp where not missing(mb_crsp)  and curcd='USD'*/
  from mb_comp_crsp where not missing(mb_crsp)  and curcd in ('USD', 'CAD')
  group by calyear, ffi&ind._desc; 
quit; 
data comparembcov;  
  merge mbcomp mbcrsp; 
    by calyear ffi&ind._desc; 
    diff=(ngvkeys-npermnos)/npermnos; 
    format diff percent7.4; 
/*    if 1980<=calyear<=2010; */
run; 
proc transpose data=comparembcov out=comparembcov  
 (drop=_name_ label='Comparing Market-to-Book coverage between two methods'); 
  by calyear; id ffi&ind._desc; 
  var diff; 
run; 
  
/*Step 7.  M/B ratios for different FF industries over time*/
/*Step 8. Industry-adjusted M/B ratios at the firm-year level*/
proc means data=mb_comp_crsp noprint; 
  class calyear ffi&ind._desc; 
  var mb_comp mb_crsp; where not missing(ffi&ind); 
  output out=medians median=/autoname; 
run; 
proc sort data=medians; by calyear ffi&ind._desc;run; 
proc transpose data=medians out=temp 
  (label="Median Market-to-Book ratios for &ind  FF industries"); 
  by calyear; id ffi&ind._desc; 
/*  where 1970<=calyear<=2010;  */
  var mb_comp_median; 
run; 
options orientation=landscape device=pdf;  
symbol1 interpol =join ci =green co =green w = 3 ;  
symbol2 interpol =join ci =blue co =blue w=3;  
symbol3 interpol =join ci =red co =red w=3;  
proc gplot data =temp; 
  Title 'Median M/B ratios of sample industries' ;   
  plot hitec*calyear= 1 hlth*calyear= 2 manuf*calyear=3/ overlay legend ;  
run; quit;  
  
/* Take out the industry component                            */ 
/* INDADJMB contains the firm-level raw and industry-adjusted */
/* Market-to-Book ratios calculated using Compustat Only      */
/* as well as CRSP-Compustat Merged Product                   */
data indadjmb; merge mb_comp_crsp medians; 
  by calyear ffi&ind._desc; 
  mb_comp_indadj=mb_comp-mb_comp_median; 
  mb_crsp_indadj=mb_crsp-mb_crsp_median; 
  if missing(ffi&ind._desc) then do; 
  mb_comp_indadj=.;mb_crsp_indadj=.;end; 
  keep gvkey datadate permco permno fyear calyear mb_comp mb_crsp;  
  keep mb_comp_indadj mb_crsp_indadj ffi&ind._desc sic; 
  label calyear='Calendar year of the fiscal period end'
      mb_comp='M/B ratio (Compustat Only)'
      mb_crsp='M/B ratio (CRSP-Compustat Merged)'
      mb_comp_indadj='Industry-adjusted M/B ratio (Compustat Only)'
      mb_crsp_indadj='Industry-adjusted M/B ratio (CRSP-Compustat Merged') 
      sic='Historical SIC code'; 
      if not missing(gvkey); 
run; 
  
/* Clean the house*/
proc sql;  
drop table comparembcov, comp_be, mbcomp, mbcrsp,mb_comp, 
           mb_comp_crsp, medians, temp 
      view comp_extract, mvalue; 
quit;  

/* ********************************************************************************* */
/* *************  Material Copyright Wharton Research Data Services  *************** */
/* ****************************** All Rights Reserved ****************************** */
/* ********************************************************************************* */
 
