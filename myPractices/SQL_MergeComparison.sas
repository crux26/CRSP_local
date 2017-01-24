/*When the position of the values is important,*/
/*DATA step merge will be needed in place of Proc SQL*/
/*However, the following example is not "merge" in the sense that*/
/*two tables do not share any common information*/
/*If they do share something, then Proc SQL can be used*/
libname sql 'D:\Dropbox\SAS_scripts\SQL Sample dataset';

data fltsuper;
input Flight Supervisor $;
datalines;
145 Kang
145 Ramirez
150 Miller
150 Picard
155 Evanko
157 Lei
;
data fltdest;
input Flight Destination $;
datalines;
145 Brussels
145 Edmonton
150 Paris
150 Madrid
165 Seattle
;
run;

data merged;
merge fltsuper fltdest;
by Flight;
run;

proc print data=merged noobs;
title 'Table Merged';
run;

proc sql;
title 'Table Joined';
select *
from fltsuper s, fltdest d
where s.Flight=d.Flight;
quit;
