proc format;
value category
Low-<0 = 'Less Than Zero'
0 = 'Equal To Zero'
0<-high = 'Greater Than Zero'
other = 'Missing';
run;
%macro try(parm);
%put &parm is %sysfunc(putn(&parm,category.));
%mend;
%try(1.02)
%try(.)
%try(-.38)
