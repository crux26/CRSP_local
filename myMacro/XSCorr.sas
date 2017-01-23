%macro XSCorr(data=,outP=, outS=, print=, var=, Date=);

%if &print=1 %then
	%do;
		proc corr data=&data outP=&outP outS=&outS;
			var &var;
			by &Date;
	%end;
%else
	%do;
		proc corr data=&data outP=&outP outS=&outS noprint;
			var &var;
			by &Date;
	%end;
run;
%mend XSCorr;
