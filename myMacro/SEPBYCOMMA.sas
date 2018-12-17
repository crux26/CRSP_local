%macro sepbycomma(varlist) / des="Used in %HASHMERGE().";
    %let delim=%str( );
    %let outputvar=%qscan(&varlist, 1, &delim);
/*%QSCAN(arg,n<,delimiters>): masks special characters and mnemonic operators in its result.*/
/*That is, it prevents macro calls and resolving vaiables through % and &.*/
/*%QSCAN() treats macro triggers (&, %) as texts.*/

/*If arg contains comma, enclose arg in a quoting function, e.g. %QUOTE(arg).*/
/*n: the position of the word to return. If n>len(arg), returns null string.*/
/*n==0 allowed, but returns WARNING.*/
    %let i=2;

    %do %while(%length(%qscan(&varlist, &i, &delim)) > 0);
        %let varhere=%qscan(&varlist, &i, &delim);
        %let outputvar=&outputvar, &varhere;
        %let i=%eval(&i+1);
    %end;

    &outputvar
	/*Note that above does not have ";" or "%PUT".*/
%mend sepbycomma;
