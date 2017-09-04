%MACRO StockSelect(freq=, datain=, dataout=, picknum=, filter_exchcd=);

data crsp_&freq.0; set &datain; by permno; exchcd_chg = dif(exchcd);
if first.permno then exchcd_chg=0; run;

proc sql;
create table crsp_&freq.1(drop=exchcd_chg) as
select *
from crsp_&freq.0
group by permno
%if &freq=m %then %do;
	having min(date)='31Jan2007'd and max(date)='30Dec2016'd and sum(exchcd_chg)=0
%end;
%else %if &freq=d %then %do;
	having min(date)='03Jan2007'd and max(date)='30Dec2016'd and sum(exchcd_chg)=0
%end;
order by permno, date;
quit;

data crsp_&freq.2; set crsp_&freq.1;
if hexcd=&filter_exchcd then output;
run;

proc sort data=crsp_&freq.2; by permno date; run;


data crsp_&freq.3; set crsp_&freq.2; by permno;
retain permno_count 0;
if first.permno then permno_count=permno_count+1;
run;

data &dataout(drop=permno_count); set crsp_&freq.3; if permno_count <= &picknum then output; run;

/* House Cleaning */
proc sql;  
drop table crsp_&freq.0, crsp_&freq.1, crsp_&freq.2, crsp_&freq.3;
quit;  

%mend;
