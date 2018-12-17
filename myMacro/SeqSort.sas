/*var1, var2: sortvar*/
/*vlist: independent variables.*/
%macro SeqSort(dsin, dsout, var1, var2, vlist_ret, nPF1, nPF2, dsout_T=, vlist_char=, groupby=, NYSE=);
	data tmp;
		set &dsin.;
		year = year(date);
		month = month(date);
	run;

	proc sort data=tmp out=tmp;
		by &groupby. year month;
	run;

	%if %lowcase(&var1.)=mktcap and ~%sysevalf(%superq(NYSE)=,boolean) %then
		%do;
			%if &nPF1.=3 %then
				%do;
					%let unitSize = 40;
					%let intvl_left = 30;
					%let intvl_right = 70;

					proc univariate data=tmp(where=(exchcd=1)) noprint;
						var &var1.;
						by &groupby. year month;
						output out=NYSE_brkpt pctlpre=brkpt pctlpts=%eval(&intvl_left.) to %eval(&intvl_right.) by %eval(&unitSize.);
					run;

					%let tmp_vlist = brkpt30 brkpt70;

					%hashmerge(largeds=tmp, smallds=NYSE_brkpt, byvars=&groupby. year month, extravars=&tmp_vlist., outds=tmp_);

					data tmp_rank;
						set tmp_;

						if MktCap <= brkpt30 then
							rank_&var1.=0;
						else if brkpt30 < MktCap <= brkpt70 then
							rank_&var1.=1;
						else if brkpt70 < MktCap then
							rank_&var1.=2;
						by &groupby. year month;
					run;

				%end;
			%else /*&PF1.~=3*/
				%do;
					%let unitSize = %eval(100/&nPF1.);
					%let intvl_left = %eval(&unitSize.);
					%let intvl_right = %eval(100-&unitSize.);

					proc univariate data=tmp(where=(exchcd=1)) noprint;
						var &var1.;
						by &groupby. year month;
						output out=NYSE_brkpt pctlpre=brkpt pctlpts=%eval(&intvl_left.) to %eval(&intvl_right.) by %eval(&unitSize.);
					run;

					%let prefix = brkpt;
					%let tmp_vlist =;

					%do i=1 %to %eval(&nPF1.-1);
						%let currVar = &prefix.%eval(&unitSize.*&i.);
						%let tmp_vlist = &tmp_vlist. &currVar.;
					%end;

					%hashmerge(largeds=tmp, smallds=NYSE_brkpt, byvars=&groupby. year month, extravars=&tmp_vlist., outds=tmp_);

					data tmp_rank;
						set tmp_;

						if MktCap <= brkpt%eval(&unitSize.) then
							rank_&var1.=0;

						%do i=2 %to %eval(&nPF1.-1);
						else if brkpt%eval(&unitSize.*(&i.-1)) < MktCap <= brkpt%eval(&unitSize.*(&i.)) then
							rank_&var1.=%eval(&i.-1);
						%end;
						else if brkpt%eval(&unitSize. * (&nPF1.-1)) < MktCap then
							rank_&var1.=%eval(&nPF1.-1);
						by &groupby. year month;
					run;

				%end;
		%end;
	%else /*~"%lowcase(&var1.)=mktcap and ~%sysevalf(%superq(NYSE)=,boolean)"*/
		%do;

			proc rank data=tmp out=tmp_rank(where=(~missing(rank_&var1.))) groups=&nPF1.;
				var &var1.;
				ranks rank_&var1.;
				by &groupby. year month;
			run;

		%end;

	proc sort data=tmp_rank out=tmp_rank;
		by &groupby. year month rank_&var1.;
	run;

		/*================================================================================*/
	%if %lowcase(&var2.)=mktcap and ~%sysevalf(%superq(NYSE)=,boolean) %then
		%do;
			%if &nPF2.=3 %then
				%do;
					%let unitSize = 40;
					%let intvl_left = 30;
					%let intvl_right = 70;

					proc univariate data=tmp_rank(where=(exchcd=1)) noprint;
						var &var2.;
						by &groupby. year month rank_&var1.;
						output out=NYSE_brkpt pctlpre=brkpt pctlpts=%eval(&intvl_left.) to %eval(&intvl_right.) by %eval(&unitSize.);
					run;

					%let tmp_vlist = brkpt30 brkpt70;

					%hashmerge(largeds=tmp_rank, smallds=NYSE_brkpt, byvars=&groupby. year month rank_&var1., extravars=&tmp_vlist., outds=tmp_rank_);

					data tmp_rank2;
						set tmp_rank_;

						if MktCap <= brkpt30 then
							rank_&var2.=0;
						else if brkpt30 < MktCap <= brkpt70 then
							rank_&var2.=1;
						else if brkpt70 < MktCap then
							rank_&var2.=2;
						by &groupby. year month rank_&var1.;
					run;

				%end;
			%else /*&PF1.~=3*/
				%do;
					%let unitSize = %eval(100/&nPF2.);
					%let intvl_left = %eval(&unitSize.);
					%let intvl_right = %eval(100-&unitSize.);

					proc univariate data=tmp_rank(where=(exchcd=1)) noprint;
						var &var2.;
						by &groupby. year month rank_&var1.;
						output out=NYSE_brkpt pctlpre=brkpt pctlpts=%eval(&intvl_left.) to %eval(&intvl_right.) by %eval(&unitSize.);
					run;

					%let prefix = brkpt;
					%let tmp_vlist =;

					%do i=1 %to %eval(&nPF2.-1);
						%let currVar = &prefix.%eval(&unitSize.*&i.);
						%let tmp_vlist = &tmp_vlist. &currVar.;
					%end;

					%hashmerge(largeds=tmp_rank, smallds=NYSE_brkpt, byvars=&groupby. year month rank_&var1., extravars=&tmp_vlist., outds=tmp_rank_);

					data tmp_rank2;
						set tmp_rank_;

						if MktCap <= brkpt%eval(&unitSize.) then
							rank_&var2.=0;

						%do i=2 %to %eval(&nPF2.-1);
						else if brkpt%eval(&unitSize.*(&i.-1)) < MktCap <= brkpt%eval(&unitSize.*(&i.)) then
							rank_&var2.=%eval(&i.-1);
						%end;
						else if brkpt%eval(&unitSize. * (&nPF2.-1)) < MktCap then
							rank_&var2.=%eval(&nPF2.-1);
						by &groupby. year month rank_&var1.;
					run;

				%end;
		%end;
	%else
		%do;

			proc rank data=tmp_rank out=tmp_rank2(where=(~missing(rank_&var2.))) groups=&nPF2.;
				var &var2.;
				ranks rank_&var2.;
				by &groupby. year month rank_&var1.;
			run;

		%end;

	/*================================================================================*/
	/*W/o winsorizing, bm_comp contains crazy extreme values.*/
	/*Winsorize other variables as well.*/
	/*%WINSORIZE(INSET=tmp_rank2, OUTSET=tmp_rank2, SORTVAR=date, VARS=SIZE BM, PERC1=1, TRIM=0);*/
	/*5m (LAB)*/
	proc sort data=tmp_rank2 out=tmp_rank2;
		by &groupby. date rank_&var1. rank_&var2.;
	run;

	options nonotes nosource nosource2 errors=0;

	proc printto log=junk;
	run;

	ods results off;
	proc means data=tmp_rank2 StackOdsOutput mean n;
		var &vlist_ret.;
		by &groupby. date rank_&var1. rank_&var2.;
		ods output summary=_EW_SeqSort_ret;
	run;

	proc sort data=_EW_SeqSort_ret out=_EW_SeqSort_ret;
		by &groupby. Variable;
	run;

	data _EW_SeqSort_ret_;
		set _EW_SeqSort_ret;
		weight = "EW";
	run;

	proc means data=tmp_rank2 StackOdsOutput mean n;
		var &vlist_ret.;
		weight MktCap;
		by &groupby. date rank_&var1. rank_&var2.;
		ods output summary=_VW_SeqSort_ret;
	run;

	proc sort data=_VW_SeqSort_ret out=_VW_SeqSort_ret;
		by &groupby. Variable;
	run;

	data _VW_SeqSort_ret_;
		set _VW_SeqSort_ret;
		weight = "VW";
	run;

	data _SeqSort_ret;
		set _EW_SeqSort_ret_ _VW_SeqSort_ret_;
	run;

	%if ~%sysevalf(%superq(vlist_char)=,boolean) %then
		%do;
			ods results off;
			proc means data=tmp_rank2 StackOdsOutput mean n;
				var &vlist_char.;
				by &groupby. date rank_&var1. rank_&var2.;
				ods output summary=_SeqSort_char;
			run;

			proc sort data=_SeqSort_char out=_SeqSort_char;
				by &groupby. Variable;
			run;

			proc sql noprint;
				select max(length(Variable)) into :varLen1 from _SeqSort_ret;
			quit;

			proc sql noprint;
				select max(length(Variable)) into :varLen2 from _SeqSort_char;
			quit;

				%let varLen = %sysfunc(max(&varLen1., &varLen2.));

			data _SeqSort;
				length Variable $ &varLen.;
				set _SeqSort_ret _SeqSort_char;
			run;

		%end;
	%else
		%do;
			proc datasets lib=work nolist;
				change _SeqSort_ret = _SeqSort;
			quit;

		%end;

	proc printto;
	run;

	options notes source source2 errors=20;

	/*====*/
	proc sort data=_SeqSort out=_SeqSort(where=(~missing(Mean) and ~missing(rank_&var1.) and ~missing(rank_&var2.)));
		by weight &groupby. Variable date rank_&var2.;
	run;

	proc transpose data=_SeqSort out=_SeqSort prefix=rank_&var1._;
		id rank_&var1.;
		by weight &groupby. Variable date rank_&var2.;
	run;

	data _SeqSort_;
		set _SeqSort;
		rank_&var1._diff = rank_&var1._%eval(&nPF1.-1) - rank_&var1._0;
		rank_&var1._avg = mean(of rank_&var1._:);
	run;

	proc transpose data=_SeqSort_ out=_SeqSort__;
		id _NAME_;
		by weight &groupby. Variable date rank_&var2.;
	run;

	%let var1_len = %sysfunc(countw(&var1., '_'));

	data _SeqSort___;
		retain date _NAME_ rank_&var2.;
		set _SeqSort__;
		_NAME_ = scan(_NAME_, %eval(&var1_len.+2), '_');
		rename _NAME_ = rank_&var1.;
	run;

	proc sort data=_SeqSort___ out=_SeqSort___;
		by weight &groupby. Variable date rank_&var1. rank_&var2.;
	run;

	proc transpose data=_SeqSort___ out=_SeqSort____ prefix=rank_&var2._;
		id rank_&var2.;
		by weight &groupby. Variable date rank_&var1.;
	run;

	data _SeqSort_____;
		set _SeqSort____;
		rank_&var2._diff = rank_&var2._%eval(&nPF2.-1) - rank_&var2._0;
		rank_&var2._avg = mean(of rank_&var2._:);
	run;

	proc transpose data=_SeqSort_____ out=_SeqSort______;
		id _NAME_;
		by weight &groupby. Variable date rank_&var1.;
	run;

	%let var2_len = %sysfunc(countw(&var2., '_'));

	data _SeqSort_______;
		retain date rank_&var1. _NAME_;
		set _SeqSort______;
		_NAME_ = scan(_NAME_, %eval(&var2_len.+2), '_');
		rename _NAME_ = rank_&var2.;
	run;

	proc sort data=_SeqSort_______ out=&dsout.;
		by weight &groupby. Variable date rank_&var1. rank_&var2.;
	run;

	%if ~%sysevalf(%superq(dsout_T)=,boolean) %then
		%do;
			proc sort data=&dsout. out=_SeqSort;
				by weight &groupby. Variable rank_&var1. rank_&var2.;
			run;

			%let vlist = &vlist_ret. &vlist_char.;
			
			ods results off;
			proc means data=_SeqSort StackOdsOutput mean t n;
				var mean n;
				by weight &groupby. Variable rank_&var1. rank_&var2.;
				ods output Summary=_SeqSort_mean;
			run;

			proc sort data=_SeqSort_mean out=_SeqSort_mean;
				by weight &groupby. Variable Variable2 rank_&var1. rank_&var2.;
			run;

			%macro loop(vlist);
				%let nVar = %sysfunc(countw(&vlist, ' '));
				%let FirstVar = %scan(&vlist, 1, ' ');

				%do i=1 %to &nVar;
					%let currVar = %scan(&vlist, &i, ' ');

					proc transpose data=_SeqSort_mean out=_&currVar._ prefix=rank_&var2._;
						id rank_&var2.;
						by weight &groupby. Variable Variable2 rank_&var1.;
						where Variable = "&currVar.";
					run;

					data _&currVar.;
						set _&currVar._;
						Variable = "&currVar.";
					run;

					proc sort data=_&currVar. out=_&currVar.;
						by weight &groupby. Variable2 _NAME_ Variable rank_&var1.;
					run;

					proc datasets lib=work nolist;
						delete _&currVar._;
					quit;

				%end;
			%mend loop;

			%loop(&vlist);

			/*Below copied from https://communities.sas.com/t5/SAS-Programming/append-text-to-words-in-a-string/td-p/42483*/
			%let vlist_ = %sysfunc( prxchange(s/(\w+)/_$1/, -1, &vlist) );
			%put &=vlist_;

			data final;
				length _NAME_ $ 8 Variable $ 20;
				set &vlist_;
				format _NUMERIC_ 10.4;
			run;

			proc sort data=final out=&dsout_T.(drop=_LABEL_);
				by weight &groupby. Variable2 _NAME_ Variable rank_&var1.;
			run;

		%end;

	proc datasets lib=work nolist;
		delete NYSE: tmp: _: final;
	quit;

%mend SeqSort;
