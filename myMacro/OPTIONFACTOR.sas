/*PROBLEM: _otm has too many duplicates. NOT SOLVED YET (2017.JUN.06)*/
/*Currently not working on this file as this is inefficient. Need to be improved for further use*/

/* OPTIONFACTOR: option's monthly return of ATMF or OTMF closest to ATM */
/* whose TTM is b/w [20D, 80D] ( intck('month',a.date,b.date)=1 ) */
/* Note that this is NOT the return on option's expiry, but before its expiry.*/
/* (opprc on first day of 1M later / opprc on first day of this month) - 1 */
/* So, option ret is calculated on month's first day, while expiry's third Friday/Saturday each month*/

/* Only retains the month's first trading day data. Hence, the result size(data) is */
/* 12 ( * #(#exdates w/i month. maxium of 5, which is a max # of Fridays w/i month) ) * #(data years). */
/*Example) date=01Feb2014, and Mar2015 have 5 Fridays. Then it will have 5 ATMs and 5 OTMs */
/* Only deals with SPX standard options.*/

/* Have to call macro 4 times to fully use the data: call/put ATM/OTM */

/***********************************************************************/
/*                                                                     */
/* Program: Option-Based Factors                                       */
/* Author : Luis Palacios, WRDS                                        */
/* Date   : 03/01/2010                                                 */
/* Revised   : 03/29/2010                                              */
/* Steps  :                                                            */
/*      - Get Daily option prices for all S&P500 options               */
/*      - S&P500 (SPX) secid in optionmetrics is 108105                */
/*      - Filters applied on 1st trading day of month                  */
/*      - Keep options expiring in the following month                 */
/*      - Keep only options with available prices                      */
/*      - Keep options with standard settlements                       */
/*                                                                     */
/* Notes on SPX Options:                                               */
/* - Expiration: Saturday Following the 3rd Friday of Expiration Month */
/* - Exercise Style: European exercisable on last bus day bef. exp.    */
/*                                                                     */
/* Example: %optionfactor(begyear=1996,endyear=2009,                   */
/*              flag=C,atm_otm=OTM,outfile=myfinalOTM);                */
/* ******************************************************************* */
   
   
/*id=108105: SPX options   */
%macro optionfactor
           (begyear=, endyear=, flag=, atm_otm=, outfile=, sp500_id=108105);
%let flag = %sysfunc(upcase(&flag));
%let atm_otm = %sysfunc(upcase(&atm_otm));
/*AFTER using upcase, it doesn't properly recognize the string.*/
/*MUST use %sysfunc(upcase()), not just upcase().*/
/*Alternatively, %upcase() can be used instead.*/


/* The DATA step below will merge opprcd files from &begyear to &endyear*/
/*Check why there's 2 semicolons after "%end" */
data a1;
set %do i=&begyear. %to &endyear. ; optionm.OPPRCD&i
  (keep = date secid exdate strike_price best_bid best_offer optionid
          exdate ss_flag cp_flag where = (secid=&sp500_id) ) %end; ;
month = month(date);
year = year(date) ;
/* Keep Options with Standard Settlment, i.e. 0 Special. Settl. Flag */
/* Drop all observations that doesn't meet the following if conditions */
if ss_flag='0' and cp_flag="&flag" and best_bid>0 and best_offer>0;
/* Mid-Price */
price = (best_bid + best_offer)/2;
/* Strike Price Adjustment */
strike=strike_price/1000;
/* Standard SPX option expire Saturday (weekday=7) following the third Friday of the expiration month */
/* It can be problematic if option data were to be matched with equity data, which does not trade at Saturday*/
/* Saturday expiries should be matched with equities' end-week day, Friday */
*if weekday(exdate)=7; * it eliminates non standard-date options (which has non-Saturday expiries);
/*if weekday(exdate)=6;*/
/*--> EXPIRES ON THURSDAY in 2002*/
/*--> EXPIRES ON FRIDAY in 2016*/
/*--> EXPIRES ON SATURDAY SOMETIMES in 2015*/
/*CBOE says SPX options are AM-settled on 3rd FRIDAY of every month*/
/*--> check for standard option through ss_flag=0*/

