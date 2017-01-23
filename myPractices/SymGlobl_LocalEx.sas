%let d=%eval(10+20);
%let d2=%sysevalf(10.5+20.3);
%let d3=10+30;
%let d4 = "10+30";
%let d5='10+30';

%put symglobl: %SYMGLOBL(d);
%put symlocal: %SYMLOCAL(d);

%put _user_;

%macro test;
%local y;
%if %symglobl(y) %then %put %nrstr(%symglobl(y)) = TRUE;
%else %put %nrstr(%symglobl(y)) = FALSE;
%put symlocal of y: %SYMLOCAL(y);
%put symglobal of y: %SYMGLOBL(y);
%put local symbol tables: _local_;
%mend test;

%test;
