/*data a (drop=i);*/
/*    do i=1 to 1000;*/
/*    x1=rannor(1234);*/
/*    x2=rannor(1234);*/
/*    e=rannor(1234);*/
/*if i > 950 then y=100 + 10*e;*/
/*else y=10 + 5*x1 + 3*x2 + 0.5 * e;*/
/*output;*/
/*end;*/
/*run;*/

data cars; set sashelp.cars; run;

proc reg data=cars outest=cars_reg edf noprint;
model invoice = cylinders horsepower mpg_city;
run;

proc quantreg data=cars outest = cars_quantreg;
model invoice = enginesize horsepower weight / quantile=0.05 0.5 0.95 ;
run;
