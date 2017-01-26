/*cmiss returns 1 for any(is missing), 0 for all(not is missing)*/
%macro nonMissing(data=, set=, var=);
data tmp / view=tmp;
set &set;
isMissingChk = cmiss(of &var);
run;

data &data;
set tmp;
where isMissingChk = 0;
drop isMissingChk;
run;

proc sql;
drop view tmp;
run;
quit;
%mend nonMissing;


