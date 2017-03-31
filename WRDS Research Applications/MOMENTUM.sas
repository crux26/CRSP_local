/* ********************************************************************************* */
/* ************** W R D S   R E S E A R C H   A P P L I C A T I O N S ************** */
/* ********************************************************************************* */
/* Summary   : Replicates Jegadeesh and Titman (JF, 1993) Momentum Portfolios        */
/* Date      : November 2004. Modified January, 2011                                 */
/* Author    : Gjergji Cici and Rabih Moussawi, WRDS                                 */
/* Variables : - J: # of Months in Formation Period to Create Momentum Portfolios    */
/*             - K: # of Months in Holding   Period to Buy and Hold Mom. Ports.      */
/*             - BEGDATE: Sample Start Date                                          */
/*             - ENDDATE: Sample End Date                                            */
/* ********************************************************************************* */
 
/* Step 1. Specifying Options */
%let J=6; /* Formation Period Length: J can be between 3 to 12 months */
%let K=6; /* Holding   Period Length: K can be between 3 to 12 months */
 
/* Jegadeesh and Titman's Footnote 4 page 69: 1965-1989 are holding period dates */
/* Need 2 years of return history to form mometum portfolios that start in 1965  */
%let begdate=01JAN1963;
%let enddate=31DEC1989;
 
/* Step 2. Extract CRSP Data for NYSE and AMEX Common Stocks */
/* Merge historical codes with CRSP Monthly Stock File       */
/* Restriction on Share Code: common shares only             */
/*      and Exchange Code: NYSE and AMEX securities only     */
%let filtr = (shrcd in (10,11) and exchcd in (1,2));
/*  Selected variables from the CRSP Monthly Stock File      */
%let fvars =  prc ret shrout cfacpr cfacshr;
/*  Selected variables from the CRSP Monthly Event File      */
%let evars =  shrcd exchcd siccd;
/* Invoke CRSPMERGE WRDS Research Macro. Data Output: CRSP_M */
%crspmerge(s=m,start=&begdate,end=&enddate,sfvars=&fvars,sevars=&evars,filters=&filtr);
 
/* Step 3. Create Momentum Port. Measures Based on Past (J) Month Compounded Returns */
/* Make sure to keep stocks with available return info in the formation period */
proc printto log=junk;
proc expand data=crsp_m (keep=permno date ret) out=umd method=none;
by permno;
id date;
convert ret = cum_return / transformin=(+1) transformout=(MOVPROD &J -1 trimleft &J);
quit;
proc printto; run;
 
/* Formation of 10 Momentum Portfolios Every Month */
proc sort data=umd; by date; run;
proc rank data=umd out=umd group=10;
  by date;
    var cum_return;
    ranks momr;
run;
 
/* Step 4. Assign Ranks to the Next 6 (K) Months After Portfolio Formation */
/* MOMR is the portfolio rank variable taking values between 1 and 10: */
/*          1 - the lowest  momentum group: Losers   */
/*         10 - the highest momentum group: Winners  */
data umd;
set umd (drop=cum_return);
where momr>=0;
momr=momr+1;
HDATE1 = intnx("MONTH",date, 1,"B");
HDATE2 = intnx("MONTH",date,&K,"E");
label momr = "Momentum Portfolio";
label date = "Formation Date";
label HDATE1= "First Holding Date";
label HDATE2= "Last Holding Date";
rename date=form_date;
run;
 
proc sort data=umd nodupkey; by permno form_date; run;
 
/* Portfolio returns are average monthly returns rebalanced monthly */
proc sql;
    create table umd2
    as select distinct a.momr, a.form_date, a.permno, b.date, b.ret
    from umd as a, crsp_m as b
    where a.permno=b.permno
    and a.HDATE1<=b.date<=a.HDATE2;
quit;
 
/* Step 5. Calculate Equally-Weighted Average Monthly Returns */
proc sort data=umd2 nodupkey; by date momr form_date permno; run;
 
/* Calculate Equally-Weighted returns across portfolio stocks */
/* Every date, each MOM group has J portfolios identified by formation date */
proc means data = umd2 noprint;
  by date momr form_date;
    var ret;
    output out = umd3 mean=ret;
run;
 
/* Portfolio average monthly returns */
proc sort data=umd3; by date momr;
    where year(date) >= year("&begdate"d)+2;
run;
 
/* Create one return series per MOM group every month */
proc means data = umd3 noprint;
  by date momr;
    var ret;
    output out = ewretdat mean= ewret std = ewretstd;
run;
 
proc sort data=ewretdat; by momr ; run;
 
Title "Jegadeesh and Titman (1993) Table 1: Returns of Relative Strength Portfolios";
Title2 "Portfolios based on &J month lagged return and held for &K months";
 
proc means data=ewretdat n mean t probt;
  class momr;
    var ewret;
run;
 
/* Step 6. Calculate Long-Short Portfolio Returns */
proc sort data=ewretdat; by date momr; run;
proc transpose data=ewretdat out=ewretdat2
     (rename = (_1=LOSERS _2=PORT2 _3=PORT3 _4=PORT4 _5=PORT5
                     _6=PORT6 _7=PORT7 _8=PORT8 _9=PORT9 _10=WINNERS)
       drop=_NAME_ _LABEL_);
  by date;
  id momr;
   var ewret;
run;
 
/* Compute Long-Short Portfolio Cumulative Returns */
data ewretdat3;
set ewretdat2;
by DATE;
LONG_SHORT=WINNERS-LOSERS;
retain CUMRET_WINNERS CUMRET_LOSERS CUMRET_LONG_SHORT 0;
CUMRET_WINNERS     = (CUMRET_WINNERS+1)*(WINNERS+1)-1;
CUMRET_LOSERS      = (CUMRET_LOSERS +1)*(LOSERS +1)-1;
CUMRET_LONG_SHORT  = (CUMRET_LONG_SHORT+1)*(LONG_SHORT+1)-1;
format WINNERS LOSERS LONG_SHORT PORT: CUMRET_: percentn12.1;
run;
 
proc means data=ewretdat3 n mean t probt;
var WINNERS LOSERS LONG_SHORT;
run;
 
/* Step 7. Plot Time Series of Portfolio Returns */
axis1 label=none;
symbol interpol =join w = 4;
proc gplot data = ewretdat3;
   Title 'Time Series of Cumulative Momentum Portfolio Returns' ;
   Title2 "Based on Jegadeesh and Titman (1993) Momentum Portfolios " ;
   plot (CUMRET_WINNERS CUMRET_LOSERS)*date
        / overlay legend vaxis=axis1;
   format date year.;
run; quit;
 
proc gplot data = ewretdat3;
   Title 'Performance of Long/Short Momentum Strategy' ;
   Title2 "Based on Jegadeesh and Titman (1993) Momentum Portfolios";
   plot (CUMRET_LONG_SHORT)*date
        / overlay legend vaxis=axis1;
   format date year.;
run; quit;
 
/* ********************************************************************************* */
/* *************  Material Copyright Wharton Research Data Services  *************** */
/* ****************************** All Rights Reserved ****************************** */
/* ********************************************************************************* */
