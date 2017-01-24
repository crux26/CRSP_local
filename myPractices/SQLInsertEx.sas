/*SET and VALUES clauses are used each*/
/*Inserting rows with QUERY is also implemented*/
libname sql 'D:\Dropbox\SAS_scripts\SQL Sample dataset';

/* Create the newcountries table. */
proc sql;
create table newcountries
like sql.countries;
/* Insert all of the rows from countries into newcountries based */
/* on a population of 130000000. */
proc sql;
insert into newcountries
select * from sql.countries
where population ge 130000000;
/* Insert 2 new rows in the newcountries table. */
/* Print the table. */


proc sql;
insert into newcountries
set name='Bangladesh',
capital='Dhaka',
population=126391060
set name='Japan',
capital='Tokyo',
population=126352003;
title "World's Largest Countries";
select name format=$20.,
capital format=$15.,
population format=comma15.0
from newcountries;
quit;

proc sql;
	insert into sql.newcountries
		values ('Pakistan', 'Islamabad', 123060000, ., ' ', .)
		values ('Nigeria', 'Lagos', 99062000, ., ' ', .);
	title "World's Largest Countries";
	select name format=$20.,
				capital format=$15.,
				population format=comma15.0
	from sql.newcountries;
quit;

proc sql;
	create table sql.newcountries
		like sql.countries;
quit;

proc sql;
	title "World's Largest Countries";
	insert into sql.newcountries
	select * from sql.countries
		where population ge 130000000;
	select name format=$20.,
		capital format=$15.,
		population format=comma15.0
	from sql.newcountries;
quit;
