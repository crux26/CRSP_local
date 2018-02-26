%macro AddVar_Nest_log(alpha=);

%let RegkeyVar = log_VaR_;
%AddVar(RegkeyVar=&RegkeyVar.,
data=tsreg_&RegkeyVar.&alpha._, set=tsreg_&RegkeyVar.&alpha.);

%let RegkeyVar = log_ES_;
%AddVar(RegkeyVar=&RegkeyVar.,
data=tsreg_&RegkeyVar.&alpha._, set=tsreg_&RegkeyVar.&alpha.);

%let RegkeyVar = log_UP_;
%AddVar(RegkeyVar=&RegkeyVar.,
data=tsreg_&RegkeyVar.&alpha._, set=tsreg_&RegkeyVar.&alpha.);

%let RegkeyVar = log_EUP_;
%AddVar(RegkeyVar=&RegkeyVar.,
data=tsreg_&RegkeyVar.&alpha._, set=tsreg_&RegkeyVar.&alpha.);

%let RegkeyVar = log_TRP_;
%AddVar(RegkeyVar=&RegkeyVar.,
data=tsreg_&RegkeyVar.&alpha._, set=tsreg_&RegkeyVar.&alpha.);

%let RegkeyVar = log_ETRP_;
%AddVar(RegkeyVar=&RegkeyVar.,
data=tsreg_&RegkeyVar.&alpha._, set=tsreg_&RegkeyVar.&alpha.);

%mend AddVar_Nest_log;
