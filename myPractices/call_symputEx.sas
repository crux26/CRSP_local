data orders;
input CustomerID $1-3 OrderDate DATE7. Model $ 13-24 Quantity;
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

proc sort data = orders;
by descending quantity;
run;

data _null_ ; set orders;
if _N_ = 1 then							 /* "n = 1" wouldn't work as undersbar is not in the front nor in the back */
	call SYMPUT ("biggest", CustomerID);
else stop;

proc print data = orders noobs;
where CustomerID = "&biggest";
format OrderDate date7. ;
title "customer &biggest had the single largest order" ;
run;
quit;

