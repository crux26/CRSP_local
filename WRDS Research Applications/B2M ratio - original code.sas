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
/*                 Minority Interest (MIB) + Stockholders? Equity (SEQ)        */
/* *************************************************************************** */
  
/* Calculating Market-to-Book using Compustat only                             */
/* Advantage: captures many firms that are in Compustat, but not in CRSP       */
%let bdate=01jan1962; %let edate=31dec2010; 
%let comp=comp;  
%let crsp=crsp; 
/* Standard Compustat Filter*/
%let comp_filter=consol='C' and indfmt='INDL' and datafmt='STD' and popsrc='D'; 
%let ind=10; *number of FF industries for which to compute median M/B ratio;
  
/* Step 1. Create Book Equity (BE) measure                                     */
/* CSHO is a company level item and includes all classes of common stock       */
/* prcc_c is the price as of Dec of the FISCAL year. So, for instance, if a    */
/* company's fiscal year end falls b/w jan and may 1990, then prcc_c will be   */
/* the Dec end price as of Dec 1989. However, if the fiscal year end falls b/w */
/* june and dec 1990, then prcc_c will be the price as of Dec 1990             */
  
data comp_extract/view=comp_extract; set &comp..funda; 
   where (at>0 or not missing(sale)) and &comp_filter and fic='USA'; 
   calyear=year(datadate); 
   mcap_c=prcc_c*csho; /*Market Value of Equity at Dec end of fiscal year t  */	
   /*to obtain shareholders equity, use stockholders equity, if not missing  */
   if not missing(SEQ) then SHE=SEQ;else
   /*if SEQ missing, use Total Common Equity plus Preferred Stock Par Value  */
   if nmiss(CEQ,PSTK)=0 then SHE=CEQ+PSTK;else
   /*if CEQ or PSTK is missing, use                                          */
   /*Total Assets-(Total Liabilities+Minority Interest), if all exist        */
   if nmiss(AT,LT)=0 then SHE=AT-sum(LT,MIB); 
   else SHE=.; 
  /*to obtain book equity,subtract from the shareholders' equity the preferred*/ 
  /*stock value,using redemption,liquididating or carrying value in that order*/
   /*if available*/ 
   PS = coalesce(PSTKRV,PSTKL,PSTK,0); 
   BE0 = SHE-PS; 
   /* Accounting data since calendar year 't-1'*/
   if year("&bdate"d) - 1<=calyear<=year("&edate"d) + 1; 
   keep gvkey calyear fyr fyear BE0 indfmt consol mcap_c sich  
        datafmt popsrc datadate TXDITC prcc_f prcc_c curcd; 
run; 
  
/* Finally, if not missing, add balance sheet deferred taxes and */
/* subtract off the FASB106 adjustment                           */
proc sql; create table comp_be 
as select  
  a.gvkey, a.calyear, a.fyr, a.datadate, a.fyear, a.mcap_c, 
  a.prcc_f, a.prcc_c, sum(a.BE0,a.TXDITC,-b.PRBA) as BE,a.curcd, a.sich 
from comp_extract a left join  
     &comp..aco_pnfnda (where=(&comp_filter)) b 
on a.gvkey=b.gvkey and a.datadate=b.datadate; 
quit; 
  
/* Step 2: calculate the market value as of Dec end                 */
/* Curcdm is the currency in which the monthly prices are available */
/* Primiss='P' is the primary issue with the highest average trading*/
/* volume over a period of time                                     */
data mvalue/view=mvalue; set &comp..secm; 
  where month(datadate)=12 and primiss='P' and fic='USA'
  and "&bdate"d<=datadate<="&edate"d; 
  mcap_dec=prccm*cshoq; 
  rename prccm=prc_dec; 
  keep gvkey datadate prccm curcdm mcap_dec; 
run; 
  
/* Step 3a. Create Book to Market (BM) ratios using Compustat only   */
/* This step is needed, because sometimes PRCC_C or CSHO is missing  */
/* in Compustat Fundamentals Annual dataset, so bring December market*/
/* value calculated from Compustat Security file                     */
/* BE- book equity reported in fiscal year t                         */
/* MCAP - market equity as of Dec of fiscal year t if available      */
/* Coalesce function returns the first non-missing value for the M/B */
/* the order of the listed arguments                                 */
/* MB_COMP contains the M/B ratios for the entire Compustat Universe */
proc sql; create table mb_comp 
as select a.gvkey, a.datadate format date9., a.calyear, a.fyear,  
          a.prcc_f, a.prcc_c,b.prc_dec, a.curcd, a.sich, 
          a.be, a.mcap_c, b.mcap_dec, mdy(12,31,a.fyear) as fyear_end,  
          coalesce(mcap_c/((be>0)*be),mcap_dec/((be>0)*be)) as mb_comp 
from comp_be a left join mvalue b 
on a.gvkey=b.gvkey and a.fyear=year(b.datadate) and a.curcd=b.curcdm 
order by a.gvkey, a.datadate; 
quit; 
  
/* Step 3b. Alternatively, one can use Market value from CRSP as of  */ 
/* Dec end of fiscal year. Note that this will restrict the sample   */
/* to CRSP stocks only                                               */
/* Select Compustat's SICH as primary SIC code, if not available     */
/* then use CRSP's historical SICCD	                                 */
proc sql; create table mb_comp_crsp 
  as select a.*, b.lpermno as permno, b.lpermco as permco,  
          abs(c.prc*c.shrout)/(1000*(a.be>0)*a.be) as mb_crsp,  
          coalesce(a.sich,d.siccd) as sic 
   from mb_comp a left join &crsp..ccmxpf_linktable b 
   on a.gvkey=b.gvkey and b.linkdt<=a.datadate and b.usedflag=1
   and linkprim in ('P','C')  
   and (a.datadate<=b.linkenddt or missing(b.linkenddt))  
  
  /* market value from CRSP as the Dec end of fiscal year end*/
  left join &crsp..msf (keep=permno date prc shrout) c 
  on b.lpermno=c.permno and put(a.fyear_end,yymmn6.)=put(c.date,yymmn6.) 
  /*Merge in historical SIC code from CRSP*/
  left join (select distinct permno, siccd, min(namedt) as mindate,  
          max(nameenddt) as maxdate 
          from &crsp..stocknames group by permno, siccd) d 
  on b.lpermno=d.permno and d.mindate<=a.fyear_end<=d.maxdate
  order by a.gvkey, a.datadate, sic; 
quit; 

/* Step 4. Invoke FF industry classification                  */
/* MB_COMP_CRSP contains M/B ratios based on "Compustat only" */
/* and CRSP-Compustat Merged database                         */
data mb_comp_crsp; set mb_comp_crsp;
 by gvkey datadate;
 if last.datadate; /*selects the record with non-zero SIC code*/
  %ffi&ind(sic); 
run; 
  
/*trimming extreme values of Market-To-Book within industries*/
proc sort data=mb_comp_crsp; 
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
  from mb_comp_crsp where not missing(mb_comp)  and curcd='USD'
  group by calyear, ffi&ind._desc; 
   
  create table mbcrsp 
  as select distinct calyear,ffi&ind._desc,  
            count(distinct permco) as npermnos 
  from mb_comp_crsp where not missing(mb_crsp)  and curcd='USD'
  group by calyear, ffi&ind._desc; 
quit; 
data comparembcov;  
  merge mbcomp mbcrsp; 
    by calyear ffi&ind._desc; 
    diff=(ngvkeys-npermnos)/npermnos; 
    format diff percent7.4; 
    if 1980<=calyear<=2010; 
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
  where 1970<=calyear<=2010;  
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
 
