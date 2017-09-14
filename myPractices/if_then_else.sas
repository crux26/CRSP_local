/*If-then-else syntax. Crucially important.*/

/*RIGHT*/
%macro temp;
    %let abc=0;
    %put &=abc;

    %if ("&abc"="0") %then
        %put string check: iszero;
    %else %put string check: notzero;

    %if (&abc=0) %then
        %put numeric check: iszero;
    %else %put numeric check: notzero;
%mend temp;
%temp;

/*WRONG - DO NOT put ";" after %ELSE. This means the termination of %ELSE part.*/
/*Then the next %PUT statement runs UNconditionally.*/
%macro temp2;
    %let abc=0;
    %put &=abc;

    %if ("&abc"="0") %then
        %put string check: iszero;
    %else; %put string check: notzero;

    %if (&abc=0) %then
        %put numeric check: iszero;
    %else; %put numeric check: notzero;
%mend temp2;

%temp2;
