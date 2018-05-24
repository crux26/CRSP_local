%macro tsreg_exret_logTailRV_Lin(data=, keyvar=, DepVarList=, IndepVarList=, out_prefix=, lag=);
	%let nwords=%sysfunc(countw(&IndepVarList));

	%do i=1 %to &nwords;
		%let IndepVar = %scan(&IndepVarList, &i);
		%put &=IndepVar;
		%put &=DepVarList;
		%let nwords_=%sysfunc(countw(&DepVarList));

		%do j=1 %to &nwords_;
			%let DepVar = %scan(&DepVarList, &j);

			proc model data=&data.;
				parms a b c;
/*				exogenous &DepVar. &IndepVar. &keyvar.; *log_VRP=log_VIX - log_RV;*/
				exogenous &IndepVar. &keyvar.; *log_VRP=log_VIX - log_RV;
				&DepVar. = a + b*&IndepVar. + c*&keyvar.;
				fit &DepVar. / gmm kernel=(bart, %eval(&lag.+1), 0) vardef=n;
				test a=0, b=1;
				test a=0;
				test b=1;
				ods output parameterEstimates=&DepVar._&IndepVar.;
				ods output ResidSummary=&DepVar._&IndepVar.Rsq;
				ods output TestResults=&DepVar._&IndepVar.test;
			run;

			quit;

			data &DepVar._&IndepVar._;
				length EstType $ 32;
				set &DepVar._&IndepVar.;
				EstType = "&DepVar._&IndepVar.";
			run;

			data &DepVar._&IndepVar.Rsq_;
				length EstType $ 32;
				set &DepVar._&IndepVar.Rsq;
				EstType = "&DepVar._&IndepVar.";
			run;

			data &DepVar._&IndepVar.test_;
				length EstType $ 32;
				set &DepVar._&IndepVar.test;
				EstType = "&DepVar._&IndepVar.";
			run;

		%end;
		
		%let depvar_prefix = %sysfunc(scan( %sysfunc(scan(&DepVarList, 1, ' ')), 1, '_' ) );
		/*Above would be "exret" or "sprtrn" or similar sorts.*/
		data &out_prefix.&IndepVar.;
			set &depvar_prefix._lead1W_&IndepVar._ &depvar_prefix._lead2W_&IndepVar._ &depvar_prefix._lead3W_&IndepVar._
				&depvar_prefix._lead1M_&IndepVar._  &depvar_prefix._lead2M_&IndepVar._  &depvar_prefix._lead3M_&IndepVar._
				&depvar_prefix._lead6M_&IndepVar._;
		run;

		data &out_prefix.&IndepVar.Rsq;
			set &depvar_prefix._lead1W_&IndepVar.Rsq_ &depvar_prefix._lead2W_&IndepVar.Rsq_ &depvar_prefix._lead3W_&IndepVar.Rsq_
				&depvar_prefix._lead1M_&IndepVar.Rsq_  &depvar_prefix._lead2M_&IndepVar.Rsq_  &depvar_prefix._lead3M_&IndepVar.Rsq_
				&depvar_prefix._lead6M_&IndepVar.Rsq_;
		run;

		data &out_prefix.&IndepVar.test;
			set &depvar_prefix._lead1W_&IndepVar.test_ &depvar_prefix._lead2W_&IndepVar.test_ &depvar_prefix._lead3W_&IndepVar.test_
				&depvar_prefix._lead1M_&IndepVar.test_  &depvar_prefix._lead2M_&IndepVar.test_  &depvar_prefix._lead3M_&IndepVar.test_
				&depvar_prefix._lead6M_&IndepVar.test_;
		run;

/**/
		proc sql;
			drop table 
				&depvar_prefix._lead1W_&IndepVar., &depvar_prefix._lead2W_&IndepVar., &depvar_prefix._lead3W_&IndepVar.,
				&depvar_prefix._lead1M_&IndepVar.,  &depvar_prefix._lead2M_&IndepVar.,  &depvar_prefix._lead3M_&IndepVar.,
				&depvar_prefix._lead6M_&IndepVar.,
				&depvar_prefix._lead1W_&IndepVar._, &depvar_prefix._lead2W_&IndepVar._, &depvar_prefix._lead3W_&IndepVar._,
				&depvar_prefix._lead1M_&IndepVar._,  &depvar_prefix._lead2M_&IndepVar._,  &depvar_prefix._lead3M_&IndepVar._,
				&depvar_prefix._lead6M_&IndepVar._;
		quit;

		proc sql;
			drop table 
				&depvar_prefix._lead1W_&IndepVar.Rsq, &depvar_prefix._lead2W_&IndepVar.Rsq, &depvar_prefix._lead3W_&IndepVar.Rsq,
				&depvar_prefix._lead1M_&IndepVar.Rsq,  &depvar_prefix._lead2M_&IndepVar.Rsq,  &depvar_prefix._lead3M_&IndepVar.Rsq,
				&depvar_prefix._lead6M_&IndepVar.Rsq,
				&depvar_prefix._lead1W_&IndepVar.Rsq_, &depvar_prefix._lead2W_&IndepVar.Rsq_, &depvar_prefix._lead3W_&IndepVar.Rsq_,
				&depvar_prefix._lead1M_&IndepVar.Rsq_,  &depvar_prefix._lead2M_&IndepVar.Rsq_,  &depvar_prefix._lead3M_&IndepVar.Rsq_,
				&depvar_prefix._lead6M_&IndepVar.Rsq_;
		quit;


		proc sql;
			drop table 
				&depvar_prefix._lead1W_&IndepVar.test, &depvar_prefix._lead2W_&IndepVar.test, &depvar_prefix._lead3W_&IndepVar.test,
				&depvar_prefix._lead1M_&IndepVar.test,  &depvar_prefix._lead2M_&IndepVar.test,  &depvar_prefix._lead3M_&IndepVar.test,
				&depvar_prefix._lead6M_&IndepVar.test,
				&depvar_prefix._lead1W_&IndepVar.test_, &depvar_prefix._lead2W_&IndepVar.test_, &depvar_prefix._lead3W_&IndepVar.test_,
				&depvar_prefix._lead1M_&IndepVar.test_,  &depvar_prefix._lead2M_&IndepVar.test_,  &depvar_prefix._lead3M_&IndepVar.test_,
				&depvar_prefix._lead6M_&IndepVar.test_;
		quit;



	%end;
%mend tsreg_exret_logTailRV_Lin;
