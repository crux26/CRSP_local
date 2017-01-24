libname sql 'D:\Dropbox\GitHub\CRSP_local\SQL Sample dataset';

proc sql outobs=12;
	reset noprint;
	select max(AvgHigh)
		into :maxtemp
			from sql.worldtemps
			where country = 'Canada';
	reset print;
	title "The Highest Temperature in Canada: &maxtemp";
	select city, AvgHigh format 4.1
		from sql.worldtemps
		where country = 'Canada';
quit;

%put _user_;
