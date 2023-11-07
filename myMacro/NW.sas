%macro NW(vlist, dsin, dsout, by=weight &groupby. Variable rank_&var., lags=5);
%let plist = _%sysfunc(tranwrd(%quote(&vlist), %str( ), %str( _) ));
proc model data=&dsin.;
	instruments / intonly;
	parms &plist;
	%do i=1 %to %sysfunc(countw(&vlist, ' '));
		%sysfunc(scan(&vlist, &i., ' ')) = %sysfunc(scan(&plist, &i., ' '));
	%end;
	fit &vlist. / gmm kernel=(bart, &lags., 0) vardef=n;
	ods output parameterestimates = _tmp_NW;
	by &by.;
quit;

data &dsout.;
set _tmp_NW;
	drop EstType stderr probt df;
	rename estimate=mean tvalue=t;
	%do i=1 %to %sysfunc(countw(&vlist, ' '));
		if Parameter = "%sysfunc(scan(&plist, &i., ' '))" then Parameter = "%sysfunc(scan(&vlist, &i., ' '))";
	%end;
	rename Parameter = Variable2;
run;

proc datasets lib=work;
	delete _tmp_NW;
quit;

%mend NW;
