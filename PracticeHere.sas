/*%include myMacro('SetDate.sas'); WILL NOT work unless */
/*-SASINITIALFOLDER "D:\Dropbox\GitHub\CRSP_local" added to sasv9.cfg in ...\nls\en and \ko*/
libname a_index "D:\Dropbox\WRDS\CRSP\sasdata\a_indexes";
libname a_stock "D:\Dropbox\WRDS\CRSP\sasdata\a_stock";
libname a_treas "D:\Dropbox\WRDS\CRSP\sasdata\a_treasuries";
libname ff "D:\Dropbox\WRDS\ff\sasdata";
libname mysas "D:\Dropbox\WRDS\CRSP\mysas";
libname myMacro "D:\Dropbox\GitHub\CRSP_local\myMacro";
libname optionm "\\Egy-labpc\WRDS\optionm\sasdata";

%let head = optionm.Opprcd;

data mysas.SPXCall;
set  &head.1996 &head.1997 &head.1998 &head.1999 &head.2000 &head.2001 &head.2002 &head.2003 &head.2004 &head.2005 &head.2006
 &head.2007 &head.2008 &head.2009 &head.2010 &head.2011 &head.2012;
where cp_flag = "C" & secid = 108105;
keep secid date exdate strike_price best_bid best_offer volume open_interest impl_volatility delta gamma vega theta cp_flag ss_flag;
run;

data mysas.SPXPut;
set  &head.1996 &head.1997 &head.1998 &head.1999 &head.2000 &head.2001 &head.2002 &head.2003 &head.2004 &head.2005 &head.2006
 &head.2007 &head.2008 &head.2009 &head.2010 &head.2011 &head.2012;
where cp_flag = "P" & secid = 108105;
keep secid date exdate strike_price best_bid best_offer volume open_interest impl_volatility delta gamma vega theta cp_flag ss_flag;
run;


proc sort data=mysas.spxcall_except9798;
by date exdate strike_price;
run;

proc sort data=mysas.spxput_except9798;
by date exdate descending strike_price;
run;

proc export data = spxcall_except9798
outfile = "C:\Users\EG.Y\Desktop\SPX_CallOnly.xls"
DBMS = EXCEL REPLACE;
SHEET = "SPX_Call secid=108105";
run;

proc export data = spxput_except9798
outfile = "C:\Users\EG.Y\Desktop\SPX_PutOnly.xls"
DBMS = EXCEL REPLACE;
SHEET = "SPX_Put secid=108105";
run;
