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
data myOption.SPXCall;
set  &head.1996 &head.1997 &head.1998 &head.1999 &head.2000 &head.2001 &head.2002 &head.2003 &head.2004 &head.2005 &head.2006
 &head.2007 &head.2008 &head.2009 &head.2010 &head.2011 &head.2012 &head.2013 &head.2014 &head.2015;
if find(symbol, 'W') = 0 & find(symbol, 'PM')=0 & find(symbol, 'Q')=0 then output myOption.SPXCall; /*SPXW, Q: non-standard options */
/*Standard option: AM-settled*/
/*PM-settled standard: secid=150513 prior to May 1, 2017*/
where cp_flag = "C" & secid = 108105;
keep secid date symbol exdate strike_price best_bid best_offer volume open_interest impl_volatility delta gamma vega theta cp_flag ss_flag;
run;

data myOption.SPXPut;
set  &head.1996 &head.1997 &head.1998 &head.1999 &head.2000 &head.2001 &head.2002 &head.2003 &head.2004 &head.2005 &head.2006
 &head.2007 &head.2008 &head.2009 &head.2010 &head.2011 &head.2012 &head.2013 &head.2014 &head.2015;
if find(symbol, 'W') = 0 & find(symbol, 'PM')=0 & find(symbol, 'Q')=0 then output myOption.SPXPut; /*SPXW, Q: non-standard options */
/*Standard option: AM-settled*/
/*PM-settled standard: secid=150513 prior to May 1, 2017*/
where cp_flag = "P" & secid = 108105;
keep secid date symbol exdate strike_price best_bid best_offer volume open_interest impl_volatility delta gamma vega theta cp_flag ss_flag;
run;

proc sort data=myOption.spxcall;
by date exdate strike_price;
run;

proc sort data=myOption.spxput;
by date exdate strike_price;
run;
