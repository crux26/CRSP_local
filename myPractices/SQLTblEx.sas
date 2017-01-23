proc sql;
create table CorrOnly_N
as 
select a.*, b.vol as NVol, b.ret as Nret
from 
	CorrOnly as a
left join
	CorrSort as b
on 	a.date = b.date &
		b._type_ = "N" ;
quit;
