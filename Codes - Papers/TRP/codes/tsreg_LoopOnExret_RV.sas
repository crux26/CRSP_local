%macro tsreg_LoopOnExret_RV(DepVarList=, IndepVar=, data=, out=);
	%let nwords=%sysfunc(countw(&DepVarList));
	%do i2=1 %to &nwords;
		%let DepVar = %scan(&DepVarList, &i2);

    %TRP_tsreg_exret_VaR_RV(data=&data., DepVar=&DepVar., IndepVar=&IndepVar.,
        out=tsreg_&DepVar._&IndepVar., lag=&lag);

    data tsreg_&DepVar._&IndepVar._;
        length EstType $ 32;
        set tsreg_&DepVar._&IndepVar.;
        EstType = "&DepVar._&IndepVar.";
    run;
	%end;

    data &out.;
        set tsreg_exret_lead1W_&IndepVar._ tsreg_exret_lead2W_&IndepVar._ tsreg_exret_lead3W_&IndepVar._
            tsreg_exret_lead1M_&IndepVar._  tsreg_exret_lead2M_&IndepVar._  tsreg_exret_lead3M_&IndepVar._
			tsreg_exret_lead6M_&IndepVar._;
    run;

    proc sql;
        drop table 
			tsreg_exret_lead1W_&IndepVar., tsreg_exret_lead2W_&IndepVar., tsreg_exret_lead3W_&IndepVar.,
            tsreg_exret_lead1M_&IndepVar.,  tsreg_exret_lead2M_&IndepVar.,  tsreg_exret_lead3M_&IndepVar.,
			tsreg_exret_lead6M_&IndepVar.,
            tsreg_exret_lead1W_&IndepVar._, tsreg_exret_lead2W_&IndepVar._, tsreg_exret_lead3W_&IndepVar._,
            tsreg_exret_lead1M_&IndepVar._,  tsreg_exret_lead2M_&IndepVar._,  tsreg_exret_lead3M_&IndepVar._,
			tsreg_exret_lead6M_&IndepVar._;
    quit;

%mend tsreg_LoopOnExret_RV;
