%macro TRP_tsreg_exret_VaR_RV(data=, DepVar=, IndepVar=, out=, lag=);
proc model data=&data.;
    parms a b c;
    exogenous &DepVar. &IndepVar. VIX RV;
    &DepVar. = a + b*&IndepVar. + c*(VIX-RV);
    fit &DepVar. / gmm kernel=(bart, %eval(&lag.+1), 0) vardef=n;
    ods output parameterEstimates=&out.;
run;
quit;

%mend TRP_tsreg_exret_VaR_RV;
