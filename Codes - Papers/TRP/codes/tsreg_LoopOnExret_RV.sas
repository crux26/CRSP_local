%macro tsreg_LoopOnExret_RV(RegkeyVar=, out=);
    %let exret = exret_lead1W;

    %TRP_tsreg_exret_VaR_RV(data=T_tmp_Wed_alpha_&alpha., exret=&exret., RegkeyVar=&RegkeyVar.,
        out=tsreg_&exret._&RegkeyVar., lag=&lag);

    data tsreg_&exret._&RegkeyVar._;
        length EstType $ 32;
        set tsreg_&exret._&RegkeyVar.;
        EstType = "&exret._&RegkeyVar.";
    run;

    %let exret = exret_lead2W;

    %TRP_tsreg_exret_VaR_RV(data=T_tmp_Wed_alpha_&alpha., exret=&exret., RegkeyVar=&RegkeyVar.,
        out=tsreg_&exret._&RegkeyVar., lag=&lag);

    data tsreg_&exret._&RegkeyVar._;
        length EstType $ 32;
        set tsreg_&exret._&RegkeyVar.;
        EstType = "&exret._&RegkeyVar.";
    run;

    %let exret = exret_lead3W;

    %TRP_tsreg_exret_VaR_RV(data=T_tmp_Wed_alpha_&alpha., exret=&exret., RegkeyVar=&RegkeyVar.,
        out=tsreg_&exret._&RegkeyVar., lag=&lag);

    data tsreg_&exret._&RegkeyVar._;
        length EstType $ 32;
        set tsreg_&exret._&RegkeyVar.;
        EstType = "&exret._&RegkeyVar.";
    run;

    %let exret = exret_lead1M;

    %TRP_tsreg_exret_VaR_RV(data=T_tmp_Wed_alpha_&alpha., exret=&exret., RegkeyVar=&RegkeyVar.,
        out=tsreg_&exret._&RegkeyVar., lag=&lag);

    data tsreg_&exret._&RegkeyVar._;
        length EstType $ 32;
        set tsreg_&exret._&RegkeyVar.;
        EstType = "&exret._&RegkeyVar.";
    run;

    %let exret = exret_lead2M;

    %TRP_tsreg_exret_VaR_RV(data=T_tmp_Wed_alpha_&alpha., exret=&exret., RegkeyVar=&RegkeyVar.,
        out=tsreg_&exret._&RegkeyVar., lag=&lag);

    data tsreg_&exret._&RegkeyVar._;
        length EstType $ 32;
        set tsreg_&exret._&RegkeyVar.;
        EstType = "&exret._&RegkeyVar.";
    run;

    %let exret = exret_lead3M;

    %TRP_tsreg_exret_VaR_RV(data=T_tmp_Wed_alpha_&alpha., exret=&exret., RegkeyVar=&RegkeyVar.,
        out=tsreg_&exret._&RegkeyVar., lag=&lag);

    data tsreg_&exret._&RegkeyVar._;
        length EstType $ 32;
        set tsreg_&exret._&RegkeyVar.;
        EstType = "&exret._&RegkeyVar.";
    run;

    %let exret = exret_lead6M;

    %TRP_tsreg_exret_VaR_RV(data=T_tmp_Wed_alpha_&alpha., exret=&exret., RegkeyVar=&RegkeyVar.,
        out=tsreg_&exret._&RegkeyVar., lag=&lag);

    data tsreg_&exret._&RegkeyVar._;
        length EstType $ 32;
        set tsreg_&exret._&RegkeyVar.;
        EstType = "&exret._&RegkeyVar.";
    run;

    data &out.;
        set tsreg_exret_lead1W_&RegkeyVar._ tsreg_exret_lead2W_&RegkeyVar._ tsreg_exret_lead3W_&RegkeyVar._
            tsreg_exret_lead1M_&RegkeyVar._  tsreg_exret_lead2M_&RegkeyVar._  tsreg_exret_lead3M_&RegkeyVar._
			tsreg_exret_lead6M_&RegkeyVar._;
    run;

    proc sql;
        drop table 
			tsreg_exret_lead1W_&RegkeyVar., tsreg_exret_lead2W_&RegkeyVar., tsreg_exret_lead3W_&RegkeyVar.,
            tsreg_exret_lead1M_&RegkeyVar.,  tsreg_exret_lead2M_&RegkeyVar.,  tsreg_exret_lead3M_&RegkeyVar.,
			tsreg_exret_lead6M_&RegkeyVar.,
            tsreg_exret_lead1W_&RegkeyVar._, tsreg_exret_lead2W_&RegkeyVar._, tsreg_exret_lead3W_&RegkeyVar._,
            tsreg_exret_lead1M_&RegkeyVar._,  tsreg_exret_lead2M_&RegkeyVar._,  tsreg_exret_lead3M_&RegkeyVar._,
			tsreg_exret_lead6M_&RegkeyVar._;
    quit;

%mend tsreg_LoopOnExret_RV;
