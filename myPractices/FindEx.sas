/*LIKE(), FIND() and FINDW() example.*/
/*FIND() returns the position of the character within a string. If not contained, returns 0.*/
/*"=:": LIKE().*/
data Bivar_brkpt_;
	length class $ 6;
	set Bivar_brkpt;

	if Variable =: "beta" then
		class="beta";
	else if Variable =: "MktCap" then
		class="MktCap";
run;

/*The same result.*/
data Bivar_brkpt_;
	length class $ 6;
	set Bivar_brkpt;
	if find(Variable, "beta")>0 then class="beta";
	else if find(Variable, "MktCap")>0 then class="MktCap";
run;

%let Variable = abcd;
%put &=Variable;
%put %sysfunc(find(&Variable, beta));
%put %sysfunc(find(&Variable, ab));
%put %sysfunc(find(&Variable, ab));

%let Variable = abcd efgh;
%put %sysfunc(findw(&Variable, efgh));
