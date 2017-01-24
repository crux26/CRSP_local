/*Comment below do NOT work*/
/*	%let i=i+1;*/
/*	%let i=&i+1;*/

%macro test(finish);
%let i=1;
%do %while (&i<&finish);
	%put the value of i is &i;
	%let i=%eval(&i+1);
%end;
%mend test;

%test(5)


