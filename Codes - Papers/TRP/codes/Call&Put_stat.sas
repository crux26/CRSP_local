libname a_index "D:\Dropbox\WRDS\CRSP\sasdata\a_indexes";
libname a_stock "D:\Dropbox\WRDS\CRSP\sasdata\a_stock";
libname a_treas "D:\Dropbox\WRDS\CRSP\sasdata\a_treasuries";
libname ff "D:\Dropbox\WRDS\ff\sasdata";
libname mysas "D:\Dropbox\WRDS\CRSP\mysas";
libname myOption "D:\Dropbox\WRDS\CRSP\myOption";
libname myMacro "D:\Dropbox\GitHub\CRSP_local\myMacro";
libname optionm "\\Egy-labpc\WRDS\optionm\sasdata";

%let head = optionm.Opprcd;

data SPXCall;
set  &head.1996 &head.1997 &head.1998 &head.1999 &head.2000 &head.2001 &head.2002 &head.2003 &head.2004 &head.2005 &head.2006
 &head.2007 &head.2008 &head.2009 &head.2010 &head.2011 &head.2012 &head.2013 &head.2014 &head.2015;
where cp_flag = "C" & secid = 108105;
run;

data SPXPut;
set  &head.1996 &head.1997 &head.1998 &head.1999 &head.2000 &head.2001 &head.2002 &head.2003 &head.2004 &head.2005 &head.2006
 &head.2007 &head.2008 &head.2009 &head.2010 &head.2011 &head.2012 &head.2013 &head.2014 &head.2015;
where cp_flag = "P" & secid = 108105;
run;

proc sort data=spxcall;
by date exdate strike_price;
run;

proc sort data=spxput;
by date exdate strike_price;
run;

/**/
data myoption.spxcall_keepall; set spxcall; strike_price=strike_price/1000; run;
data myoption.spxput_keepall; set spxput; strike_price=strike_price/1000; run;
/**/

data spxcall_keepall; set myoption.spxcall_keepall; run;
data spxput_keepall; set myoption.spxput_keepall; run;

proc sort data=spxcall_keepall; by exdate date strike_price optionid; run;
proc sort data=spxput_keepall; by exdate date strike_price optionid; run;

data spxcall_keepall;
retain date exdate strike_price optionid volume open_interest impl_volatility;
set spxcall_keepall;
strike_price = strike_price/1000;
run;

data spxput_keepall;
retain date exdate strike_price optionid volume open_interest impl_volatility;
set spxput_keepall;
strike_price = strike_price/1000;
run;

proc sql;
create table call_stat as
select distinct date, exdate, min(strike_price/1000) as K_min, max(strike_price/1000) as K_max,
std(strike_price/1000) as K_STD format=5.3, count(distinct strike_price/1000) as K_num
from spxcall_keepall as a
group by exdate, date
order by exdate, date;
quit;

proc sql;
create table put_stat as
select distinct date, exdate, min(strike_price/1000) as K_min, max(strike_price/1000) as K_max,
std(strike_price/1000) as K_STD format=5.3, count(distinct strike_price/1000) as K_num
from spxcall_keepall as a
group by exdate, date
order by exdate, date;
quit;

data myoption.SPXCall_stat; set call_stat; run;
data myoption.SPXPut_stat; set put_stat; run;

data tmp_; set spxcall_keepall(firstobs=107455 obs=107516); run;

proc export data=call_stat
outfile="D:\Dropbox\GitHub\TRP\Stats\Call_stat.xlsx"
dbms=xlsx replace;
run;

proc export data=put_stat
outfile="D:\Dropbox\GitHub\TRP\Stats\Put_stat.xlsx"
dbms=xlsx replace;
run;
