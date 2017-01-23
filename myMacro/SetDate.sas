%macro SetDate(data=, set=, date=, begdate=, enddate=);
data &data;
set &set;
rename &date = date;
where &begdate <= &date <= &enddate;
run;
%mend SetDate;
