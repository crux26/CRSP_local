%macro tsreg_LoopOnExret_Nest_RV(alpha=);
    %let alpha=&alpha.;

    %let RegkeyVar = VaR_;
    %tsreg_LoopOnExret_RV(RegkeyVar=&RegkeyVar., out=TRP.tsreg_exret_&RegkeyVar.RV_&alpha.);

    %let RegkeyVar = ES_;
    %tsreg_LoopOnExret_RV(RegkeyVar=&RegkeyVar., out=TRP.tsreg_exret_&RegkeyVar.RV_&alpha.);

	%let RegkeyVar = UP_;
    %tsreg_LoopOnExret_RV(RegkeyVar=&RegkeyVar., out=TRP.tsreg_exret_&RegkeyVar.RV_&alpha.);

	%let RegkeyVar = EUP_;
    %tsreg_LoopOnExret_RV(RegkeyVar=&RegkeyVar., out=TRP.tsreg_exret_&RegkeyVar.RV_&alpha.);

	%let RegkeyVar = TRP_;
    %tsreg_LoopOnExret_RV(RegkeyVar=&RegkeyVar., out=TRP.tsreg_exret_&RegkeyVar.RV_&alpha.);

	%let RegkeyVar = ETRP_;
    %tsreg_LoopOnExret_RV(RegkeyVar=&RegkeyVar., out=TRP.tsreg_exret_&RegkeyVar.RV_&alpha.);

%mend tsreg_LoopOnExret_Nest_RV;
