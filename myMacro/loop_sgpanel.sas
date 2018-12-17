/*PROC SGPANEL improper for MktCap, SIZE; dominates all the others.*/

%macro loop_sgpanel(dsin, rankVar, vlist_ret, vlist_char, vlist_beta, groupby=) / DES='Run after %*Sort().';
%let nVar_ret = %sysfunc(countw(&vlist_ret., ' '));
%let nVar_char = %sysfunc(countw(&vlist_char., ' '));
%let nVar_beta = %sysfunc(countw(&vlist_beta., ' '));

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
		panelby Variable weight &groupby. / uniscale=column;
		series x=&rankVar. y=Mean / markers group=Variable;
		where Variable in %enquote(&vlist_ret.) and Variable2 in ('Mean') and &rankVar. ~in ('diff', 'avg');
	run;

%do i=1 %to &nVar_char.;
	%let currVar_char = %scan(&vlist_char., &i., ' ');

	title "&currVar_char.";
	proc sgpanel data=&dsin.;
		panelby &groupby. / uniscale = column;
		series x=&rankVar. y=Mean / markers group=Variable;
		where Variable in ("&currVar_char.") and Variable2 in ('Mean') and &rankVar. ~in ('diff', 'avg');
	run;

	%end;

%do i=1 %to &nVar_beta.;
	%let currVar_beta = %scan(&vlist_beta., &i., ' ');

	title "&currVar_beta.";
	proc sgpanel data=&dsin.;
		panelby Variable &groupby. / uniscale = column;
		series x=&rankVar. y=Mean / markers group=Variable;
		where Variable in ("&currVar_beta.") and Variable2 in ('Mean') and &rankVar. ~in ('diff', 'avg');
	run;

	%end;

%mend loop_sgpanel;
