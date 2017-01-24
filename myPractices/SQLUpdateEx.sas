libname sql 'D:\Dropbox\SAS_scripts\SQL Sample dataset';

proc sql;
	create table sql.newcountries like sql.countries;
	insert into sql.newcountries
	select * from sql.countries
		where population ge 130000000;
quit;

proc sql;
update sql.newcountries
	set population=population*1.05;
title "Updated Population Values";
select name format=$20.,
			capital format=$15.,
			population format=comma15.0
	from sql.newcountries;
quit;
