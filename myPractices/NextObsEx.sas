data have;
   input ID Salary class;
   cards;
10 1000 1
20 2000 1
30 3000 1
40 .		2
50 6000 .
100 9000 3
230 5000 3
;
run;

proc sort data = have;
by class id;
run;

data have;  set have;
by class;
count +1;
if first.class then count=1;
run;

data want;
   recno=_n_+1;
   set have end=last;
   if not last 
           then set have (keep=salary class rename=(salary=next_row_salary class=next_row_class)) point=recno;
      else call missing(next_row_salary, next_row_class) ;
run;
