data have;
format d date11.;
input d date9. x1 $ 10-15 x2 $ 16-21 precip 22-30;
datalines;
02AUG1994                    8
03AUG1994                   56
04AUG1994                   18
05AUG1994                   15
06AUG1994                   36
07AUG1994                    0
08AUG1994                    0
09AUG1994                    0
10AUG1994                    0
11AUG1994                   76
12AUG1994                    0
13AUG1994                   33
14AUG1994                   79
15AUG1994                    0
16AUG1994                   13
17AUG1994                    5
18AUG1994                    0
19AUG1994          X2       61
20AUG1994                    0
21AUG1994                   33
22AUG1994                  231
23AUG1994    X1              0
24AUG1994                    0
25AUG1994                    5
;

proc transpose data=have 
out=refs(rename=(d=refDate col1=station) where=(notspace(station)>0) drop=_:);
by d notsorted;
var x:;
run;

data intervals;
input interval $;
datalines;
WEEK2
WEEK6
MONTH9
;

proc sql;
create table want as
select station, refDate, interval, sum(precip) as totalPrecip
from have, refs, intervals
where d between intnx(interval, refDate-1, -1, "SAME") and refDate 
group by station, refDate, interval;
quit;
