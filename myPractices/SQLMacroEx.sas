/*"%put &country1 &barrels1;" is just to print out the macro variable*/
/*Above does not generate macro variable*/
/*Instead, "into :country1, :barrels1" defines macro variables*/

libname sql 'D:\Dropbox\GitHub\CRSP_local\SQL Sample dataset';

proc sql noprint;
	select country, barrels
	into :country1, :barrels1
		from sql.oilrsrvs;
	%put &country1 &barrels1;
quit;

%put _user_;
%symdel country1 barrels1;
