/*Checking done! (2017.06.07) */
/*No 1W skip between formation and holding period as in Jegadessh, Titman (1993) */

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
/* Form portfolio using the past (&J)M cumulative return */
%let K=6; /* Holding   Period Length: K can be between 3 to 12 months */
 
/* Jegadeesh and Titman's Footnote 4 page 69: 1965-1989 are holding period dates */
/* Need 2 years of return history to form mometum portfolios that start in 1965  */
%let begdate=01JAN1983;
%let enddate=31DEC1989;
 
/* Step 2. Extract CRSP Data for NYSE and AMEX Common Stocks */
/* Merge historical codes with CRSP Monthly Stock File       */
/* Restriction on Share Code: common shares only  (shrcd in (10,11) ) */
/*      and Exchange Code: NYSE and AMEX securities only ( exchcd in (1,2) )  */
%let filtr = (shrcd in (10,11) and exchcd in (1,2));
/*  Selected variables from the CRSP Monthly Stock File (a_stock.msf)     */
%let fvars =  prc ret shrout cfacpr cfacshr;
/*  Selected variables from the CRSP Monthly Event File (a_stock.mse)     */
%let evars =  shrcd exchcd siccd;
/* Invoke CRSPMERGE WRDS Research Macro. Data Output: CRSP_M */
/*If there's GLOBAL variable s, then "crsp_&s." will denote GLOBAL variable s, not s of "s=m", which is LOCAL */
%crspmerge(s=m,start=&begdate,end=&enddate,sfvars=&fvars,sevars=&evars,filters=&filtr, outset=crsp_&s.);
/*%crspmerge() merges SFVARS from msf, SEVARS from mseall */
/*%crspmerge() returns month-end date*/
 
/* Step 3. Create Momentum Port. Measures Based on Past (J) Month Compounded Returns */
/* Make sure to keep stocks with available return info in the formation period */
proc printto log=junk;
proc expand data=crsp_m (keep=permno date ret) out=umd method=none;
by permno;
id date;
/*CONVERT variable = newname */
convert ret = cum_return / transformin=(+1) transformout=(MOVPROD &J -1 trimleft &J);
/*TRANSFORMIN= : TRANSFORM=, TIN=.*/
/*transformin=(+1): cum_return + 1, to make it gross return */
/* MOVPROD &J : Backward moving product with window size &J */
/*MOVPROD &J -1: Set gross return back to (net) return */
/* trimleft &J: sets x_t to missing if t <= &J */
/* That is, first &J observations will be treated as missing */
quit;
proc printto; run;
 
/* Formation of 10 Momentum Portfolios Every Month */
proc sort data=umd; by date; run;
proc rank data=umd out=umd group=10;
  by date;
    var cum_return;
/*If cum_return=. then its rank is missing*/
    ranks momr;
/*RANKS: Identify a variable to which the ranks are assigned*/
run;
 
/* Step 4. Assign Ranks to the Next 6 (&K) Months After Portfolio Formation */
/* MOMR is the portfolio rank variable taking values between 1 and 10: */
/*          1 - the lowest  momentum group: Losers   */
/*         10 - the highest momentum group: Winners  */
data umd;
set umd; * (drop=cum_return); *<-- Not dropping cum_return would be better, for future checking purpose;
where momr>=0;
momr=momr+1; * to make it gross return from net return;
HDATE1 = intnx("MONTH",date, 1,"B"); 		* "B": Beginning of the interval --> 1M (in fact, 1 weekend later at most) later than date, month-beginning ;
HDATE2 = intnx("MONTH",date,&K,"E");		* "E": End of the interval* --> (&K)M later than date, month-end ;
label momr = "Momentum Portfolio";
label date = "Formation Date";
label HDATE1= "First Holding Date";
/*As %crspmerge() returns month-end date, HDATE is at most 1 weekend later (or 1D at least) from the formation date */
label HDATE2= "Last Holding Date";
rename date=form_date;
run;
 
proc sort data=umd nodupkey; by permno form_date; run;
/*NODUPKEY: checks for and eliminates observations with duplicate BY values. */
/* PROC SORT compares all BY values for each observation to the ones */
/* for the previous observation that is written to the output data set */
 
