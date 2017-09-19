%put today=%sysfunc(today(),yymmddn8.);

proc format;
picture myfmt low-high = '%Y%0m%0d_%0H%0M%0S' (datatype=datetime);
run;

%put timestamp=%sysfunc(datetime(), myfmt.);


%put %sysfunc(date(), worddate.);
%put %sysfunc(time(), TIMEAMPM.w);

