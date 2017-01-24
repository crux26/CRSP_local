/*See CASE expression carefully*/
/*Make sure to include ELSE clause in CASE expression*/
libname sql 'D:\Dropbox\SAS_scripts\SQL Sample dataset';

proc sql;
	create table sql.newcountries like sql.countries;
	insert into sql.newcountries
	select * from sql.countries
		where population ge 130000000;
quit;

proc sql;
	update sql.newcountries
		set population=population*1.05
			where name like 'B%';
	update sql.newcountries
		set population=population*1.07
			where name in ('China', 'Russia');
	title "Selectively Updated Population Values";
	select name format=$20.,
				capital format=$15.,
				population format=comma15.0
		from sql.newcountries;
quit;

/**/

proc  sql;
	update sql.newcountries
	set population=population*
		case when name like 'B%' then 1.05
				when name in ('China', 'Russia') then 1.07
				else 1
	end;
quit;
