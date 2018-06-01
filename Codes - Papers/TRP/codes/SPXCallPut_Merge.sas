/*SPXOpprcd_Merge -> SPXData_Merge -> SPXCallPut_Merge -> SPXData_Trim -> SPXData_Export */
libname a_index "E:\Dropbox\WRDS\CRSP\sasdata\a_indexes";
libname a_stock "E:\Dropbox\WRDS\CRSP\sasdata\a_stock";
libname a_treas "E:\Dropbox\WRDS\CRSP\sasdata\a_treasuries";
libname ff "E:\Dropbox\WRDS\ff\sasdata";
libname frb "E:\Dropbox\WRDS\frb\sasdata";
libname mysas "E:\Dropbox\WRDS\CRSP\mysas";
libname myOption "E:\Dropbox\WRDS\CRSP\myOption";
libname myMacro "E:\Dropbox\GitHub\CRSP_local\myMacro";
libname optionm "\\Egy-labpc\WRDS\optionm\sasdata";
/*datedif: BUS day difference.*/
data spxcall_cmpt;
	set myOption.spxcall_mnth;
	datedif = intck('weekday',date,exdate);
	if 10 <= datedif <= 64 then output;
run;

data spxput_cmpt;
	set myOption.spxput_mnth;
	datedif = intck('weekday',date,exdate);
	if 10 <= datedif <= 64 then output;
run;

proc sql;
	create table spxCall_cmpt_
	as select a.*, b.spindx, b.sprtrn, b.tb_m3, b.rate as div, b.spxset
	from
	spxcall_cmpt as a
	left join
	myOption.spxdata as b
	on b.caldt = a.date;
quit;

/*b.caldt = a.exdate - 1 is not enough, at least technically*/
/*there exists a case that b.caldt = a.exdate - 2 (though very few)*/

/*Below is to align SPXSET, the settlement price for SPX options.*/
proc sql;
	create table spxCall_cmpt__
	as select a.*, b.spxset as spxset_expiry
	from
	spxCall_cmpt_ as a
	left join
	myOption.spxdata as b
	/*Even if a.exdate = Saturday, match it with Friday's b.caldt data*/
	/*Below is to select caldt=Friday only on the exdate's week where SPX option's maturity is 3rd Friday every month.*/
	on b.caldt = intnx('week',a.exdate,0)+5
	order by date, exdate, strike_price; 
quit;

/*--------------Put case---------------*/
proc sql;
	create table spxPut_cmpt_
	as select a.*, b.spindx, b.sprtrn, b.tb_m3, b.rate as div, b.spxset
	from
	spxput_cmpt as a
	left join
	myOption.spxdata as b
	on b.caldt = a.date ;
quit;

proc sql;
	create table spxPut_cmpt__
	as select a.*, b.spxset as spxset_expiry
	from
	spxPut_cmpt_ as a
	left join
	myOption.spxdata as b
	/*Even if a.exdate = Saturday, match it with Friday's b.caldt data*/
	on b.caldt = intnx('week',a.exdate,0)+5
	order by date, exdate, strike_price; 
quit;

data myOption.spxCall_cmpt;
	set spxCall_cmpt__;
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

data myOption.spxPut_cmpt;
	set spxPut_cmpt__;
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
