/*Only at DEC to replicate BEM's table.*/

/* Although MktCap_BEM (DEC value only) is much easier to calculate, trying MktCap^FF for practice. */
/* Bali, Engle, Murray says two methods yields more or less the same results for most of the cases. */
/* Note that this MktCap is NOT "ME" of "BE/ME". */
/* "ME": value of December of year t-1 */
%let begdate = '01JAN1988'd;
%let enddate = '31DEC2012'd;
%let vars = permno permco date prc altprc cfacpr vol ret shrout cfacshr;

data msix;
	set a_index.msix;
	where caldt between &begdate and &enddate;
run;

data msf;
set a_stock.msf;
date = intnx('month', date, 0, 'e');
run;

proc sql;
create table msf_dlretAdj as
select a.*, b.altprc, b.cfacpr, b.cfacshr
from
BEM.msf_dlretAdj as a
left join
msf as b
on
a.permno = b.permno and a.date = b.date
order by a.permno, a.date;
quit;

/*Note that in BEM, MktCap is scaled by $1m (usually by $1k to make it $1m unit.)*/
data MktCap_DEC(keep=&vars year month mktcap);
	set msf_dlretAdj(where=(date between &begdate and &enddate));
	year = year(date);
	month = month(date);
	if month = 12 then
			MktCap = abs(altprc) / cfacpr * shrout * cfacshr / 1000000;
run;

proc sort data=MktCap_DEC out=MktCap_DEC;
	by permno year;
run;

/* Keep June's MktCap constant until the following May. */
data MktCap_DEC2(drop=count _MktCap JuneCount cum_JuneCount);
	set MktCap_DEC;
	by permno year;

	if first.permno then
		count=0;
	count+1;
	retain _MktCap;

	if missing(MktCap)=0 then
		_MktCap = MktCap;

	if missing(MktCap) then
		MktCap = _MktCap;
	SIZE = log(MktCap);

	if month=6 then
		JuneCount=1;
	else JuneCount=0;
	retain cum_JuneCount;

	if first.permno then
		cum_JuneCount=0;
	cum_JuneCount+JuneCount;

	/*cum_JuneCount: No June appearance up to now. */
	if cum_JuneCount = 0 then
		do;
			MktCap=.;
			SIZE=.;
		end;
run;

proc sort data=MktCap_DEC2 out=BEM.MktCap_DEC(where=(month=12));
	by year month permno;
run;

proc datasets nolist;
	delete MktCap_DEC MktCap_DEC2 msf_;
quit;

ods results off;
proc means data=BEM.MktCap_Dec StackOdsOutput mean stddev skew kurt min p5 p25 median p75 p95 max n;
var MktCap Size;
by year;
ods output summary = BEM.MktCap_DECPrdcStat;
run;

proc sort data=BEM.MKTCap_DecPrdcStat out=BEM.MKTCap_DecPrdcStat;
	by variable;
run;

proc means data=BEM.MKTCap_DecPrdcStat StackOdsOutput mean;
var mean stddev skew kurt min p5 p25 median p75 p95 max n;
by variable;
ods output summary = MktCap_DecAvgStat;
run;

proc transpose data=MktCap_DecAvgStat out=BEM.MktCap_DecAvgStat;
	by variable;
	id variable2;
	var mean;
run;
