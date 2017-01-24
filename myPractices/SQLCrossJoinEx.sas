/*Following 2 tables are the same*/
libname sql 'D:\Dropbox\SAS_scripts\SQL Sample dataset';

data one;
input X Y $;
datalines;
1 2
2 3
;
data two;
input W Z $;
datalines;
2 5
3 6
4 9
;
run;

proc sql;
title 'Table One';
select * from one;
title 'Table Two';
select * from two;
title;
quit;

proc sql;
title 'Table One and Table Two; Cross Join';
select *
from one cross join two;
quit;

proc sql;
title 'Table One and Two';
select * from one, two;
quit;
