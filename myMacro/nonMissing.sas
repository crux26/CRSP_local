%macro nonMissing(data=, set=, var=);
data &data;
set &set;
where &var ^=.  ;
run;
%mend nonMissing;

/*Not working properly for multiple macro variables within where statement*/
