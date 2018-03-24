%macro TRP_tsreg_RV(data=, RegkeyVar=, out=, lag=);
proc model data=&data.;
    parms a b;
    exogenous RV_lead1M;
    RV_lead1M = a + b*&RegkeyVar.;
    fit RV_lead1M / gmm kernel=(bart, %eval(&lag.+1), 0) vardef=n;
	test a=0, b=1;
	test a=0;
	test b=1;
    ods output parameterEstimates=&out.;
	ods output ResidSummary=&out._Rsq;
	ods output TestResults=&out._test;
run;
quit;

%mend TRP_tsreg_RV;
