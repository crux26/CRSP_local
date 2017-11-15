/*%include myMacro('SetDate.sas'); WILL NOT work unless */
/*-SASINITIALFOLDER "D:\Dropbox\GitHub\CRSP_local" added to sasv9.cfg in ...\nls\en and \ko*/
libname a_index "D:\Dropbox\WRDS\CRSP\sasdata\a_indexes";
libname a_stock "D:\Dropbox\WRDS\CRSP\sasdata\a_stock";
libname a_treas "D:\Dropbox\WRDS\CRSP\sasdata\a_treasuries";
libname ff "D:\Dropbox\WRDS\ff\sasdata";
libname frb "D:\Dropbox\WRDS\frb\sasdata";
libname mysas "D:\Dropbox\WRDS\CRSP\mysas";
libname myMacro "D:\Dropbox\GitHub\CRSP_local\myMacro";
libname optionm "\\Egy-labpc\WRDS\optionm\sasdata";

%include myMacro('PersistenceAnal.sas');
%PersistenceAnal(data=mysas.msf_common, out=result, ret=ret, date=date, identifier=permno);

/*ABOVE is the shorthand version of BELOW.*/
/**/
data have0;
set mysas.msf_common;
year = year(date);
run;

proc sort data=have0;
by permno date;
run;

data have1;
set have0;
by permno;
ObsNum+1;
if first.permno then ObsNum =1;
run;

/*Below is too brute-force. Find a better solution*/
/*--> this "Brute-force" approach is actually provided by SAS*/
data have2;
set have1;
by permno;
L1ret = lag(ret);
L2ret = lag(L1ret);
L3ret = lag(L2ret);
if ObsNum =1 then do;
	L1ret = .; 	L2ret = .; 	L3ret = .;
end;
if ObsNum = 2 then do;
	L2ret = .;	L3ret = .;
end;
if ObsNum = 3 then do;
	L3ret = .;
end;
run;
/**/
proc sort data=have2;
by year permno;
run;

/*As Jan or Feb data are missing by lag1 and lag2, "N" in the first year 1988 being*/
/*much smaller for L1ret, L2ret is natural*/
proc corr data=have2 outp = corr_L1 noprint;
var ret L1ret;
by year;
run;

proc corr data=have2 outp = corr_L2 noprint;
var ret L2ret;
by year;
run;

proc corr data=have2 outp = corr_L3 noprint;
var ret L1ret L2ret;
by year;
run;


data want1;
set corr_l1;
drop L1ret;
if _name_ ^= 'L1ret' then delete;
run;

data want2;
set corr_l2;
drop L2ret;
if _name_ ^= 'L2ret' then delete;
run;

data want3;
set corr_L3;
keep year _type_ _name_ ret;
if _name_="" then _name_ = _type_;
run;

data want33;
set want3;
if _name_ ="" then _name_ =_type_;
run;

proc transpose data=want33 out=want4(drop=_label_ ret) name=varname;
var ret  ;
id _name_ ;
by year;
run;