drop ss_flag cp_flag best_bid best_offer strike_price;
run;
   
/* Sort Dataset to Keep First Observation per Month */
proc sort data=a1 out=a1; by optionid year month date; run;
   
/* Use Data from the First Trading Day of the Month */
/*  Keep only Options that Expire in the Following Month */
/*BY statement in DATA step instructs to process dataset observations in groups, rather than singly*/
/*It can be used whenever SAS data is ORDERED*/
/*Here, if BY is not used, then "first.month" wouldn't make much sense*/
data a2; set a1;
by optionid year month date; /*By focusing on optionid, one can track historical trajectory of one specific option*/
if first.month; /*only keep options that appear the first w/i given month*/
if intck('month',date,exdate)=1; /*only keep options whose TTM is between around 20D and 80D*/
/*This is because standard SPX option's exdate is the THIRD SATURDAY, which is around 16th - 22nd*/
									 /*These would be most liquid options in general*/
run;
/*Dataset a2 will store at most one observation for each optionid due to*/
/*"first.month" and "intck('month,date,exdate)=1"*/
   
/* Get Price of the underlying index (S&P 500) */
/*The DATA step below will merge from &begyear to &endyear */
/* For underlying price retrieving only, may be better to use optionm.secprd instead of*/
/*crsp.msf or crsp.dsf because of consistency of the data vendor*/
data b1;
set %do i=&begyear %to &endyear %by 1;
    optionm.secprd&i (where = (secid=&sp500_id)) %end; ;
month = month(date);
year = year(date);
/* CLOSE is closing price at the end of the day */
keep date year month close secid;
run;
   
/* Sort Price Data */
proc sort data=b1 out=b1; by secid year month date; run;
   
/* Keep data on first day of the month */
data b2; set b1;
by secid year month date;
if first.month; /*Non-first day of the month data are discarded*/
run;

/* Add Risk-Free Rate for Present Value Calculation */
proc sql;
create table b3 as
select a.rf, b.*
from ff.factors_monthly as a, b2 as b
where a.year=b.year and a.month=b.month;
quit;
/*Same obs. # as b2, which is 12 * #(years) */
    
/* Merge Option data with price data to identify moneyness */
   
/* Discount Rate for Strike Price of options expiring at 'exdate' */
%let discount = (( 1 + b.rf) ** ( -(a.exdate-a.date)/30 )) ;
/*ABOVE "a. , b." works? --> NOT some value, but string to be used to simplify notation*/
 
/* Select option whose Strike Price PV is closest to current price */
/*That is, searching for ATMF strike starting from the current price*/
proc sql;
create table _list as
select a.date, a.secid, a.price, a.exdate, a.strike , b.close,
   a.optionid, a.strike*&discount - b.close as diff
from a2 as a, b3 as b
where a.date=b.date
group by a.date
having abs(diff)=min(abs(diff));
/* HAVING clause works w/ GROUP BY clause to RESTRICT the groups in a query's results based on a given condition*/
/* HAVING condition is applied after grouping the data and applying aggregate functions*/
quit;
/* In sum, _list will contain ATMF only at month's start date, */
/* so #(data) = 12 * #(data years) */
   
%if &atm_otm. = ATM %then %goto finalstep;
   
/* Next Step is for OTM options Exclusively */
   
%else %if &atm_otm. = OTM %then %do;
    %if &flag.=C %then %let sign = < ;
    %else %if &flag.=P %then %let sign = > ;
%end;

/*OTM: nearest-to-money */
proc sql undo_policy=none;
create table _list2 as
select b.*, ((a.close + abs(a.diff)) - b.strike) as diff2
from _list(keep=date strike close diff) as a, a2 as b
where a.date=b.date and
( a.close + abs(a.diff) ) &sign b.strike /* OTM PUT sign is positive, OTM CALL sign is negative */
and
a.strike &sign b.strike
group by a.date
having abs(diff2)=min(abs(diff2)) ; /* Retains min(abs(diff2)) only */
/*That is, OTM nearest-to-money (for both call, put)*/
quit;
   
