libname a_stock "D:\Dropbox\WRDS\CRSP\sasdata\a_stock\";
libname a_index "D:\Dropbox\WRDS\CRSP\sasdata\a_indexes\";
libname mysas "D:\Dropbox\WRDS\CRSP\mysas\";
libname myMacro "D:\Dropbox\SAS_scripts\myMacro";

data mysas.first(rename=(ret=unsquared_ret));
	set a_stock.msf(keep=  FIRSTOBS=50 OBS=1049) ;
	squared_ret = ret**2; 
run;

proc print data = mysas.first; run;

%include myMacro('ChgDay2MthEnd.sas');
%ChgDay2MthEnd(data=mysas.first,output=,keep=permno date unsquared_ret squared_ret, print=1, date= date);

data first first_positive;
set a_stock.msf(keep=permno date ret);
if ret>0 	then
	output first_positive;
/*else output first;*/
run;
quit;

%include myMacro('Dep_DblSort.sas');
%Dep_DblSort(data=mysas.first, output=, print=0, sortvar1=permno, sortseq1=, sortvar2=date, sortseq2=);

proc print;
run;




/*typing "vt open = mysas.first" in "COMMAND" will open the viewtable*/


