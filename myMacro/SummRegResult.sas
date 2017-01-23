%macro SummRegResult(data=, out=, var=, by=);
proc means data=&data noprint nway;
output out=&out(drop=_TYPE_ _FREQ_);
var &var;
by &by;
run;
%mend SummRegResult;
