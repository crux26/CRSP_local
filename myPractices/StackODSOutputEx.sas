/* default output data set. Yuck! */
proc means data=sashelp.cars noprint;
	var mpg_city mpg_highway;
	output out=MeansWidePctls P5= P25= P75= P95= / autoname;
run;

proc print data=MeansWidePctls noobs;
run;

/* Use the STACKODSOUTPUT option to get output in a more natural shape */
proc means data=sashelp.cars StackODSOutput P5 P25 P75 P95;
	var mpg_city mpg_highway;
	ods output summary=LongPctls;
run;

proc print data=LongPctls noobs;
run;
