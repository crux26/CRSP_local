%macro ChgDay2MthEnd (data=, output=, keep=, print=, date= );

%if %sysevalf(%superq(output)=,boolean)  %then
	%do;
		%let output = &data;
	%end;

data &output;
	set &data(keep=&keep);
	&date = intnx('month', &date, 1)-1;
	format &date yymmddn8.;
	%if &print=1 %then
		%do;
			proc print data = &output;
			title1 "with the input '&data' and output '&output' keeping '&keep'" ;
			title2 'Date changed to the end of month';
		%end;
run;
title;
%mend ChgDay2MthEnd;
