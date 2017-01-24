libname sql 'D:\Dropbox\GitHub\CRSP_local\SQL Sample dataset';

proc sql;
	create index area
		on sql.newcountries(area);
quit;

proc sql;
create index places
on sql.newcountries(name, continent);
quit;

proc sql;
drop index places from sql.newcountries;
quit;

proc sql;
drop index area from sql.newcountries;
quit;

proc contents data=sql.newcountries;
run;
