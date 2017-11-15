/*SPXOpprcd_Merge -> SPXData_Merge -> SPXCallPut_Merge -> SPXData_Trim -> SPXData_Export */
/*This code will make SPXCall, SPXPut datasets by merging annual datasets*/
%let head = optionm.Opprcd;
/*For year=2016, only up to April exists.*/
data myOption.SPXCall myOption.SPXPut;
set  &head.1996 &head.1997 &head.1998 &head.1999 &head.2000 &head.2001 &head.2002 &head.2003 &head.2004 &head.2005 &head.2006
 &head.2007 &head.2008 &head.2009 &head.2010 &head.2011 &head.2012 &head.2013 &head.2014 &head.2015;
/*Standard option: AM-settled*/
/*PM-settled standard: secid=150513 prior to May 1, 2017*/
where secid = 108105;
keep secid date symbol exdate strike_price best_bid best_offer volume open_interest impl_volatility delta gamma vega theta cp_flag ss_flag;
if cp_flag = "C" then output myOption.SPXCall;
if cp_flag = "P" then output myOption.SPXPut;
run;

/*Meaningless renaming below is to make it consistent to other files.*/

data SPXCall_mnth; set myOption.SPXCall; 
run;

/**/
/*Put*/
/**/

data SPXPut_mnth; set myOption.SPXPut;
run;

/**/

proc sort data=spxcall_mnth;
by date exdate strike_price;
run;

proc sort data=spxput_mnth;
by date exdate strike_price;
run;


