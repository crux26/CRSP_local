/*SPXOpprcd_Merge -> SPXData_Merge -> SPXCallPut_Merge -> SPXData_Trim -> SPXData_Export */
libname a_index "D:\Dropbox\WRDS\CRSP\sasdata\a_indexes";
libname a_stock "D:\Dropbox\WRDS\CRSP\sasdata\a_stock";
libname a_treas "D:\Dropbox\WRDS\CRSP\sasdata\a_treasuries";
libname ff "D:\Dropbox\WRDS\ff\sasdata";
libname frb "D:\Dropbox\WRDS\frb\sasdata";
libname mysas "D:\Dropbox\WRDS\CRSP\mysas";
libname myOption "D:\Dropbox\WRDS\CRSP\myOption";
libname myMacro "D:\Dropbox\GitHub\CRSP_local\myMacro";
libname optionm "\\Egy-labpc\WRDS\optionm\sasdata";

data myOption.spxcall_cmpt;
	set myOption.spxcall;
	datedif = intck('weekday',date,exdate);
run;

data myOption.spxput_cmpt;
	set myOption.spxput;
	datedif = intck('weekday',date,exdate);
run;

data myOption.spxcall_cmpt;
set myOption.spxcall_cmpt;
where 10 <= datedif <= 64;
run;

data myOption.spxput_cmpt;
set myOption.spxput_cmpt;
where 10 <= datedif <= 64;
run;

proc sql;
	create table myOption.spxCall_cmpt
	as select a.*, b.spindx, b.sprtrn, b.tb_m3, b.rate as div, b.spxset
	from
	myOption.spxcall_cmpt as a
	left join
	myOption.spxdata as b
	on b.caldt = a.date ;
quit;

/*b.caldt = a.exdate - 1 is not enough, at least technically*/
/*there exists a case that b.caldt = a.exdate - 2 (though very few)*/
proc sql;
	create table myOption.spxCall_cmpt
	as select a.*, b.spxset as spxset_expiry
	from
	myOption.spxcall_cmpt as a
	left join
	myOption.spxdata as b
	/*Even if a.exdate = Saturday, match it with Friday's data*/
	on b.caldt = intnx('week',a.exdate,0)+5 ; 
quit;

/**/
/**/
proc sql;
	create table myOption.spxPut_cmpt
	as select a.*, b.spindx, b.sprtrn, b.tb_m3, b.rate as div, b.spxset
	from
	myOption.spxput_cmpt as a
	left join
	myOption.spxdata as b
	on b.caldt = a.date ;
quit;

proc sql;
	create table myOption.spxPut_cmpt
	as select a.*, b.spxset as spxset_expiry
	from
	myOption.spxput_cmpt as a
	left join
	myOption.spxdata as b
	/*Even if a.exdate = Saturday, match it with Friday's data*/
	on b.caldt = intnx('week',a.exdate,0)+5 ; 
quit;

data myOption.spxCall_cmpt;
	set myOption.spxCall_cmpt;
	strike_price = strike_price/1000;
	moneyness = spindx / strike_price ;
	mid = (best_bid + best_offer) * 0.5;
	opret = (spxset_expiry - strike_price) / mid -1;
	if opret < -1 then opret = -1;
	informat impl_volatility delta gamma vega theta 12.6;
	format impl_volatility delta gamma vega theta 12.6;
	drop secid cp_flag best_bid best_offer ss_flag;
	where date <='31DEC2015'd;
run;

data myOption.spxPut_cmpt;
	set myOption.spxPut_cmpt;
	strike_price = strike_price/1000;
	moneyness = spindx / strike_price ;
	mid = (best_bid + best_offer) * 0.5;
	opret = (spxset_expiry - strike_price) / mid - 1 ;
	if opret < -1 then opret = -1;
	informat impl_volatility delta gamma vega theta 12.6;
	format impl_volatility delta gamma vega theta 12.6;
	drop secid cp_flag best_bid best_offer ss_flag;
	where date <= '31DEC2015'd;
run;
