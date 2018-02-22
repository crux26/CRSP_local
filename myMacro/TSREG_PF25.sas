%MACRO TSREG_PF25(data=, out=, PF_sort1=s, PF_sort2=b, n_sort1=, n_sort2=, depvar_postfix=, INDEPVARS=, lags=);
	options nonotes nosource;
	ods listing close;
	ods exclude all;
	ods graphics off;
	ods noresults;
    
	%do i=1 %to &n_sort1.;
		%do j=1 %to &n_sort2.;

			proc printto log=junk;
			run;

			proc model data=&data;
				parms a b c d;
				exogenous MKT_RF SMB HML;
				&PF_sort1.&i.&PF_sort2.&j._&depvar_postfix. = a + b*MKT_RF + c*SMB + d*HML;
				fit &PF_sort1.&i.&PF_sort2.&j._&depvar_postfix. / gmm kernel=(bart, %eval(&lags+1), 0) vardef=n;
				ods output parameterEstimates=&PF_sort1.&i.&PF_sort2.&j._&depvar_postfix.;
			quit;

			proc printto;
			run;
		%end;
	%end;

    %do i=1 %to &n_sort1.;
        %do j=1 %to &n_sort2.;
            data &PF_sort1.&i.&PF_sort2.&j._&depvar_postfix.;
                set &PF_sort1.&i.&PF_sort2.&j._&depvar_postfix.;
                class = "&PF_sort1.&i.&PF_sort2.&j._&depvar_postfix.";
            run;
        %end;
    %end;

    data &out.;
    run; 

    %do i=1 %to &n_sort1.;
        %do j=1 %to &n_sort2.;
            data &out.; set &out. &PF_sort1.&i.&PF_sort2.&j._&depvar_postfix.;
            if missing(class) then delete;
            run;
        %end;
    %end;


	ods results;
	ods listing;
	ods exclude none;
	ods graphics;
	options notes source;
%mend TSREG_PF25;
