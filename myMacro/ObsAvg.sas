%macro ObsAvg(data=, out=, by=, drop=);
proc means data=&data noprint nway;
output out=&out(drop=&drop)
mean()=;
by &by;
run;
%mend ObsAvg;

/*String variables aren't considered in PROC MEANS*/
/*Assumed that data is pre-sorted properly*/
/*ObsAvg is run over ALL variables*/

