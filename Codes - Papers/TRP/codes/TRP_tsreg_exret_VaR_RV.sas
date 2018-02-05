%macro TRP_tsreg_exret_VaR_RV(data=, exret=, RegkeyVar=, out=, lag=);
proc model data=&data.;
    parms a b c;
    exogenous &exret. &RegkeyVar. VIX RV;
    &exret. = a + b*&RegkeyVar. + c*(VIX-RV);
    fit &exret. / gmm kernel=(bart, %eval(&lag.+1), 0) vardef=n;
    ods output parameterEstimates=&out.;
run;
quit;

%mend TRP_tsreg_exret_VaR_RV;
