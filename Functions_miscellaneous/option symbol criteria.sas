/*This is to check symbol determination criteria for standard and non-standard options.*/
/*Checked with Call.*/
/*Note that some parts are removed.*/
data spxcall; set myoption.spxcall;
where date between '17may2010'd and '05dec2010'd
and find(symbol, 'SPXPM')=0;
run;

proc sort data=spxcall; by date exdate; run;

/**/
/**/
data nonstd std; set spxcall;
month_exdate = month(exdate); year_exdate = year(exdate);
Fri3 = nwkdom(3, 6, month_exdate, year_exdate); Fri3Plus1 = nwkdom(3, 6, month_exdate, year_exdate)+1;
if exdate ~= Fri3 and exdate ~=Fri3Plus1 then output nonstd;
else output std;
run;

/**/
/*Below can NOT completely identify non-standards.*/
/*Between May 17, 2010 and Apr 05, 2011, Friday EOWs are written with symbol=SPX.*/
data nonstd_1 nonstd_0; set nonstd;
	if find(symbol, 'J')=1 then isJ=1;
	isQ1 = find(symbol, 'SPXQ'); isQ2=find(substr(symbol,1,3), 'Q'); isQ=isQ1+isQ2; 
	isW = find(symbol, 'SPXW');
	isPM = find(symbol, 'PM');
	if sum(isJ, isQ, isW, isPM) > 0 then output nonstd_1;
	else output nonstd_0;
run;