/* Portfolio returns are average monthly returns rebalanced monthly */
proc sql;
    create table umd2
    as select distinct a.momr, a.form_date, a.permno, b.date, b.ret
/*To track the portfolio's return series from form_date up to (form_date + &K) */
    from umd as a, crsp_m as b
    where a.permno=b.permno
    and a.HDATE1<=b.date<=a.HDATE2;
quit;
 
/* Step 5. Calculate Equally-Weighted Average Monthly Returns */
proc sort data=umd2 nodupkey; by date momr form_date permno; run;

/* Calculate Equally-Weighted returns across portfolio stocks */
/* Every date, each MOM group has J number of portfolios identified by formation date */
proc means data = umd2 noprint;
  by date momr form_date;
    var ret;
    output out = umd3 mean=ret;
/*"ret" is now average return over momr on given (date,form_date) pair*/
run;
 
/* Portfolio average monthly returns */
proc sort data=umd3; by date momr;
    where year(date) >= year("&begdate"d)+2;
run;
/* Jegadeesh and Titman's Footnote 4 page 69: 1965-1989 are holding period dates */
/* Need 2 years of return history to form mometum portfolios that start in 1965  */
 
/* Create one return series per MOM group every month */
proc means data = umd3 noprint;
  by date momr;
    var ret;
    output out = ewretdat mean= ewret std = ewretstd;
run;
/* At given date, there're &K number of portfolios formed at &K different months */
/* By averaging these &K portfolios, one can obtain one momentum portfolio at each date */
 
proc sort data=ewretdat; by momr ; run;
 
Title "Jegadeesh and Titman (1993) Table 1: Returns of Relative Strength Portfolios";
Title2 "Portfolios based on &J month lagged return and held for &K months";

/* Below refers to "Title" */
/* Time-series avg. of cross-sectional statistics of momentum PFs */
/* More precisely, pooled avg. of momentum PFs */
proc means data=ewretdat n mean t probt noprint;
output out=ewretdat_stat;
  class momr;
    var ewret;
/* Take avg. of ewret over momr, which is "pooled time-series, cross-sectional avg." */
run;
 
/* Step 6. Calculate Long-Short Portfolio Returns */
proc sort data=ewretdat; by date momr; run;

proc transpose data=ewretdat out=ewretdat2
     (rename = (_1=LOSERS _2=PORT2 _3=PORT3 _4=PORT4 _5=PORT5
                     _6=PORT6 _7=PORT7 _8=PORT8 _9=PORT9 _10=WINNERS)
       drop=_NAME_ _LABEL_);
  by date;
  id momr; *ID: variable/column "name";
  var ewret; *VAR: variable/column "value";
run;
 
/* Compute Long-Short Portfolio Cumulative Returns */
/* Not just &K-period cumulative return, but from &begdate to &enddate */
data ewretdat3;
set ewretdat2;
by DATE;
LONG_SHORT = WINNERS - LOSERS ;
retain CUMRET_WINNERS CUMRET_LOSERS CUMRET_LONG_SHORT 0; *3 new variables introduced;
CUMRET_WINNERS     = (CUMRET_WINNERS+1)*(WINNERS+1)-1;
CUMRET_LOSERS      = (CUMRET_LOSERS +1)*(LOSERS +1)-1;
CUMRET_LONG_SHORT  = (CUMRET_LONG_SHORT+1)*(LONG_SHORT+1)-1;
format WINNERS LOSERS LONG_SHORT PORT: CUMRET_: percentn12.2;
run;

/* Below refers to "Title2" */
/* WINNERS, LOSERS are just renaming of the results from "ewretdat_stat" */
/* New in this table is LONG_SHORT, which is a spared between WINNERS & LOSERS */
proc means data=ewretdat3 n mean t probt noprint;
output out=ewretdat3_stat;
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
run;
quit;
 
/* ********************************************************************************* */
/* *************  Material Copyright Wharton Research Data Services  *************** */
/* ****************************** All Rights Reserved ****************************** */
/* ********************************************************************************* */
