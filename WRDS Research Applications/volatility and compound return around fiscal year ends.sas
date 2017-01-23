
/* ********************************************************************************* */
/* ************** W R D S   R E S E A R C H   A P P L I C A T I O N S ************** */
/* ********************************************************************************* */
/* Summary   : Stock Volatility & Compound Returns around Fiscal Period Ends         */
/* Date      : August 24, 2011                                                       */
/* Author    : Rabih Moussawi                                                        */
/* Details   : - Inputs are CRSP Monthly File and Compustat Data with FPE Dates      */
/*             - Linking CRSP and Compustat using CCM or using CUSIP                 */
/*             - 3, 6, 9, and 12-Month Trailing Compound Returns are computed for    */
/*                      Stocks and for the Market Index                              */
/*             - Adds Cumulative Returns for the 3 Months after Fiscal Period End    */
/*             - Adds Cumulative Returns for the 3 Months after (FPE + 90 days),     */
/*                 after annual reports are filed with the SEC                       */
/*             - Computes 24-Month Total Stock Volatility, and Book Value of Equity  */
/* ********************************************************************************* */
 
/* Set the Date Range */
%let BEGDATE=01JAN1990;
%let ENDDATE=31DEC2002;
 
/* Step1. Extract Compustat Sample */
data comp1;
set comp.funda;
where datadate between "&BEGDATE"d and "&ENDDATE"d
 and DATAFMT='STD' and INDFMT='INDL' and CONSOL='C' and POPSRC='D';
/* Use Daniel and Titman (JF 1997) Book of Equity Calculation: */
if SEQ>0; /* Keep Companies with Existing Shareholders' Equity */
/* PSTKRV: Preferred stock Redemption Value . If missing, use PSTKL: Liquidating Value */
/* If still missing, then use PSTK: Preferred stock - Carrying Value, Stock (Capital)  */
PREF = coalesce(PSTKRV,PSTKL,PSTK);
/* BE = Stockholders Equity + Deferred Taxes + investment Tax Credit - Preferred Stock */
BE = sum(SEQ, TXDB, ITCB, -PREF);
label datadate = "Fiscal Year End Date";
label BE = "Book Value of Equity";
keep GVKEY conm datadate fyear fyr at ni sale be;
run;
 
/* Step2. Add Historical CRSP PERMCO Identifier */
/* Use Primary Issue Identifier LinkScore='P' to Resolve Duplicate Links */
/* When LinkPrim 'P' is not available, choose 'C' links over 'N' or 'J' links */
proc sql;
  create table comp2 (drop=LinkScore)
  as select distinct a.*, b.lpermco as permco,
   case
    when b.linkprim='P' then 2 when b.linkprim='C' then 1 else 0
   end as LinkScore
  from comp1 as a, crsp.ccmxpf_linktable as b
  where a.gvkey = b.gvkey and
  b.LINKTYPE in ("LU","LC") and
 (b.LINKDT <= a.datadate) and (a.datadate <= b.LINKENDDT or missing(b.LINKENDDT))
group by a.gvkey, a.datadate
having LinkScore=max(LinkScore);
quit;
proc sort data=comp2 nodupkey; by gvkey datadate; run;
 
/* Alternative Step2. Use CUSIP to Map PERMCO and GVKEY */
/* if CCM Product is not to be used, then run the following step */
proc sql;
  create table comp2_alternative
  as select distinct a.*, b.permco as permco
  from comp1 as a,
   (select distinct gvkey, permco
    from comp.security as a, crsp.msenames as b
    where not missing(b.NCUSIP) and substr(a.CUSIP,1,8)=b.NCUSIP) as b
  where a.gvkey = b.gvkey;
quit;
proc sort data=comp2_alternative nodupkey; by gvkey datadate; run;
 
/* Step3. Get CRSP Monthly Stock Data and Add Market Return */
/* Keep Only Common Stocks, using Historical Share Code Identifier */
/* Extract Stock Return Information, and Adjust Prices and Shares Outstanding */
proc sql;
create table crsp1
as select a.permco, a.permno, a.date, a.ret, abs(prc)/cfacpr as P, shrout*cfacshr*1000 as TSO
from crsp.msf as a, crsp.msenames as b
where a.date between intnx("month","&BEGDATE"d,-12,'b') and "&ENDDATE"d and a.permno=b.permno
  and b.namedt<=a.date<=b.nameendt and b.shrcd in (10,11)
order by permno, date;
quit;
 
/* Step4. Add Value-Weighted CRSP Market Return Index: VWRETD Variable */
/* Use this step to fill the gaps of missing monthly observations in CRSP */
/* PROC EXPAND requires a return time series with continuous date intervals */
proc sql;
create table msi
as select b.permno, a.date, a.vwretd
from crsp.msi as a,
 (select permno, min(date) as date1, max(date) as date2
   from crsp1 group by permno) as b
