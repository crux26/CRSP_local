data have;
set a_stock.dsf(obs=100);
win_end = intnx('week', date, 1, 's');
format win_end yymmddn8.;
run;

proc sql;
create table want as
select a.permno, a.date, sum(b.ret) as ret_1W
from
have as a
left join
have as b
on
b.permno = a.permno and b.date between a.date and a.win_end
group by
a.permno, a.date
order by
a.permno, a.date;
quit;

/**/
/**/
/*Bivar reg.: MKT, Tail. --> ran for bivariate sort w.r.t. betas.*/

/*FF3F*/
/*Below takes: <9m.*/
%hashmerge(largeds=XSREG.crsp_char_d(obs=1000), smallds=FF.FF3F_mrgd_expd_d, 
	byvars=date, extravars=smb hml mom strev ltrev, outds=crsp_char_d0);

/*Below takes: 22m; cpu 1m, i/o 21m.*/
proc sort data=crsp_char_d0 out=crsp_char_d0 nodupkey;
	by permno date;
run;

data crsp_char_d0;
	set crsp_char_d0;
	win_st = intnx('week', date, -3, 's');
	win_end = intnx('week', date, 4, 's');
	format win_st win_end date9.;
run;

/*Variables not appearing in ON, GROUP BY results in duplication.*/
proc sql;
	create table crsp_char_d_expd as
		select a.permno, a.date,
			sum(b.ret) as ret_1M, sum(b.rf) as rf_1M, calculated ret_1M - calculated rf_1M as exret_1M,
			sum(b.mktrf) as mktrf_1M, sum(b.SMB) as SMB_1M, sum(b.HML) as HML_1M, sum(b.UMD) as UMD_1M,
			sum(b.STREV) as STREV_1M, sum(b.LTREV) as LTREV_1M,
			sum(c.ret) as ret_ld1M, sum(c.rf) as rf_ld1M, calculated ret_ld1M - calculated rf_ld1M as exret_ld1M,
			sum(c.mktrf) as mktrf_ld1M, sum(c.SMB) as SMB_ld1M, sum(c.HML) as HML_ld1M, sum(c.UMD) as UMD_ld1M,
			sum(c.STREV) as STREV_ld1M, sum(c.LTREV) as LTREV_ld1M
		from
			crsp_char_d0 as a
		left join
			crsp_char_d0 as b
			on
			b.permno = a.permno and b.date between a.win_st and a.date
		left join
			crsp_char_d0 as c
			on
			c.permno = a.permno and c.date between a.date and a.win_end
		group by
			a.permno, a.date
		order by
			a.permno, a.date;
quit;


proc sql;
	create table crsp_char_d0 as 
		select a.*, b.ret_1M, b.rf_1M, b.exret_1M, b.mktrf_1M, b.SMB_1M, b.HML_1M, b.UMD_1M, b.STREV_1M, b.LTREV_1M,
		b.ret_ld1M, b.rf_ld1M, b.exret_ld1M, b.mktrf_ld1M, b.SMB_ld1M, b.HML_ld1M, b.UMD_ld1M, b.STREV_ld1M, b.LTREV_ld1M
			from
				crsp_char_d0 as a
			left join
				crsp_char_d_expd as b
				on
				b.permno = a.permno and b.date = a.date
			order by
				a.permno, a.date;
quit;
