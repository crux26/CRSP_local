%macro AddVar_logRV_test_Nest_log(alpha=);
%let RegkeyVar = log_VaR_;
%AddVar(RegkeyVar=&RegkeyVar.,
data=tsreg_logRV_&RegkeyVar.&alpha._test_, set=tsreg_logRV_&RegkeyVar.&alpha._test);

%let RegkeyVar = log_ES_;
%AddVar(RegkeyVar=&RegkeyVar.,
data=tsreg_logRV_&RegkeyVar.&alpha._test_, set=tsreg_logRV_&RegkeyVar.&alpha._test);

%let RegkeyVar = log_UP_;
%AddVar(RegkeyVar=&RegkeyVar.,
data=tsreg_logRV_&RegkeyVar.&alpha._test_, set=tsreg_logRV_&RegkeyVar.&alpha._test);

%let RegkeyVar = log_EUP_;
%AddVar(RegkeyVar=&RegkeyVar.,
data=tsreg_logRV_&RegkeyVar.&alpha._test_, set=tsreg_logRV_&RegkeyVar.&alpha._test);

%let RegkeyVar = log_TRP_;
%AddVar(RegkeyVar=&RegkeyVar.,
data=tsreg_logRV_&RegkeyVar.&alpha._test_, set=tsreg_logRV_&RegkeyVar.&alpha._test);

%let RegkeyVar = log_ETRP_;
%AddVar(RegkeyVar=&RegkeyVar.,
data=tsreg_logRV_&RegkeyVar.&alpha._test_, set=tsreg_logRV_&RegkeyVar.&alpha._test);

%mend AddVar_logRV_test_Nest_log;
