libname sql 'D:\Dropbox\SAS_scripts\SQL Sample dataset';

proc sql outobs=12;
title 'Mean Temperatures for World Cities';
select City, Country, mean(AvgHigh, AvgLow)
as MeanTemp
from sql.worldtemps
where calculated MeanTemp gt 75
order by MeanTemp desc;

quit;

proc sql outobs=12;
title 'Mean Temperatures for World Cities';
select City, Country, max(AvgHigh)
as MaxTemp
from sql.worldtemps;

quit;

proc sql outobs=12;
title 'Mean Temperatures for World Cities';
select City, Country, min(AvgHigh, AvgLow)
as MinTemp
from sql.worldtemps
order by MinTemp desc;

quit;
