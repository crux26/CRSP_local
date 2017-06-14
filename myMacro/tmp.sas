%macro tmp(begyear=2004, endyear=2004, flag=C, sp500_id = 108105);
%let flag = upcase(&flag);
/* The DATA step below will merge opprcd files from &begyear to &endyear*/
/*Check why there's 2 semicolons after "%end" */
data a1;
set 
	%do i=&begyear. %to &endyear. ; optionm.OPPRCD&i
		(keep = date secid exdate strike_price best_bid best_offer optionid
		exdate ss_flag cp_flag where = (secid=&sp500_id) ) %end; 
;
month = month(date);
year = year(date) ;
run;

data a2; set a1;
/* Keep Options with Standard Settlment, i.e. 0 Special. Settl. Flag */
/* Drop all observations that doesn't meet the following if conditions */
if ss_flag=0 and cp_flag="&flag" and best_bid>0 and best_offer>0;
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
/*drop ss_flag cp_flag best_bid best_offer strike_price;*/
run;

%mend tmp;
