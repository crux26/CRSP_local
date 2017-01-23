%put _user_;

%let a = 3;
%let b = %eval(13);

data _null_;
call symput("x", 13);
call symput("y", 13);
run;

%let z=11;

/*works improperly without ""(i.e. double quotation mark)*/
data _null_;
	if &x = &b then put "equal: 1";
	else put "not equal: 0";
run;
