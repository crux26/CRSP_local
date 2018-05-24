/*Working on this file (18.04.09). Far from being done.*/

%vw_avgprice(indsn=taq.ct_20130102 , outdsn=VWP_20130102, begdate=, enddate=,
	beghms=09:30:00, endhms=16:00:00, inthms=00:05:00, 
	symlist=_ALL_, symdsn=,
	p_var=price, v_var=size, d_var=date, t_var=time, s_var=symbol, nt_var=, 
	help=no);

/*Above takes 11.41s on WRDS server, for a day, 379748 obs and 6 variables.*/
/*--> 20Y takes 15.96h. */

/*W/o calculating total_vol and n_trades, decreases to 7.8s.*/
/*--> 10.9h.*/


/*--*/
data dates;
    date = '01Jan1993'd;

    do while (date<='31Dec2013'd);
        output;
        date=intnx('day', date, 1);
    end;
    format date date9.;
    
run;

data dates(drop=weekday);
set dates;
weekday = weekday(date);
if weekday in (2,3,4,5,6) then output;
run;

data dates;
set dates;
obs = _N_;
run;
