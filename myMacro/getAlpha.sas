%macro getAlpha(dsin, dsout, rankvar, depvar=exret_ld1M, MKTRF=MKTRF_ld1M, SMB=SMB_ld1M, HML=HML_ld1M, UMD=UMD_ld1M, groupby=, lags=6) / des="MEAN, CAPM, FF3F alpha.";

	proc sort data=&dsin.;
		by &groupby. Variable &rankvar.;
	run;

	/*Mean(exret), NW adjusted.*/
	proc model data=&dsin.;
		instruments a nObs / intonly;
		mean = a;
		N = nObs;
		fit mean N / gmm kernel=(bart, %eval(&lags.+1), 0) vardef=n;
		by &groupby. Variable &rankvar.;
		ods output parameterEstimates = pe_exret;
	run;

	/*CAPM*/
	proc model data=&dsin.;
		instruments a b;
		mean = a + b*&MKTRF.;
		fit mean / gmm kernel=(bart, %eval(&lags.+1), 0) vardef=n;
		by &groupby. Variable &rankvar.;
		ods output parameterEstimates = pe_CAPM;
		where Variable="&depvar.";
	run;

	/*FF3F*/
	proc model data=&dsin.;
		instruments a b c d;
		mean = a + b*&MKTRF. + c*&SMB. + d*&HML.;
		fit mean / gmm kernel=(bart, %eval(&lags.+1), 0) vardef=n;
		by &groupby. Variable &rankvar.;
		ods output parameterEstimates = pe_FF3F;
		where Variable="&depvar.";
	run;

	/*C4F*/
	proc model data=&dsin.;
		instruments a b c d e;
		mean = a + b*&MKTRF. + c*&SMB. + d*&HML. + e*&UMD.;
		fit mean / gmm kernel=(bart, %eval(&lags.+1), 0) vardef=n;
		by &groupby. Variable &rankvar.;
		ods output parameterEstimates = pe_C4F;
		where Variable="&depvar.";
	run;


	%let nRankVar = %sysfunc(countw(&rankvar., ' '));

	%if &nRankVar.=1 %then
		%do;

			proc sort data=pe_exret out=pe_exret;
				by &groupby. Variable Parameter;
			run;

			proc sort data=pe_CAPM out=pe_CAPM;
				by &groupby. Variable Parameter;
			run;

			proc sort data=pe_FF3F out=pe_FF3F;
				by &groupby. Variable Parameter;
			run;

			proc sort data=pe_C4F out=pe_C4F;
				by &groupby. Variable Parameter;
			run;

			proc transpose data=pe_exret out=pe_exret_(drop=_LABEL_ where=(_NAME_ in ("Estimate", "tValue"))) prefix=&rankvar._;
				id &rankvar.;
				by &groupby. Variable Parameter;
			run;

			proc transpose data=pe_CAPM out=pe_CAPM_(drop=_LABEL_ where=(_NAME_ in ("Estimate", "tValue"))) prefix=&rankvar._;
				id &rankvar.;
				by &groupby. Variable Parameter;
			run;

			proc transpose data=pe_FF3F out=pe_FF3F_(drop=_LABEL_ where=(_NAME_ in ("Estimate", "tValue"))) prefix=&rankvar._;
				id &rankvar.;
				by &groupby. Variable Parameter;
			run;

			proc transpose data=pe_C4F out=pe_C4F_(drop=_LABEL_ where=(_NAME_ in ("Estimate", "tValue"))) prefix=&rankvar._;
				id &rankvar.;
				by &groupby. Variable Parameter;
			run;

		%end;
	%else %if &nRankVar.=2 %then
		%do;
			%let RankVar1 = %scan(&RankVar., 1, ' ');
			%let RankVar2 = %scan(&RankVar., 2, ' ');

			proc sort data=pe_exret out=pe_exret;
				by &groupby. Variable Parameter &RankVar1.;
			run;

			proc sort data=pe_CAPM out=pe_CAPM;
				by &groupby. Variable Parameter &RankVar1.;
			run;

			proc sort data=pe_FF3F out=pe_FF3F;
				by &groupby. Variable Parameter &RankVar1.;
			run;

			proc sort data=pe_C4F out=pe_C4F;
				by &groupby. Variable Parameter &RankVar1.;
			run;

			proc transpose data=pe_exret out=pe_exret_(drop=_LABEL_ where=(_NAME_ in ("Estimate", "tValue"))) prefix=&RankVar2._;
				id &RankVar2.;
				by &groupby. Variable Parameter &RankVar1.;
			run;

			proc transpose data=pe_CAPM out=pe_CAPM_(drop=_LABEL_ where=(_NAME_ in ("Estimate", "tValue"))) prefix=&RankVar2._;
				id &RankVar2.;
				by &groupby. Variable Parameter &RankVar1.;
			run;

			proc transpose data=pe_FF3F out=pe_FF3F_(drop=_LABEL_ where=(_NAME_ in ("Estimate", "tValue"))) prefix=&RankVar2._;
				id &RankVar2.;
				by &groupby. Variable Parameter &RankVar1.;
			run;

			proc transpose data=pe_C4F out=pe_C4F_(drop=_LABEL_ where=(_NAME_ in ("Estimate", "tValue"))) prefix=&RankVar2._;
				id &RankVar2.;
				by &groupby. Variable Parameter &RankVar1.;
			run;

		%end;

	data pe_exret__;
		set pe_exret_;
		model = "mean";
	run;

	data pe_CAPM__;
		set pe_CAPM_;
		model = "CAPM";
	run;

	data pe_FF3F__;
		set pe_FF3F_;
		model = "FF3F";
	run;

	data pe_C4F__;
		set pe_C4F_;
		model = "C4F";
	run;

	data pe_mrgd;
		set pe_exret__ pe_CAPM__ pe_FF3F__ pe_C4F__;
		format _NUMERIC_ 10.4;
	run;

	proc sort data=pe_mrgd out=&dsout.;
		by &groupby. Variable _NAME_ Parameter;
	run;

	proc datasets lib=work nolist;
		delete pe:;
	quit;

%mend getAlpha;