/* Final Step bookmark */
%finalstep:
   
       %if &atm_otm. = ATM %then %let inputfile= _list ;
%else  %if &atm_otm. = OTM %then %let inputfile= _list2 ;
   
/* For selected options grab prices at the beg. of the next month */
   
/*Monthly return of ATMF (or OTMs) options, TTM b/w [20D,80D] with the nearest-to-maturity */
/*Hence, there exist only 1 data (for both ATM, OTM) each month */
proc sql;
	create table &outfile as
	select intnx('month',a.date,0,'end') as DATE format yymmddn8., /*set date to month's end*/
	(b.price/a.price)-1 as Factor_Ret "Option-Based Return Factor" format percentn8.2,
	"&flag" as flag, "&atm_otm" as money
	from &inputfile as a, a1 as b
	where a.optionid=b.optionid and intck('month',a.date,b.date)=1
/*i.e. month(b.date) = month(a.date)+1*/
/*Tracks the */
	group by a.date
	having b.date=min(b.date)
/*among month(b.date)=month(a.date)+1, choose the minimum b.date*/
	order by a.date ;
quit;
   
/* Data issue on Feb 2001:
Factor_ret is missing for CALL ATM and CALL OTM. Reason is that data for
ATM and OTM options selected at the beginning of Feb 2001 (and that expire on March 2001)
are missing in March 2001. Actually, the substantial decrease in the index made the value of the option
almost zero. See example of ATM optionid 20157245:
    secid        date      exdate   optionid   month   year    price   strike
   
   108105   01FEB2001   17MAR2001   20157245     2     2001   38.700    1380
   
   
   108105   28FEB2001   17MAR2001   20157245     2     2001    0.325    1380
   
No observations in March 2001 for these options. So the program can not calculate monthly returns.
We fill these missing returns for CALL ATM and CALL OTM to be -99%.  */
    
%if &flag=C %then %do;
   
    data &outfile;
      set &outfile;
      output &outfile;
       if month(date)=1 and year(date)=2001 then do;
          date='28Feb2001'd;
          Factor_Ret=-0.99;
          output &outfile;
       end;
     run;
   
%end;   
   
/* House Cleaning */
proc sql; drop table a1, a2, b1, b2, b3, _list; quit;
   
%mend optionfactor;
    
/* END */


/*   */
/*%optionfactor (begyear=1996,endyear=2016,flag=P,atm_otm=ATM,outfile=PUT_ATM,sp500_id=108105);*/
/*   */
/*proc print data= PUT_ATM; title 'PUT ATM final file'; run;*/
/*   */
/*%optionfactor (begyear=1996,endyear=2016,flag=P,atm_otm=OTM,outfile=PUT_OTM,sp500_id=108105);*/
/*   */
/*proc print data= PUT_OTM; title " PUT_OTM final file "; run;*/
/*   */
/*%optionfactor (begyear=1996,endyear=2016,flag=C,atm_otm=ATM,outfile=CALL_ATM,sp500_id=108105);*/
/*   */
/*proc print data= CALL_ATM; title 'CALL ATM final file'; run;*/
/*   */
/*%optionfactor (begyear=1996,endyear=2016,flag=C,atm_otm=OTM,outfile=CALL_OTM,sp500_id=108105);*/
/*   */
/*proc print data= CALL_OTM; title " CALL_OTM final file "; run;*/
/*   */
/*   */
/*   */
/*data myOption.OptionFactor_Ret;*/
/*merge*/
/*PUT_ATM  (rename=( Factor_Ret = ret_P_atm ))*/
/*PUT_OTM  (rename=( Factor_Ret = ret_P_otm ))*/
/*CALL_ATM (rename=( Factor_Ret = ret_C_atm ))*/
/*CALL_OTM (rename=( Factor_Ret = ret_C_otm ))*/
/*;*/
/*by date;*/
/*run;*/
/*   */
/*proc means data=mother2 mean std median skew kurtosis min max;*/
/*var*/
/*ret_C_atm*/
/*ret_P_atm*/
/*ret_C_otm*/
/*ret_P_otm*/
/*;*/
/*run;*/
