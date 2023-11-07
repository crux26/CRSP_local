%macro loop_local_uniSort(dsin, dsout, var, groupby=);
	proc sort data=&dsin. out=uniSort;
		by weight &groupby. Variable &var.;
	run;

	ods results off;
	ods graphics off;
	
	proc means data=uniSort StackOdsOutput mean t;
		id date;
		var mean n;
		ods output summary=uniSort_ret;
		by weight &groupby. Variable &var.;
	run;

	proc sort data=uniSort_ret out=uniSort_ret;
		by weight &groupby. Variable2 Variable &var.;
	run;

	proc sql noprint;
		select max(length(Variable)) into :varLen from uniSort_ret;
	quit;

	data &dsout.;
		length variable $ &varLen.;
		set uniSort_ret;
		by weight &groupby. Variable2 Variable &var. ;
	run;

	proc datasets lib=work nolist;
		delete uniSort_ret uniSort_char;
	quit;

%mend loop_local_uniSort;
