/* Checking Done! (2017.08.31) */

/* INPUT: crsp_m, indadjbm */
/* This code basically follows <FF factors replication.sas>. */
/* Some parts are modified as indadjbm already has done some calculations. */
/* Idea: replace B2M of FF with DT method. Everything else is the same. */

/*-------------------------Part 1: data preparation------------------*/
data crsp_m; set mysas.crsp_m; run;

data indadjbm_dt; set mysas.indadjbm_dt; run;

proc sort data=indadjbm_dt; by datadate gvkey; run;

data indadjbm_dt; set indadjbm_dt;
me = coalesce(mcap_c, mcap_dec);
label me="coalesce(mcap_c, mcap_dec)";
run;
/*-----------------------Part 2: follow <FF factors replication.sas>-----------------------------*/
data crsp_m2; set crsp_m;
retadj = sum(1,ret) * sum(1,dlret) - 1;
MEq = abs(prc) * shrout/1000;
run;

proc sort data=crsp_m2; by date permco MEq; run;

data crsp_m2a (drop=MEq); set crsp_m2;
by date permco MEq;
retain ME;
if first.permco and last.permco then do;
	ME=MEq; output;
end;
else do;
	if first.permco then ME=MEq;
	else ME=sum(MEq, ME);
	if last.permco then output;
end;
run;

proc sort data=crsp_m2a nodupkey; by permno date; run;

data crsp_m3 DECME(rename=(ME=DEC_ME)); set crsp_m2a;
by permno date;
retain weight_port cumretx ME_base;
Lpermno = lag(permno); LME = lag(ME);
if first.PERMNO then do;
	LME = ME/(1+retx);
	cumretx = sum(1,retx);
	ME_base = LME;
	weight_port=. ;
end;
else do;
	if month(date)=7 then do;
		weight_port = LME;
		me_base = LME;
		cumretx = sum(1,retx);
	end;
	else do;
		if LME>0 then weight_port = cumretx * ME_base;
		else weight_port =. ;
		cumretx = cumretx * sum(1,retx);
	end;
end;
output crsp_m3;
if month(date)=12 and ME>0 then output DECME;
run;

proc sql;
	create table crsp_june (label="CRSP only, June only (no COMPUSTAT or ccmxpf_linktable)") as
	select a.*, b.DEC_ME, b.date as date_lastDEC
	from crsp_m3 (where=(month(date)=6)) as a, decme as b
  	where a.permno=b.permno and
  	intck('month',b.date,a.date)=6;
quit;

/*--------------------------Setting NYSE breakpoints----------------------------------*/

proc univariate data=indadjbm_dt noprint;
  where exchcd=1 and bm_crsp>0 and shrcd in (10,11) and me>0 and count>=2;
/*COUNT: Specific firm's number of observations in COMPUSTAT.COUNT=1: first.gvkey (sorted by gvkey datadate). */
/*--> why discard COUNT=1 or first.gvkey=1? (O) */
/* Table june below says it: "more than two years in COMPUSTAT". */
/*COUNT=1 or first.gvkey observation may not have a 12M or 1 full year data - only some portion of it. */
/*ex) DATE=19870630, PERMNO=10001, GVKEY=012994, DATADATE=19860630, FYEAR=1986, FYR=6*/
  var me bm_crsp;
  by datadate; /*at June (ccm2_june.date: June only) */
  output out=nyse_breaks median = SIZEMEDN pctlpre=ME BEME pctlpts=30 70;
run;

/* Use Breakpoints to classify stock only at end of all June's */
proc sql;
create table tmp_0 as
select a.*, b.sizemedn, b.beme30, b.beme70
from indadjbm_dt as a
left join
nyse_breaks as b
on a.datadate = b.datadate;
quit;

data tmp_1; set tmp_0;
if bm_crsp>0 and me>0 and count>=2 then do;
	positivebeme=1;
	if 0 <= me <=sizemedn then sizeport = 'S';
	else if me>sizemedn then sizeport = 'B';
	else sizeport=' ' ;

	if 0< bm_crsp <= beme30 then btmport = 'L';
	else if beme30 < bm_crsp <= beme70 then btmport = 'M';
	else if bm_crsp > beme70 then btmport = 'H';
	else btmport =' ' ;
end;
else positivebeme=0;

if cmiss(sizeport,btmport)=0 then nonmissport=1; else nonmissport=0;
keep permno datadate sizeport btmport positivebeme exchcd shrcd nonmissport;
label btmport="used DT's definition of B2M (not FF's)";
run;

data june; set tmp_1;
if month(datadate) ^=6 then delete;
run;

proc sort data=june; by permno date; run;

/**/

proc sql;
create table tmp_2 as
 select a.*, b.sizeport, b.btmport, b.datadate as portdate label="Portfolio formation date" format date9., 
        b.positivebeme , b.nonmissport 
 from crsp_m3 as a, june as b
 where a.permno=b.permno and  1 <= intck('month',b.datadate,a.date) <= 12
/*b.date and a.date have the same calendar year date. */
 order by date, sizeport, btmport, permno;
quit;

proc means data=tmp_2 noprint;
 where weight_port>0 and positivebeme=1 and exchcd in (1,2,3,4) 
      and shrcd in (10,11) and nonmissport=1;
/*WEIGHT_PORT: last month's ME * cumretx. Missing until firm's first July. */
/*That is, if first.DATE=19860831, then first.WEIGHT_PORT=19870731. */
 by date sizeport btmport;
 var retadj;
 weight weight_port;
 output out=vwret_DT (drop= _type_ _freq_ ) mean=vwret n=n_firms;
/*Why n=1 whereas size, B2M portfolios contain far more than 1 firm? --> Unknown error. No more exists. */
run;

proc transpose data=vwret_DT(keep=date sizeport btmport vwret) 
out=vwret_DT2 (drop=_name_ _label_);
by date ;
ID sizeport btmport;
Var vwret;
run;
   
/************************ Part 6: Saving Output ************************/
data ff_factors_DT;
set vwret_DT2;
 WH = (bh + sh)/2  ;
 WL = (sl + bl)/2 ;
 WHML = WH - WL;
 WB = (bl + bm + bh)/3 ;
 WS = (sl + sm + sh)/3 ;
 WSMB = WS - WB;
 label WH   = 'WRDS High'
       WL   = 'WRDS Low'
       WHML = 'WRDS HML'
       WS   = 'WRDS Small'
       WB   = 'WRDS Big'
       WSMB = 'WRDS SMB';
run;

/* Number of Firms */
proc transpose data=vwret_DT(keep=date sizeport btmport n_firms) 
               out=vwret_DT3 (drop=_name_ _label_) prefix=n_;
by date ;
ID sizeport btmport;
Var n_firms;
run;

data ff_nfirms_DT;
set vwret_DT3;
 N_H = n_sh + n_bh;
 N_L = n_sl + n_bl;
 N_HML = N_H + N_L;
 N_B =  n_bl + n_bm + n_bh;
 N_S =  n_sl + n_sm + n_sh ;
 N_SMB = N_S + N_B;
 Total= N_SMB;
 label N_H   = 'N_firms High'
       N_L   = 'N_firms Low'
       N_HML = 'N_firms HML'
       N_S   = 'N_firms Small'
       N_B   = 'N_firms Big'
       N_SMB = 'N_firms SMB';
run;

data mysas.ff_nfirms_DT; set ff_nfirms_DT; run;
data mysas.ff_factors_DT; set ff_factors_DT; run;
data mysas.ff_vwret_DT; set vwret_DT; run;
