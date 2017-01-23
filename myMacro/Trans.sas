%macro Trans(data=, out=, var=, id=, by=);
proc transpose data=&data out=&out(drop=_LABEL_) name=Coeff;
var &var;
id &id;
by &by;
run;
%mend Trans;
