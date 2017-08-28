/*Syntaxes of "data; set;" clauses*/

data mysas.first(rename=(ret=unsquared_ret));
	set a_stock.msf(keep= FIRSTOBS=50 OBS=1049) ;
	squared_ret = ret**2; 
run;

data first first_positive;
set a_stock.msf(keep=permno date ret);
if ret>0 	then
	output first_positive;
/*else output first;*/
run;
quit;

data msf_2014;
set a_stock.msf(keep=permno date ret);
where year(date)=2014;
run;
quit;
