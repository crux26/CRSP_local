%macro tsreg_ChgValue(RegkeyVar=, data=, set=);

data &data; 
	set &set;
	EstType = "&RegkeyVar.";
run;

%mend tsreg_ChgValue;
