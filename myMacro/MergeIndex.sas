/* This macro written for CorpFin_HW1 purpose only. May not be extendible. */
%macro MergeIndex(freq=, datain=, dataout=, exchcd=);
proc sql;
create table &dataout as
select a.*, b.vwretd, b.vwindd, b.ewretd, b.ewindd,
a.vwret-b.vwretd as abnormal_vwret, a.ewret-b.ewretd as abnormal_ewret
from &datain as a
left join
%if &exchcd=1 %then %do;
	a_index.&freq.sia as b /* sia: NYSE */
%end;
%else %if &exchcd=3 %then %do;
	a_index.&freq.sio as b /* sio: NASDAQ */
%end;
on a.date = b.caldt
order by date;
quit;


%mend MergeIndex;
