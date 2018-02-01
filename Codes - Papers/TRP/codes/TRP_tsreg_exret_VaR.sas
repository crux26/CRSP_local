%macro TRP_tsreg_exret_VaR(data=, exret=, RegkeyVar=, out=, lag=);
proc model data=&data.;
    parms a b c;
    exogenous &exret. &RegkeyVar.;
    &exret. = a + b*&RegkeyVar. + c*VIX;
    fit &exret. / gmm kernel=(bart, %eval(&lag.+1), 0) vardef=n;
    ods output parameterEstimates=&out.;
run;
quit;

%mend TRP_tsreg_exret_VaR;
