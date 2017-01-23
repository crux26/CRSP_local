data prices;
input code amount;
datalines;
56 300
99 10000
24 225
;

data sales;
	set prices;
	length saleitem $ 20;
	b = 33;
	call symput('abc',b); /*b=3 will be stored in abc as a global variable*/
run;

/*Displays user-defined macro variables*/
%put _user_;
