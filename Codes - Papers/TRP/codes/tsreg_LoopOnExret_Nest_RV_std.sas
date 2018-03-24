%macro tsreg_LoopOnExret_Nest_RV_std(alpha=, data=);
    %let alpha=&alpha.;

    %let RegkeyVar = VaR_;
    %tsreg_LoopOnExret_RV(RegkeyVar=&RegkeyVar., data=&data., out=TRP.tsreg_exret_&RegkeyVar.RV_&alpha._std);

    %let RegkeyVar = ES_;
    %tsreg_LoopOnExret_RV(RegkeyVar=&RegkeyVar., data=&data., out=TRP.tsreg_exret_&RegkeyVar.RV_&alpha._std);

	%let RegkeyVar = UP_;
    %tsreg_LoopOnExret_RV(RegkeyVar=&RegkeyVar., data=&data., out=TRP.tsreg_exret_&RegkeyVar.RV_&alpha._std);

	%let RegkeyVar = EUP_;
    %tsreg_LoopOnExret_RV(RegkeyVar=&RegkeyVar., data=&data., out=TRP.tsreg_exret_&RegkeyVar.RV_&alpha._std);

	%let RegkeyVar = TRP_;
    %tsreg_LoopOnExret_RV(RegkeyVar=&RegkeyVar., data=&data., out=TRP.tsreg_exret_&RegkeyVar.RV_&alpha._std);

	%let RegkeyVar = ETRP_;
    %tsreg_LoopOnExret_RV(RegkeyVar=&RegkeyVar., data=&data., out=TRP.tsreg_exret_&RegkeyVar.RV_&alpha._std);

%mend tsreg_LoopOnExret_Nest_RV_std;
