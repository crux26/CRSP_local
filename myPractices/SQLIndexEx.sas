/*Index created is automatically checked by SAS*/
/*for faster accessbility to observations*/
/*Index can be included in its table, or be a separate file*/
/*PROC CONTENTS checks if there's any index */
/*defined w.r.t. that table*/
libname sql 'D:\Dropbox\GitHub\CRSP_local\SQL Sample dataset';

proc sql;
	create index area
		on sql.newcountries(area);
quit;

proc sql;
create index places
on sql.newcountries(name, continent);
quit;

proc contents data=sql.newcountries;
run;


proc sql;
drop index places from sql.newcountries;
quit;

proc sql;
drop index area from sql.newcountries;
quit;

