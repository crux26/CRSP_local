/* Currently working on FF factors replication */
/*COMPUSTAT: NO MORE /d_na, but /naa*/

/*a_ccm.ccmxpf_linktable: almost equivalent to a_ccm.ccmxpf_lnkhist */

/* The identification of a fiscal year is the calendar year in which it ends.*/
/* FY: from t-1, July to t, June prior to 1976.*/
/*ex) FY17: Oct, 2016 ~ Sep, 2017. */
/*ex) datadate=20080531, fyear=2007, fyr=5 --> Jun, 2006 ~ May, 2007 written at 20080531. */
/*ex) datadate=20090930, fyear=2009, fyr=9 --> Aug, 2008 ~ Sep, 2009 written at 20090930. */


/*%include myMacro('SetDate.sas'); WILL NOT work unless */
/*-SASINITIALFOLDER "D:\Dropbox\GitHub\CRSP_local" added to sasv9.cfg in ...\nls\en and \ko*/
libname a_index "D:\Dropbox\WRDS\CRSP\sasdata\a_indexes";
libname a_stock "D:\Dropbox\WRDS\CRSP\sasdata\a_stock";
libname a_ccm "D:\Dropbox\WRDS\CRSP\sasdata\a_ccm";
libname a_treas "D:\Dropbox\WRDS\CRSP\sasdata\a_treasuries";
libname comp "D:\Dropbox\WRDS\comp\sasdata\naa";
libname ff "D:\Dropbox\WRDS\ff\sasdata";
libname frb "D:\Dropbox\WRDS\frb\sasdata";
libname mysas "D:\Dropbox\WRDS\CRSP\mysas";
libname myMacro "D:\Dropbox\GitHub\CRSP_local\myMacro";
libname optionm "\\Egy-labpc\WRDS\optionm\sasdata";
libname myOption "D:\Dropbox\WRDS\CRSP\myOption";


%let bdate = '01Jan1962'd;
%let edate = '31Dec2016'd;
%let link = a_ccm.ccmxpf_linktable;

%include mymacro('size_bm.sas');
%size_bm(bdate=&bdate, edate=&edate);

proc sort data=crspm2;
by permco date;
run;

data mysas.msedelist; set a_stock.msedelist; run;

proc freq data = crspm2;
by permco;
run;
