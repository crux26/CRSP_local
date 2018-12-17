%macro loop_sgplot(dsin, rankVar, vlist_ret, vlist_char, vlist_beta=) / DES='Run after %*Sort().';
%let nVar_ret = %sysfunc(countw(&vlist_ret, ' '));
%let nVar_char = %sysfunc(countw(&vlist_char, ' '));

%macro enquote(varlist);
    %let delim=%str( );
    %let outputvar="%qscan(&varlist, 1, &delim)";
    %let i=2;

    %do %while(%length(%qscan(&varlist, &i, &delim)) > 0);
        %let varhere=%qscan(&varlist,&i,&delim);
        %let outputvar=&outputvar, "&varhere";
        %let i=%eval(&i+1);
    %end;
	%let outputvar=(&outputvar.);
	&outputvar.
%mend enquote;

	title "&vlist_ret.";
	proc sgpanel data=&dsin.;
		panelby Variable weight;
		series x=&rankVar. y=Mean / markers group=Variable;
		where Variable in %enquote(&vlist_ret.) and Variable2 in ('Mean') and &rankVar. ~in ('diff', 'avg');
	run;

%do i=1 %to &nVar_char.;
	%let currVar_char = %scan(&vlist_char., &i., ' ');

	title "&currVar_char.";
	proc sgplot data=&dsin.;
		series x=&rankVar. y=Mean / markers group=Variable;
		where Variable in ("&currVar_char.") and Variable2 in ('Mean') and &rankVar. ~in ('diff', 'avg');
	run;
%end;

title "betas";
proc sgplot data=&dsin.;
	series x=&rankVar. y=Mean / markers group=Variable;
	where Variable contains ('beta') and Variable2 in ('Mean') and &rankVar. ~in ('diff', 'avg');
run;

%mend loop_sgplot;
