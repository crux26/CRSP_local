%macro PersistenceAnal(data=, out=, ret=, date=, identifier=);
/*"by=" may be needed*/
/*Correlations up to 6M is hard-coded.*/
data tmp0;
set &data;
year = year(&date);
run;

proc sort data = tmp0;
by &identifier &date; /*identifier: permno, permco, ...*/
run;

data tmp1;
set tmp0;
by &identifier;
ObsNum+1;
if first.&identifier then ObsNum = 1;
run;

/*Below is too brute-force. Find a better solution*/
/*--> this "Brute-force" approach is actually provided by SAS*/
data tmp2;
set tmp1;
by &identifier;
L1ret = lag(&ret);
L2ret = lag2(&ret);
L3ret = lag3(&ret);
L4ret = lag4(&ret);
L5ret = lag5(&ret);
L6ret = lag6(&ret);
if ObsNum=1 then do;
	L1ret=.; L2ret=.; L3ret=.; L4ret=.; L5ret=.; L6ret=.;
end;
if ObsNum=2 then do;
	L2ret=.; L3ret=.; L4ret=.; L5ret=.; L6ret=.;
end;
if ObsNum=3 then do;
	L3ret=.; L4ret=.; L5ret=.; L6ret=.;
end;
if ObsNum=4 then do;
	L4ret=.; L5ret=.; L6ret=.;
end;
if ObsNum=5 then do;
	L5ret=.; L6ret=.;
end;
if ObsNum=6 then do;
	L6ret=.;
end;

proc sort data=tmp2;
by year &identifier;
run;

/*As Jan or Feb data are missing by lag1 and lag2, "N" in the first year 1988 being*/
/*much smaller for L1ret, L2ret is natural*/
proc corr data=tmp2 outp=corr noprint;
var &ret L1ret L2ret L3ret L4ret L5ret L6ret;
by year;
run;

data tmp3;
set corr;
keep year _TYPE_ _NAME_ ret;
if _NAME_="" then _NAME_ = _TYPE_;
run;

proc transpose data=tmp3 out=result(drop=_LABEL_ ret) name=varname;
var &ret;
id _NAME_;
by year;
run;

proc datasets lib=work nolist;
	delete tmp0-tmp3 corr;
run;
quit;

%mend PersistenceAnal;
