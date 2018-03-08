%macro tsreg_exret_TailRV_Lin(data=, DepVarList=, IndepVarList=, out_prefix=, lag=);
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
				exogenous &DepVar. &IndepVar. VRP; *VRP=VIX - RV;
				&DepVar. = a + b*&IndepVar. + c*VRP;
				fit &DepVar. / gmm kernel=(bart, %eval(&lag.+1), 0) vardef=n;
				test a=0, b=1;
				test a=0;
				test b=1;
				ods output parameterEstimates=tsreg_&DepVar._&IndepVar.;
				ods output ResidSummary=tsreg_&DepVar._&IndepVar.Rsq;
				ods output TestResults=tsreg_&DepVar._&IndepVar.test;
			run;

			quit;

			data tsreg_&DepVar._&IndepVar._;
				length EstType $ 32;
				set tsreg_&DepVar._&IndepVar.;
				EstType = "&DepVar._&IndepVar.";
			run;

			data tsreg_&DepVar._&IndepVar.Rsq_;
				length EstType $ 32;
				set tsreg_&DepVar._&IndepVar.Rsq;
				EstType = "&DepVar._&IndepVar.";
			run;

			data tsreg_&DepVar._&IndepVar.test_;
				length EstType $ 32;
				set tsreg_&DepVar._&IndepVar.test;
				EstType = "&DepVar._&IndepVar.";
			run;

		%end;

		data &out_prefix.&IndepVar.;
			set tsreg_exret_lead1W_&IndepVar._ tsreg_exret_lead2W_&IndepVar._ tsreg_exret_lead3W_&IndepVar._
				tsreg_exret_lead1M_&IndepVar._  tsreg_exret_lead2M_&IndepVar._  tsreg_exret_lead3M_&IndepVar._
				tsreg_exret_lead6M_&IndepVar._;
		run;

		data &out_prefix.&IndepVar.Rsq;
			set tsreg_exret_lead1W_&IndepVar.Rsq_ tsreg_exret_lead2W_&IndepVar.Rsq_ tsreg_exret_lead3W_&IndepVar.Rsq_
				tsreg_exret_lead1M_&IndepVar.Rsq_  tsreg_exret_lead2M_&IndepVar.Rsq_  tsreg_exret_lead3M_&IndepVar.Rsq_
				tsreg_exret_lead6M_&IndepVar.Rsq_;
		run;

		data &out_prefix.&IndepVar.test;
			set tsreg_exret_lead1W_&IndepVar.test_ tsreg_exret_lead2W_&IndepVar.test_ tsreg_exret_lead3W_&IndepVar.test_
				tsreg_exret_lead1M_&IndepVar.test_  tsreg_exret_lead2M_&IndepVar.test_  tsreg_exret_lead3M_&IndepVar.test_
				tsreg_exret_lead6M_&IndepVar.test_;
		run;

/**/
		proc sql;
			drop table 
				tsreg_exret_lead1W_&IndepVar., tsreg_exret_lead2W_&IndepVar., tsreg_exret_lead3W_&IndepVar.,
				tsreg_exret_lead1M_&IndepVar.,  tsreg_exret_lead2M_&IndepVar.,  tsreg_exret_lead3M_&IndepVar.,
				tsreg_exret_lead6M_&IndepVar.,
				tsreg_exret_lead1W_&IndepVar._, tsreg_exret_lead2W_&IndepVar._, tsreg_exret_lead3W_&IndepVar._,
				tsreg_exret_lead1M_&IndepVar._,  tsreg_exret_lead2M_&IndepVar._,  tsreg_exret_lead3M_&IndepVar._,
				tsreg_exret_lead6M_&IndepVar._;
		quit;

		proc sql;
			drop table 
				tsreg_exret_lead1W_&IndepVar.Rsq, tsreg_exret_lead2W_&IndepVar.Rsq, tsreg_exret_lead3W_&IndepVar.Rsq,
				tsreg_exret_lead1M_&IndepVar.Rsq,  tsreg_exret_lead2M_&IndepVar.Rsq,  tsreg_exret_lead3M_&IndepVar.Rsq,
				tsreg_exret_lead6M_&IndepVar.Rsq,
				tsreg_exret_lead1W_&IndepVar.Rsq_, tsreg_exret_lead2W_&IndepVar.Rsq_, tsreg_exret_lead3W_&IndepVar.Rsq_,
				tsreg_exret_lead1M_&IndepVar.Rsq_,  tsreg_exret_lead2M_&IndepVar.Rsq_,  tsreg_exret_lead3M_&IndepVar.Rsq_,
				tsreg_exret_lead6M_&IndepVar.Rsq_;
		quit;


		proc sql;
			drop table 
				tsreg_exret_lead1W_&IndepVar.test, tsreg_exret_lead2W_&IndepVar.test, tsreg_exret_lead3W_&IndepVar.test,
				tsreg_exret_lead1M_&IndepVar.test,  tsreg_exret_lead2M_&IndepVar.test,  tsreg_exret_lead3M_&IndepVar.test,
				tsreg_exret_lead6M_&IndepVar.test,
				tsreg_exret_lead1W_&IndepVar.test_, tsreg_exret_lead2W_&IndepVar.test_, tsreg_exret_lead3W_&IndepVar.test_,
				tsreg_exret_lead1M_&IndepVar.test_,  tsreg_exret_lead2M_&IndepVar.test_,  tsreg_exret_lead3M_&IndepVar.test_,
				tsreg_exret_lead6M_&IndepVar.test_;
		quit;



	%end;
%mend tsreg_exret_TailRV_Lin;
