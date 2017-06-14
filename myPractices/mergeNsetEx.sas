data have1;
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
proc sort data=have1; by id; run;


data have2;
   input ID Salary class;
   cards;
110 1000 1
120 2000 1
130 3000 1
140 .		2
150 6000 .
1100 9000 3
1230 5000 3
;
run;
proc sort data=have2; by id; run;


data have3;
   input ID Salary class;
   cards;
110 11000 1
320 12000 1
230 13000 1
140 .		2
450 16000 .
200 19000 3
430 15000 3
;
run;
proc sort data=have3; by id; run;

/*If same id occurs, then the right will overwrite onto the left*/
/*MERGE statement will automatically sort w.r.t. by id*/
data want_m12;
merge have1 have2;
by id; /*w/o BY clause, it won't work as I expected*/
run;


data want_m13;
merge have1 (in=have1) have3 (in=have3);
/*BELOW wouldn't work*/
/*have1 = have1; have3=have3;*/
i1 = have1; i3 = have3;
by id;
run;

/*SET statement will concatenate in [have1; have2] shape*/
/*That is, the result will not be sorted*/
data want_s131;
set have1 have3;
run;

/*With BY clause, the result will show up in sorted order*/
/*Even if same ID occurs, instead of overwritting onto one another,*/
/*It prints all the data sharing the same ID */
data want_s132;
set have1 have3;
by id;
run;
