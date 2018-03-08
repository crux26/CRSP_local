%macro tsreg_exret_logTailRV_Lin(data=, DepVarList=, IndepVarList=, out_prefix=, lag=);
	%let nwords=%sysfunc(countw(&IndepVarList));

	%do i=1 %to &nwords;
		%let IndepVar = %scan(&IndepVarList, &i);
		%put &=IndepVar;
		%put &=DepVarList;
		%let nwords=%sysfunc(countw(&DepVarList));

		%do j=1 %to &nwords;
			%let DepVar = %scan(&DepVarList, &j);

			proc model data=&data.;
				parms a b c;
				exogenous &DepVar. &IndepVar. log_VRP; *log_VRP=log_VIX - log_RV;
				&DepVar. = a + b*&IndepVar. + c*log_VRP;
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

		data &out_prefix.&IndepVar.;
			set exret_lead1W_&IndepVar._ exret_lead2W_&IndepVar._ exret_lead3W_&IndepVar._
				exret_lead1M_&IndepVar._  exret_lead2M_&IndepVar._  exret_lead3M_&IndepVar._
				exret_lead6M_&IndepVar._;
		run;

		data &out_prefix.&IndepVar.Rsq;
			set exret_lead1W_&IndepVar.Rsq_ exret_lead2W_&IndepVar.Rsq_ exret_lead3W_&IndepVar.Rsq_
				exret_lead1M_&IndepVar.Rsq_  exret_lead2M_&IndepVar.Rsq_  exret_lead3M_&IndepVar.Rsq_
				exret_lead6M_&IndepVar.Rsq_;
		run;

		data &out_prefix.&IndepVar.test;
			set exret_lead1W_&IndepVar.test_ exret_lead2W_&IndepVar.test_ exret_lead3W_&IndepVar.test_
				exret_lead1M_&IndepVar.test_  exret_lead2M_&IndepVar.test_  exret_lead3M_&IndepVar.test_
				exret_lead6M_&IndepVar.test_;
		run;

/**/
		proc sql;
			drop table 
				exret_lead1W_&IndepVar., exret_lead2W_&IndepVar., exret_lead3W_&IndepVar.,
				exret_lead1M_&IndepVar.,  exret_lead2M_&IndepVar.,  exret_lead3M_&IndepVar.,
				exret_lead6M_&IndepVar.,
				exret_lead1W_&IndepVar._, exret_lead2W_&IndepVar._, exret_lead3W_&IndepVar._,
				exret_lead1M_&IndepVar._,  exret_lead2M_&IndepVar._,  exret_lead3M_&IndepVar._,
				exret_lead6M_&IndepVar._;
		quit;

		proc sql;
			drop table 
				exret_lead1W_&IndepVar.Rsq, exret_lead2W_&IndepVar.Rsq, exret_lead3W_&IndepVar.Rsq,
				exret_lead1M_&IndepVar.Rsq,  exret_lead2M_&IndepVar.Rsq,  exret_lead3M_&IndepVar.Rsq,
				exret_lead6M_&IndepVar.Rsq,
				exret_lead1W_&IndepVar.Rsq_, exret_lead2W_&IndepVar.Rsq_, exret_lead3W_&IndepVar.Rsq_,
				exret_lead1M_&IndepVar.Rsq_,  exret_lead2M_&IndepVar.Rsq_,  exret_lead3M_&IndepVar.Rsq_,
				exret_lead6M_&IndepVar.Rsq_;
		quit;


		proc sql;
			drop table 
				exret_lead1W_&IndepVar.test, exret_lead2W_&IndepVar.test, exret_lead3W_&IndepVar.test,
				exret_lead1M_&IndepVar.test,  exret_lead2M_&IndepVar.test,  exret_lead3M_&IndepVar.test,
				exret_lead6M_&IndepVar.test,
				exret_lead1W_&IndepVar.test_, exret_lead2W_&IndepVar.test_, exret_lead3W_&IndepVar.test_,
				exret_lead1M_&IndepVar.test_,  exret_lead2M_&IndepVar.test_,  exret_lead3M_&IndepVar.test_,
				exret_lead6M_&IndepVar.test_;
		quit;



	%end;
%mend tsreg_exret_logTailRV_Lin;
