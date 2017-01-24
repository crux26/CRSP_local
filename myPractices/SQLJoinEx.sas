libname sql 'D:\Dropbox\SAS_scripts\SQL Sample dataset';
/*Following 2 are the same*/
/*1: listing in FROM & WHERE*/
/*2: INNER JOIN & ON */

proc sql;
title 'Oil Production/Reserves of Countries';
select p.*, barrels from sql.oilprod as p, sql.oilrsrvs as r
where p.country = r.country;
quit;

proc sql ;
title 'Oil Production/Reserves of Countries';
select p.*, barrels 'barrels_join'
from sql.oilprod as p inner join sql.oilrsrvs as r
on p.country = r.country;

quit;
