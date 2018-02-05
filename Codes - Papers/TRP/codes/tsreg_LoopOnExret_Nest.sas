%macro tsreg_LoopOnExret_Nest(alpha=);
    %let alpha=&alpha.;

    %let RegkeyVar = VaR_;
    %tsreg_LoopOnExret(RegkeyVar=&RegkeyVar., out=TRP.tsreg_exret_&RegkeyVar._&alpha.);

    %let RegkeyVar = ES_;
    %tsreg_LoopOnExret(RegkeyVar=&RegkeyVar., out=TRP.tsreg_exret_&RegkeyVar._&alpha.);

	%let RegkeyVar = UP_;
    %tsreg_LoopOnExret(RegkeyVar=&RegkeyVar., out=TRP.tsreg_exret_&RegkeyVar._&alpha.);

	%let RegkeyVar = EUP_;
    %tsreg_LoopOnExret(RegkeyVar=&RegkeyVar., out=TRP.tsreg_exret_&RegkeyVar._&alpha.);

	%let RegkeyVar = TRP_;
    %tsreg_LoopOnExret(RegkeyVar=&RegkeyVar., out=TRP.tsreg_exret_&RegkeyVar._&alpha.);

	%let RegkeyVar = ETRP_;
    %tsreg_LoopOnExret(RegkeyVar=&RegkeyVar., out=TRP.tsreg_exret_&RegkeyVar._&alpha.);

%mend tsreg_LoopOnExret_Nest;
