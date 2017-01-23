data orders;
input CustomerID $1-3 OrderDate Date7. Model $ 13-24 Quantity;
cards;
287 15OCT03 Delta Breeze 	15
287 15OCT03 Santa Ana 		15
274 16OCT03 Jet Stream 		1
174 17OCT03 Santa Ana 		20
174 17OCT03 Nor'easter 		5
174 17OCT03 Scirocco 		1
347 18OCT03 Mistral 			1
287 21OCT03 Delta Breeze	 30
287 21OCT03 Santa Ana 		25
;
run;

proc print data = orders;
run;
quit;

%MACRO reports;
%IF &SYSDAY = Monday %THEN %DO;
PROC PRINT DATA = orders NOOBS;
FORMAT OrderDate DATE7.;
TITLE "&SYSDAY Report: Current Orders";
%END;
%ELSE %IF &SYSDAY ^= Friday %THEN %DO;
PROC TABULATE DATA = orders;
CLASS CustomerID;
VAR Quantity;
TABLE CustomerID ALL, Quantity;
TITLE "&SYSDAY Report: Summary of Orders";
%END;
%MEND reports;
RUN;

%reports;
run;
quit;

proc print data = orders;
run;
quit;
