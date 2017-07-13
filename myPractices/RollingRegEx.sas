/*This is NOT rolling regression per se.*/
/*To see whether "where ObsNum >= 200", this code is tested*/


proc import datafile="C:\Users\User\Desktop\testHave" dbms=EXCEL
out=mysas.testHave;
run;


proc reg data=mysas.testHave
outest =mysas.testReg noprint;
model ret = vwretd;
by permno year;
where ObsNum >= 200;
run;
