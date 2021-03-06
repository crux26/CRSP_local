%macro tsreg_exret(data=, out=, DepVar=, IndepVarList=, alpha=);

    proc sql;
        create table crsp_TRP_alpha_&alpha.
            as select distinct a.*, b.VaR_, b.ES_, b.UP_, b.EUP_, b.TRP_, b.ETRP_
            from
                &data. as a
            left join
                TRP.TRP_resultTable_alpha_&alpha. as b
                on a.date = b.date
            order by date;
    quit;

    data crsp_TRP_alpha_&alpha._;
        set crsp_TRP_alpha_&alpha.;

        if missing(VaR_) then
            delete;
    run;

    proc sort data=crsp_TRP_alpha_&alpha._ 
        out=crsp_TRP_alpha_&alpha.__ nodupkey;
        by permno date;
    run;

    proc printto log=junk;
    run;

	%let nwords = %sysfunc(countw(&IndepVarList.));	
	%do i=1 %to &nwords;
		%let RegkeyVar = %scan(&IndepVarList., &i.);
		
		%let IndepVars = mkt_rf_1M &RegkeyVar.;

		%RRLOOP(data=crsp_TRP_alpha_&alpha.__, out_ds=&out._&RegkeyVar.,
		model_equation=&DepVar.=&IndepVars., id=permno, 
		date=date, start_date='01jan1995'd, end_date='31dec2015'd,
		freq=month, step=3, n=3, regprint=noprint, minwin=10);

	%end;
    proc printto;
    run;

%mend tsreg_exret;
