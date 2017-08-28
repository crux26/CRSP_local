/*CALL SYMPUTX(): automatically removes leading and trailing blanks, not like CALL SYMPUT(). */

/*	"%let" is a macro statement that you can use in open code	or inside a macro.*/
/*	Call symputs can be used only in a DATA step, not in open code.*/
/*	This DATA Step may be inside a macro.*/

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
	call symput('abc',b); /*b=33 will be stored in abc as a global variable*/
run;

/*Displays user-defined macro variables*/
%put _user_;
