%macro JARQUE_BERA(data= , var= );
**********************************************;
* SAS macro to do Jarque-Bera Normality Test *;
* ------------------------------------------ *;
* wensui.liu@53.com                          *;
**********************************************;
options mprint mlogic symbolgen nodate;

ods listing close;
ods output moments = m1;
proc univariate data = &data normal;
  var &var.;
run;

proc sql noprint;
  select nvalue1 into :n from m1 where upcase(compress(label1, ' ')) = 'N';
  select put(nvalue1, best32.) into :s from m1 where upcase(compress(label1, ' ')) = 'SKEWNESS';
  select put(nvalue2, best32.) into :k from m1 where upcase(compress(label2, ' ')) = 'KURTOSIS';
quit;

data _temp_;
  jb = ((&s) ** 2 + (&k) ** 2 / 4) / 6 * &n;
  pvalue = 1 - probchi(jb, 2);
  put jb pvalue;
run;

ods listing;
proc print data = _last_ noobs;
run;

%mend jarque_bera;
