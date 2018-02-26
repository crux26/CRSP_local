%macro AddVar_RV_Nest(alpha=);
%let RegkeyVar = VaR_;
%AddVar(RegkeyVar=&RegkeyVar.,
data=tsreg_RV_&RegkeyVar.&alpha._, set=tsreg_RV_&RegkeyVar.&alpha.);

%let RegkeyVar = ES_;
%AddVar(RegkeyVar=&RegkeyVar.,
data=tsreg_RV_&RegkeyVar.&alpha._, set=tsreg_RV_&RegkeyVar.&alpha.);

%let RegkeyVar = UP_;
%AddVar(RegkeyVar=&RegkeyVar.,
data=tsreg_RV_&RegkeyVar.&alpha._, set=tsreg_RV_&RegkeyVar.&alpha.);

%let RegkeyVar = EUP_;
%AddVar(RegkeyVar=&RegkeyVar.,
data=tsreg_RV_&RegkeyVar.&alpha._, set=tsreg_RV_&RegkeyVar.&alpha.);

%let RegkeyVar = TRP_;
%AddVar(RegkeyVar=&RegkeyVar.,
data=tsreg_RV_&RegkeyVar.&alpha._, set=tsreg_RV_&RegkeyVar.&alpha.);

%let RegkeyVar = ETRP_;
%AddVar(RegkeyVar=&RegkeyVar.,
data=tsreg_RV_&RegkeyVar.&alpha._, set=tsreg_RV_&RegkeyVar.&alpha.);

%mend AddVar_RV_Nest;
