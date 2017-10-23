/*SPXOpprcd_Merge -> SPXData_Merge -> SPXCallPut_Merge -> SPXData_Trim -> SPXData_Export */
/*This code will make SPXCall, SPXPut datasets by merging annual datasets*/
libname a_index "D:\Dropbox\WRDS\CRSP\sasdata\a_indexes";
libname a_stock "D:\Dropbox\WRDS\CRSP\sasdata\a_stock";
libname a_treas "D:\Dropbox\WRDS\CRSP\sasdata\a_treasuries";
libname ff "D:\Dropbox\WRDS\ff\sasdata";
libname mysas "D:\Dropbox\WRDS\CRSP\mysas";
libname myOption "D:\Dropbox\WRDS\CRSP\myOption";
libname myMacro "D:\Dropbox\GitHub\CRSP_local\myMacro";
libname optionm "\\Egy-labpc\WRDS\optionm\sasdata";

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

/*It is NOT 3rd Saturday, but next day of 3rd Friday.*/
/*Note that these two can be different if the first day of the month is Saturday.*/
data tmpCall; set myOption.SPXCall;
month_exdate = month(exdate); year_exdate = year(exdate);
Fri3 = nwkdom(3, 6, month_exdate, year_exdate); Fri3Plus1 = nwkdom(3, 6, month_exdate, year_exdate)+1;
run;

data myOption.SPXCall_mnth; set tmpCall; where exdate=Fri3 or exdate=Fri3Plus1;
drop Fri3 Fri3Plus1 month_exdate year_exdate;
run;

/**/
/*Put*/
/**/

/*It is NOT 3rd Saturday, but next day of 3rd Friday.*/
/*Note that these two can be different if the first day of the month is Saturday.*/
data tmpPut; set myOption.SPXPut;
month_exdate = month(exdate); year_exdate = year(exdate);
Fri3 = nwkdom(3, 6, month_exdate, year_exdate); Fri3Plus1 = nwkdom(3, 6, month_exdate, year_exdate)+1;
run;

data myOption.SPXPut_mnth; set tmpPut; where exdate=Fri3 or exdate=Fri3Plus1;
drop Fri3 Fri3Plus1 month_exdate year_exdate;
run;

/**/

proc sort data=myOption.spxcall_mnth;
by date exdate strike_price;
run;

proc sort data=myOption.spxput_mnth;
by date exdate strike_price;
run;


