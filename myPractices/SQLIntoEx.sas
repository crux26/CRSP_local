DATA MASTER;
INPUT EMPID $ DIAG $ MEMID ;
CARDS;
P01 	53071 	258766
P02 	99215 	92139678
P03 	99201 	921396
P04 	45355 	566511
P05 	45383 	464467896
P06 	43260 	87932
P07 	99213 	73771
P08 	45380 	846420987
P09 	88714 	346987
P10 	55431 	3469871 
;

proc sql noprint;
	select distinct empid, diag
	into :e1 - :e4, :d2 - :d4
	from master;
quit;

%put &e1 &d2;
%put &e2 &d3;
%put &e3 &d4;
%put &e4 ;



proc sql noprint;
	select distinct empid, diag
	into :e separated by ', '
	from master;
quit;

%put Types of empid=&e.;

