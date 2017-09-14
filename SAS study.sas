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

data msf; set mysas.msf(keep=date permno permco prc ret vol); where permno < 10100; run;

/**/

proc sort data=msf; by permno date; run;

data firstandlastdates; set msf(keep=permno date); by permno;
retain firstdate;
date=intnx('month', date, 0, 'e');
if first.permno then firstdate=date;
if last.permno then do;
	lastdate=date;
	output;
end;
run;

data permnosrankdates(rename=(date=rankdate));
	set firstandlastdates;
	date=firstdate;
	do while(date<=lastdate);
	output;
/*		date=intnx('month', date+1, 1) -1;*/
		date=intnx('month', date, 1, 'e');
	end;
run;

data permnosrankdates2; set permnosrankdates;
date=rankdate;
i=1;
do while(i<=24);
	output;
	date=intnx('month', date, -1, 'e') ;
	i=i+1;
end;
run;
/**/

data ff; set ff.factors_monthly(keep=date rf smb hml umd mktrf);
date=intnx('month', date, 0, 'e');
run;

proc sort data=permnosrankdates2; by date permno; run;

data permnosrankdates3; merge permnosrankdates2(in=a) ff(in=b); by date; if a and b; run;

data msf_; set msf(keep=permno date ret);
where not(missing(ret));
date=intnx('month', date, 0, 'e');
run;

proc sort data=msf_; by date permno; run;

data permnosrankdates4; merge permnosrankdates3(in=a) msf_(in=b); by date permno; if a and b; run;

data permnosrankdates4; set permnosrankdates4; exret=ret-rf; run;

proc sort data=permnosrankdates4; by permno rankdate; run;

/**/
%let oldoptions=%sysfunc(getoption(mprint)) %sysfunc(getoption(notes)) %sysfunc(getoption(source));
%let errors=%sysfunc(getoption(errors));
options nonotes nomprint nosource errors=0;
proc printto log = junk; run;
/**/

proc reg data=permnosrankdates4 outest=est edf noprint; by permno rankdate;
model exret=mktrf smb hml umd;
run;

data est; set est; regobs= _p_ + _edf_; run;

/**/
options errors=&errors &oldoptions;
proc printto; run;
/**/

proc sql;
drop table ff, firstandlastdates, msf, msf_, permnosrankdates, permnosrankdates2,
permnosrankdates3, permnosrankdates4;
quit;


/*---------------------------------------------------------------------------------------------*/
/*----------------------<Sbusetting obesrvations...>-------------------------------------------*/
/*---------------------------------------------------------------------------------------------*/

data keepthese; input obs permno; cards;
1 10000
2 10006
3 10009
4 10021
;
run;

data _null_;
set keepthese nobs=nobs;
if _n_=1 then call symput("nobs", nobs);
call symput("permname"||strip(left(put(_n_,4.))), permno);
run;

%put _user_;

%macro justconcatenate;
	%let listofpermnos=&permname1;
	%do i=2 %to &nobs;
		%let listofpermnos=%sysfunc(catx(%str(,), &listofpermnos, "%trim(&&permname&i)"));
	%end;
%let listofpermnos=(&listofpermnos);
%mend;
%justconcatenate;


