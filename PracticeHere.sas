/* Currently working on <indadjbm to portfolios>. */
/* # of result firms from <B2M ratio - DT> are too small compared to <B2M ratio - FF>. */

/* WARNING: in PROC SORT, NODUPKEY and NODUPLICATES are DIFFERENT. */
/* NODUPLICATES: delete duplicated observations (records identical to each other). */
/* NODUPKEY: delete observations with duplicate BY values (the sort BY variables). */


/* After that, re-check FF factors replication.sas, and find a way to form portfolio returns */
/* using indadjbm (industry-adjusted B2M). (2017.08.28) */

/*COMPUSTAT: NO MORE /d_na, but /naa (use /nam instead)*/

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
libname BEM "D:\Dropbox\GitHub\CRSP_local\Bali, Engle, Murray - replications";
libname ff_repl "D:\Dropbox\WRDS\CRSP\ff_repl";


/* To automatically point to the macros in this library within your SAS program */
options sasautos=('D:\Dropbox\GitHub\CRSP_local\myMacro\', SASAUTOS) MAUTOSOURCE;


%CRSPMERGE (s=m,START=01JAN2007,END=31DEC2016, OUTSET=crsp_&s.);