where a.date between b.date1 and b.date2;
/* Add Delisting Return Information */
create table msi_dlret
as select a.*, c.dlret
from msi as a left join crsp.msedelist as c
on  a.permno=c.permno
   and intnx("month",a.date,0,"e")=intnx("month",c.dlstdt,0,"e")
order by permno, date;
quit;
 
/* Step5. Calculate Total Return measure after incorporating Delisting Return */
data crsp2;
merge crsp1 (in=a) msi_dlret;
by permno date;
/* Add delisting return to month end return */
if not missing(dlret) then ret=sum(1,ret)*(1+dlret)-1;
/* Calulate Total Market Capitalization */
ME=P*TSO/1000000;
/* align trading date to month end date */
date = intnx("month",date,0,'e');
label P = "Price at Period End, Adjusted";
label TSO = "Total Shares Outstanding, Adjusted";
label ME = "Total Market Capitalization, in $mil";
rename VWRETD=RM; label ret=" " VWRETD=" "; drop dlret;
format RET VWRETD percentn8.2 TSO comma12. P ME dollar12.2;
run;
 
proc sort data=crsp2 nodupkey; by permno date; run;
 
/* Step 5. Calculate 3, 6, 9, and 12 Month compound Returns for Stock and Market */
/* Calculate Total Stock Volatility Measure */
/* to avoid cluttering in log window, proc printto is used to export log output  */
proc printto log = junk; run;
proc expand data = crsp2 out=crsp3 method=none;
    by permno;
    id date;
    convert RET = RET_3  / transformin=(+1) transformout=(MOVPROD  3 -1 trimleft  3); /*ex) [3%,2%,5%] -> 1.03*1.02*1.05 = 1.10 -> 10% through transformin/out */
    convert RET = RET_6  / transformin=(+1) transformout=(MOVPROD  6 -1 trimleft  6);
    convert RET = RET_9  / transformin=(+1) transformout=(MOVPROD  9 -1 trimleft  9);
    convert RET = RET_12 / transformin=(+1) transformout=(MOVPROD 12 -1 trimleft 12);
    convert RM  = RM_3   / transformin=(+1) transformout=(MOVPROD  3 -1 trimleft  3);
    convert RM  = RM_6   / transformin=(+1) transformout=(MOVPROD  6 -1 trimleft  6);
    convert RM  = RM_9   / transformin=(+1) transformout=(MOVPROD  9 -1 trimleft  9);
    convert RM  = RM_12  / transformin=(+1) transformout=(MOVPROD 12 -1 trimleft 12);
    convert RET = Tot_Vol / transformout = (movstd 24 trimleft 24);
quit;
proc printto; run;
 
/* Step 6. Add Cumulative Returns to Compustat Data at Fiscal Period End */
proc sort data=crsp3; by permco date permno; run;
proc sort data=comp2; by permco datadate; run;
 
data FPE_Ret1;
merge comp2(in=a) crsp3(in=b rename=date=datadate);
by permco datadate;
if a and b;
label RET    = "Stock Return of Last Month of Fiscal Period";
label RET_3  = "Stock Return of Last 3 Months of Fiscal Period";
label RET_6  = "Stock Return of Last 6 Months of Fiscal Period";
label RET_9  = "Stock Return of Last 9 Months of Fiscal Period";
label RET_12 = "Stock Return of Last 12 Months of Fiscal Period";
label RM    = "Market Return of Last Month of Fiscal Period";
label RM_3  = "Market Return of Last 3 Months of Fiscal Period";
label RM_6  = "Market Return of Last 6 Months of Fiscal Period";
label RM_9  = "Market Return of Last 9 Months of Fiscal Period";
label RM_12 = "Market Return of Last 12 Months of Fiscal Period";
label Tot_Vol  = "Total Stock Return Volatility in the Last 24 Months";
run;
 
proc sort data=FPE_Ret1 nodupkey; by permno datadate; run;
 
/* Step 7. Add 3 Month Returns After Fiscal Period End */
proc sql;
create view FPE_Ret2
as select a.*, b.RET_3 as RET3 "Stock Forward 3-month Return, after FPE",
               b.RM_3  as RM3 "Market Forward 3-month Return, after FPE"
from FPE_Ret1 as a left join crsp3 as b
on a.permno=b.permno and intnx("month",a.datadate,3,"e")=b.date;
create table FPE_Ret3
as select a.*, b.RET_3 as RET3_90 "Stock Forward 3-month Return, after FPE+90 days",
               b.RM_3  as RM3_90 "Market Forward 3-month Return, after FPE+90 days"
from FPE_Ret2 as a left join crsp3 as b
on a.permno=b.permno and intnx("month",a.datadate+90,3,"e")=b.date
order by permno, datadate;
quit;
 
/* END */
 
/* ********************************************************************************* */
/* *************  Material Copyright Wharton Research Data Services  *************** */
/* ****************************** All Rights Reserved ****************************** */
/* ********************************************************************************* */
