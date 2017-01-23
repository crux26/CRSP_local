/* scalar multiplied by matrix */

data scalar;
c = 3;
proc print data = scalar;
run;


data matrix;
input x y; cards;
3 7
2 6
proc print data = matrix;
run;


data mult_result;
set scalar (rename = (c=cA1));
drop cA: ;
do until (_it);
set matrix (rename =(x = cB1 y=cB2) ) end=_it;
col1 = cA1*cB1;
col2 = cA1*cB2;
output; /*<-- cannot have the desired result w/o this command*/
drop cB: ;
end;
proc print;
run;
quit;


/* element-wise matrix multiplication without IML / SQL */

data mat1;
input x y; cards;
1 2
3 4
;

data mat2;
input x y; cards;
2 3
4 5
;

data mat_mult2;
merge mat1 (rename = (x=x1 y=y1)) mat2 (rename = (x=x2 y=y2));
col1 = x1*x2;
col2 = y1*y2;
drop x: y: ;
proc print data = mat_mult2;
run;


proc contents data = mat_mult2;
run;
quit;
