%macro TRP_tsreg_VaR(data=, RegkeyVar=, out=, lag=);
proc model data=&data.;
    parms a b;
    exogenous &RegkeyVar.;
    &RegkeyVar. = a + b*VIX;
    fit &RegkeyVar. / gmm kernel=(bart, %eval(&lag.+1), 0) vardef=n;
    ods output parameterEstimates=&out.;
run;
quit;

%mend TRP_tsreg_VaR;
