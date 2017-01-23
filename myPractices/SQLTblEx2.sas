data have;
   input ID Salary class;
   cards;
10 1000 1
20 2000 1
30 3000 1
40 4000		2
50 5000 .
60 6000 3
70 7000 3
;
run;

proc sql;
create table want
as select distinct a.* 
from have as a, have as b
where a.salary > b.salary and b.class =1;
quit;

proc sql;
create table want2
as select *
from have
where salary > some (select salary from have where class=1);
quit;

proc sql;
create table want3
as select *
from have as a
where exists (select salary from have as b where a.salary > b.salary and  b.class=1);
quit;

proc sql;
create table want4
as select *
from have as a
where not exists (select salary from have as b where a.salary > b.salary and  b.class=1);
quit;

proc sql;
create table want5
as select *
from have
where salary > all (select salary from have where class=1);
quit;

/*"with" clause doesn't work in SAS proc SQL*/

/*proc sql;*/
/*create table want6*/
/*as select **/
/*with max_salary(value) as (select max(salary) from have)*/
/*from have, max_salary*/
/*where have.salary = max_salary.value;*/
/*quit;*/
