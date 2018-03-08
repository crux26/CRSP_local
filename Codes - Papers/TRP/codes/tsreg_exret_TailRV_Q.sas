%macro tsreg_exret_TailRV_Q(data=, DepVarList=, IndepVarList=, out=, lag=);
	%let nwords=%sysfunc(countw(&IndepVarList));

	%do i=1 %to &nwords;
		%let IndepVar = %scan(&IndepVarList, &i);
		%put &=IndepVar;
		%put &=DepVarList;
		%let nwords=%sysfunc(countw(&DepVarList));

		%do j=1 %to &nwords;
			%let DepVar = %scan(&DepVarList, &j);

/*------------------------------------------------------------------------------*/
			proc quantreg data=&data. outest=&out.;
			model &DepVar. = &IndepVar. VIX-RV / quantile=0.05 0.5 0.95;
			run;

/*			proc model data=&data.;*/
/*				parms a b c;*/
/*				exogenous &DepVar. &IndepVar. VIX RV;*/
/*				&DepVar. = a + b*&IndepVar. + c*(VIX-RV);*/
/*				fit &DepVar. / gmm kernel=(bart, %eval(&lag.+1), 0) vardef=n;*/
/*				ods output parameterEstimates=&out.;*/
/*			run;*/
/*------------------------------------------------------------------------------*/
			quit;

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

	%end;
%mend tsreg_exret_TailRV_Q;
