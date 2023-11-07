%macro unisort(dsin, dsout, var, vlist_ret, nPF, dsout_T=, vlist_char=, groupby=, NYSE=);
	data tmp;
		set &dsin.;
		year = year(date);
		month = month(date);
	run;

	proc sort data=tmp out=tmp;
		by &groupby. year month;
	run;

	%if %lowcase(&var.)=mktcap and ~%sysevalf(%superq(NYSE)=,boolean) %then
		%do;
			%if &nPF.=3 %then
				%do;
					%let unitSize = 40;
					%let intvl_left = 30;
					%let intvl_right = 70;

					proc univariate data=tmp(where=(exchcd=1)) noprint;
						var &var.;
						by &groupby. year month;
						output out=NYSE_brkpt pctlpre=brkpt pctlpts=%eval(&intvl_left.) to %eval(&intvl_right.) by %eval(&unitSize.);
					run;

					%let tmp_vlist = brkpt30 brkpt70;

					%hashmerge(largeds=tmp, smallds=NYSE_brkpt, byvars=&groupby. year month, extravars=&tmp_vlist., outds=tmp_);

					data tmp_rank;
						set tmp_;

						if MktCap <= brkpt30 then
							rank_&var.=0;
						else if brkpt30 < MktCap <= brkpt70 then
							rank_&var.=1;
						else if brkpt70 < MktCap then
							rank_&var.=2;
						by &groupby. year month;
					run;

				%end;
			%else /*&PF1.~=3*/
				%do;
					%let unitSize = %eval(100/&nPF.);
					%let intvl_left = %eval(&unitSize.);
					%let intvl_right = %eval(100-&unitSize.);

					proc univariate data=tmp(where=(exchcd=1)) noprint;
						var &var.;
						by &groupby. year month;
						output out=NYSE_brkpt pctlpre=brkpt pctlpts=%eval(&intvl_left.) to %eval(&intvl_right.) by %eval(&unitSize.);
					run;

					%let prefix = brkpt;
					%let tmp_vlist =;

					%do i=1 %to %eval(&nPF.-1);
						%let currVar = &prefix.%eval(&unitSize.*&i.);
						%let tmp_vlist = &tmp_vlist. &currVar.;
					%end;

					%hashmerge(largeds=tmp, smallds=NYSE_brkpt, byvars=&groupby. year month, extravars=&tmp_vlist., outds=tmp_);

					data tmp_rank;
						set tmp_;

						if MktCap <= brkpt%eval(&unitSize.) then
							rank_&var.=0;

						%do i=2 %to %eval(&nPF.-1);
						else if brkpt%eval(&unitSize.*(&i.-1)) < MktCap <= brkpt%eval(&unitSize.*(&i.)) then
							rank_&var.=%eval(&i.-1);
						%end;
						else if brkpt%eval(&unitSize. * (&nPF.-1)) < MktCap then
							rank_&var.=%eval(&nPF.-1);
						by &groupby. year month;
					run;

				%end;
		%end;
	%else /*~"%lowcase(&var.)=mktcap and ~%sysevalf(%superq(NYSE)=,boolean)"*/
		%do;

			proc rank data=tmp out=tmp_rank(where=(~missing(rank_&var.))) groups=&nPF.;
				var &var.;
				ranks rank_&var.;
				by &groupby. year month;
			run;

		%end;

		/*Winsorizing MktCap affects _&PF_weight. ret/exret weighted by MktCap; do not winsorize it, but SIZE only.*/
		/*Winsorized w.r.t. SORTVAR.*/
		/*%WINSORIZE(INSET=tmp_rank, OUTSET=tmp_rank, SORTVAR=date, VARS=SIZE BM, PERC1=1, TRIM=0);*/
		/*5m (LAB)*/
		proc sort data=tmp_rank out=tmp_rank;
			by &groupby. date rank_&var.;
		run;

		options nonotes nosource nosource2 errors=0;

		proc printto log=junk;
		run;

		ods results off;
		proc means data=tmp_rank StackOdsoutput mean n;
			var &vlist_ret.;
			by &groupby. date rank_&var.;
			ods output summary=_EW_spread_ret;
		run;

		proc sort data=_EW_spread_ret out=_EW_spread_ret;
			by &groupby. Variable;
		run;

		data _EW_spread_ret_;
			set _EW_spread_ret;
			weight = "EW";
		run;

		proc means data=tmp_rank StackOdsoutput mean n;
			var &vlist_ret.;
			weight MktCap;
			by &groupby. date rank_&var.;
			ods output summary=_VW_spread_ret;
		run;

		proc sort data=_VW_spread_ret out=_VW_spread_ret;
			by &groupby. Variable;
		run;

		data _VW_spread_ret_;
			set _VW_spread_ret;
			weight = "VW";
		run;

		data _spread_ret;
			set _EW_spread_ret_ _VW_spread_ret_;
		run;

		%if ~%sysevalf(%superq(vlist_char)=,boolean) %then
			%do;
				ods results off;
				proc means data=tmp_rank stackodsoutput mean n;
					var &vlist_char.;
					by &groupby. date rank_&var.;
					ods output summary=_spread_char;
				run;

				proc sort data=_spread_char out=_spread_char;
					by &groupby. Variable;
				run;

				proc sql noprint;
					select max(length(Variable)) into :varLen1 from _spread_ret;
				quit;

				proc sql noprint;
					select max(length(Variable)) into :varLen2 from _spread_char;
				quit;

				%let varLen = %sysfunc(max(&varLen1., &varLen2.));

				data _spread;
					length Variable $ &varLen.;
					set _spread_ret _spread_char;
				run;

			%end;
		%else
			%do;

				proc datasets lib=work nolist;
					change _spread_ret=_spread;
				quit;

			%end;

		proc printto;
		run;

		options notes source source2 errors=20;

		proc sort data=_spread out=_spread(where=(~missing(Mean) and ~missing(rank_&var.)));
			by weight &groupby. Variable date rank_&var.;
		run;

		/*====*/
		proc transpose data=_spread out=_spread_ prefix=rank_&var._;
			id rank_&var.;
			by weight &groupby. Variable date;
		run;

		data _spread__;
			set _spread_;
			rank_&var._diff = rank_&var._%eval(&nPF.-1) - rank_&var._0;
			rank_&var._avg = mean(of rank_&var._:);
		run;

		proc transpose data=_spread__ out=_spread___;
			id _NAME_;
			by weight &groupby. Variable date;
		run;

		%let var_len = %sysfunc(countw(&var., '_'));

		data _spread____;
			set _spread___;
			_NAME_ = scan(_NAME_, %eval(&var_len.+2), '_');
			rename _NAME_ = rank_&var.;
		run;

		proc sort data=_spread____ out=&dsout.;
			by weight &groupby. Variable date rank_&var.;
		run;

		%if ~%sysevalf(%superq(dsout_T)=,boolean) %then
			%do;
				proc sort data=&dsout. out=_spread____;
					by weight &groupby. Variable rank_&var.;
				run;

				%let vlist = &vlist_ret. &vlist_char.;

				ods results off;
				proc means data=_spread____ StackOdsOutput mean t;
					var mean n;
					by weight &groupby. Variable rank_&var.;
					ods output summary=_spread_mean;
				run;

				proc sort data=_spread_mean out=_spread_mean;
					by weight &groupby. Variable Variable2 rank_&var.;
				run;

				%macro loop(vlist);
					%let nVar = %sysfunc(countw(&vlist, ' '));
					%let FirstVar = %scan(&vlist, 1, ' ');

					%do i=1 %to &nVar;
						%let currVar = %scan(&vlist, &i, ' ');

						proc transpose data=_spread_mean out=_&currVar._ PREFIX=rank_&var._;
							id rank_&var.;
							by weight &groupby. Variable Variable2;
							where Variable = "&currVar.";
						run;

						data _&currVar.;
							set _&currVar._;
							Variable = "&currVar.";
						run;

						proc sort data=_&currVar. out=_&currVar.;
							by weight &groupby. Variable2 _NAME_;
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
					by weight &groupby. Variable2 _NAME_;
				run;
			%end;
		
	proc datasets lib=work nolist;
		delete NYSE: tmp: _: final;
	quit;

%mend unisort;
