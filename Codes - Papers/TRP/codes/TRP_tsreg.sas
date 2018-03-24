%macro TRP_tsreg(data=, DepVar=, IndepVar=, out=, lag=);
proc model data=&data.;
    parms a b;
    exogenous &DepVar.;
    &DepVar. = a + b*&IndepVar.;
    fit &DepVar. / gmm kernel=(bart, %eval(&lag.+1), 0) vardef=n;
	test a=0, b=1;
	test a=0;
	test b=1;
    ods output parameterEstimates=&out.;
	ods output ResidSummary=&out._Rsq;
	ods output TestResults=&out._test;
run;
quit;

%mend TRP_tsreg;
