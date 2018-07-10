/*Note that cumprod cannot be calculated w/o BY statement.*/
data have;
   informat  stock $5.  date ddmmyy10. adjustment_factor best8.;
   format date ddmmyy10.;
   input stock  date  adjustment_factor;
datalines;
1        31/01/2000       1
1        01/02/2000       1
1        02/02/2000       1.2
1        10/02/2000        1
1        11/02/2000        1
1        12/02/2000        1
2        31/01/2000        1
2        01/02/2000        1
2        02/02/2000        1
2        10/02/2000         2.2
2        11/02/2000         1
2        12/02/2000         1.7
2         13/02/2000        1
;

data want;
   set have;
   by stock date;
   retain cum_adjust;
   if first.stock then cum_adjust = adjustment_factor;
   else cum_adjust = cum_adjust*adjustment_factor ;
run;
