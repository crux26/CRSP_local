%macro Dep_DblSort (data=, output=, print=, sortseq1= , sortvar1=, sortseq2=, sortvar2= );
%if %sysevalf(%superq(output)=,boolean)  %then
	%do;
		%let output = &data;
	%end;

proc sort data=&data out=&output;
by &sortseq1 &sortvar1 &sortseq2 &sortvar2;

%if &print = 1 %then
	%do;
		proc print data = &output;
		title "with the input '&data' and output '&output'" ;
		title2 "sorted first by &sortseq1 &sortvar1 and then &sortseq2 &sortvar2";
	%end;

run;
%mend Dep_DblSort;
