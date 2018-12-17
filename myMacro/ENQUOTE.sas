%macro enquote(varlist) / DES="Used in %HASHMERGE().";
    %let delim=%str( );
    %let outputvar="%qscan(&varlist, 1, &delim)";
    %let i=2;

    %do %while(%length(%qscan(&varlist, &i, &delim)) > 0);
        %let varhere=%qscan(&varlist,&i,&delim);
        %let outputvar=&outputvar,"&varhere";
        %let i=%eval(&i+1);
    %end;

    &outputvar.
	/*Note that above does not have ";" or "%PUT". Also note that above is NECESSARY.*/
%mend enquote;
