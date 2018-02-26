%macro AddVar_test_Nest(alpha=);
%let RegkeyVar = VaR_;
%AddVar(RegkeyVar=&RegkeyVar.,
data=tsreg_&RegkeyVar.&alpha._test_, set=tsreg_&RegkeyVar.&alpha._test);

%let RegkeyVar = ES_;
%AddVar(RegkeyVar=&RegkeyVar.,
data=tsreg_&RegkeyVar.&alpha._test_, set=tsreg_&RegkeyVar.&alpha._test);

%let RegkeyVar = UP_;
%AddVar(RegkeyVar=&RegkeyVar.,
data=tsreg_&RegkeyVar.&alpha._test_, set=tsreg_&RegkeyVar.&alpha._test);

%let RegkeyVar = EUP_;
%AddVar(RegkeyVar=&RegkeyVar.,
data=tsreg_&RegkeyVar.&alpha._test_, set=tsreg_&RegkeyVar.&alpha._test);

%let RegkeyVar = TRP_;
%AddVar(RegkeyVar=&RegkeyVar.,
data=tsreg_&RegkeyVar.&alpha._test_, set=tsreg_&RegkeyVar.&alpha._test);

%let RegkeyVar = ETRP_;
%AddVar(RegkeyVar=&RegkeyVar.,
data=tsreg_&RegkeyVar.&alpha._test_, set=tsreg_&RegkeyVar.&alpha._test);
%mend AddVar_test_Nest;
