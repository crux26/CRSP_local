/*SPXOpprcd_Merge -> SPXCallPut_Merge -> SPXData_Trim_2nd_dly (or _MnthEnd) */
/*Using SPXData_Trim_2nd_dly.*/
/*HERE, DATEDIF IS CALENDAR DAY DIFFERENCE, WHICH IS DIFFERENT FROM TRP.*/
/*datedif: BUS day difference.*/
data OpFull.spxcall_cmpt;
	set spxcall_mnth;
	datedif = intck('day',date,exdate);
	if datedif < 70 then output;
run;

data OpFull.spxput_cmpt;
	set spxput_mnth;
	datedif = intck('day',date,exdate);
	if datedif < 70 then output;
run;

/*Match option data with SPX data.*/
proc sql;
	create table OpFull.spxCall_cmpt
	as select a.*, b.spindx, b.sprtrn, b.tb_m3, b.rate as div, b.spxset
	from
	OpFull.spxcall_cmpt as a
	left join
	myOption.spxdata as b
	on b.caldt = a.date;
quit;

/*Below is to align SPXSET, the settlement price for SPX options.*/
proc sql;
	create table OpFull.spxCall_cmpt
	as select a.*, b.spxset as spxset_expiry
	from
	OpFull.spxcall_cmpt as a
	left join
	myOption.spxdata as b
	/*Even if a.exdate = Saturday, match it with Friday's b.caldt data*/
	/*Below is to select caldt=Friday only on the exdate's week where SPX option's maturity is 3rd Friday every month.*/
	on b.caldt = intnx('week',a.exdate,0)+5
	order by date, exdate, strike_price; 
quit;

/*--------------Put case---------------*/
proc sql;
	create table OpFull.spxPut_cmpt
	as select a.*, b.spindx, b.sprtrn, b.tb_m3, b.rate as div, b.spxset
	from
	OpFull.spxput_cmpt as a
	left join
	myOption.spxdata as b
	on b.caldt = a.date ;
quit;

proc sql;
	create table OpFull.spxPut_cmpt
	as select a.*, b.spxset as spxset_expiry
	from
	OpFull.spxput_cmpt as a
	left join
	myOption.spxdata as b
	/*Even if a.exdate = Saturday, match it with Friday's b.caldt data*/
	on b.caldt = intnx('week',a.exdate,0)+5
	order by date, exdate, strike_price; 
quit;

data OpFull.spxCall_cmpt;
	set OpFull.spxCall_cmpt;
	strike_price = strike_price/1000;
	moneyness = spindx / strike_price ;
	mid = (best_bid + best_offer) * 0.5;
	opret = (spxset_expiry - strike_price) / mid -1;
	if opret < -1 then opret = -1;
	informat impl_volatility delta gamma vega theta 12.6;
	format impl_volatility delta gamma vega theta 12.6;
/*	drop secid cp_flag best_bid best_offer ss_flag;*/
	where date <='31DEC2015'd;
run;

data OpFull.spxPut_cmpt;
	set OpFull.spxPut_cmpt;
	strike_price = strike_price/1000;
	moneyness = spindx / strike_price ;
	mid = (best_bid + best_offer) * 0.5;
	opret = (spxset_expiry - strike_price) / mid - 1 ;
	if opret < -1 then opret = -1;
	informat impl_volatility delta gamma vega theta 12.6;
	format impl_volatility delta gamma vega theta 12.6;
/*	drop secid cp_flag best_bid best_offer ss_flag;*/
	where date <= '31DEC2015'd;
run;
