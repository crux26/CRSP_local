%macro MacroLoopEx;
    %local i;
    %let i=1;

%loop:
    %put i=&i.;

    %*test;
    %if &i. eq 2 %then
        %goto done;

    %*iterate;
    %let i=%eval(&i.+1);

    %*repeat; %goto loop;
%done:
    %put loop-repeat: i=&i.;
    %local j;
    %let j=1;

    %do %while(&j lt 3);
        %put j=&j.;
        %let j=%eval(&j.+1);
    %end;

    %put do j: j=&j.;
    %local k;
    %let k=1;

    %do %until(&k ge 3);
        %put k=&k.;
        %let k=%eval(&k.+1);
    %end;

    %put do k: k=&k.;
    %local l;

    %do l=1 %to 2;
        %put l=&l;
    %end;

    %put do l: l=&l.;
%mend MacroLoopEx;

%MacroLoopEx;
