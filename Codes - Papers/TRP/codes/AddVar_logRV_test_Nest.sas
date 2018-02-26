%macro AddVar_logRV_test_Nest(alpha=);
%let RegkeyVar = VaR_;
%AddVar(RegkeyVar=&RegkeyVar.,
data=tsreg_logRV_&RegkeyVar.&alpha._test_, set=tsreg_logRV_&RegkeyVar.&alpha._test);

%let RegkeyVar = ES_;
%AddVar(RegkeyVar=&RegkeyVar.,
data=tsreg_logRV_&RegkeyVar.&alpha._test_, set=tsreg_logRV_&RegkeyVar.&alpha._test);

%let RegkeyVar = UP_;
%AddVar(RegkeyVar=&RegkeyVar.,
data=tsreg_logRV_&RegkeyVar.&alpha._test_, set=tsreg_logRV_&RegkeyVar.&alpha._test);

%let RegkeyVar = EUP_;
%AddVar(RegkeyVar=&RegkeyVar.,
data=tsreg_logRV_&RegkeyVar.&alpha._test_, set=tsreg_logRV_&RegkeyVar.&alpha._test);

%let RegkeyVar = TRP_;
%AddVar(RegkeyVar=&RegkeyVar.,
data=tsreg_logRV_&RegkeyVar.&alpha._test_, set=tsreg_logRV_&RegkeyVar.&alpha._test);

%let RegkeyVar = ETRP_;
%AddVar(RegkeyVar=&RegkeyVar.,
data=tsreg_logRV_&RegkeyVar.&alpha._test_, set=tsreg_logRV_&RegkeyVar.&alpha._test);

%mend AddVar_logRV_test_Nest;
