/*Adds ESTTYPE as a variable. This enables merge by this variable.*/
%macro AddVar(RegkeyVar=, data=, set=);

data &data; 
	set &set;
	EstType = "&RegkeyVar.";
run;

%mend AddVar;
