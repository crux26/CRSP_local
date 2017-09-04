/* Finding Month-End. This not fully implemented, and has an "error" at the last observation. */

data &datain._0; set &datain._00; by permno;
year=year(date); month=month(date); day=day(date); month_chg = dif(month);
if first.permno then month_chg=0;
if month_chg^=0 then isMonthBeg=1;
run;

data &datain._1; merge &datain._0(in=_base) &datain._0(keep=isMonthBeg firstobs=2 rename=isMonthBeg=isMonthEnd);
if _base;
run;

%abort;
