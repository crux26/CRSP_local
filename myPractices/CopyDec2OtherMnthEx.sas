/*Descending month so that "DEC" shows up at the top*/
/*Months except DEC will copy DEC value into themselves within the same year*/
proc sort data=have;
by permno year descending month;
run;


data want; set have;
by permno year;
retain _MktCap ;
if missing(MktCap) =0 then _MktCap = MktCap;
if missing(MktCap) then MktCap = _MktCap;
drop _MktCap;
run;
