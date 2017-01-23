%macro counterEx(data=);
data &data;
set &data;
%if _N_ = 1 %then do;
FirstObs = 1;
output;
run;
%mend counterEx;
