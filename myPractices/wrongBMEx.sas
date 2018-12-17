/*Wrong prcc_c, prccm for BM calculation.*/
/*comp.secm.prccm may give wrong results while crsp.msf does not.*/

proc sort data=indadjbm_dt_final
(keep=gvkey permno datadate fyear fyr bm_comp BE prcc_f prcc_c prccm csho cshoq mcap_c mcap_dec) 
	out=_BE nodupkey;
	by descending bm_comp;
run;

/*-->gvkey=009774, datdate=30apr2013 (permno=70923) */

/*BE*/
data _BE;
set indadjbm_dt_final;
where gvkey='009774';
keep gvkey permno datadate fyear fyr bm_comp BE prcc_f prcc_c prccm csho cshoq mcap_c mcap_dec; 
run;


data _funda;
set comp.funda;
where gvkey='009774' AND consol='C' and indfmt='INDL' and datafmt='STD' and popsrc='D' ;
keep gvkey datadate prcc_f prcc_c csho;
run;

/*Find the prccm in secm.*/
/*data _secm;*/
/*set comp.secm;*/
/*where gvkey='009774' and year(datadate)=2013;*/
/*keep gvkey datadate prccm cshoq cshom;*/
/*run;*/
data _secm;
set comp.secm;
where gvkey='009774' ;
keep gvkey datadate prccm cshoq cshom;
run;



/*Find the PRC in CRSP.*/
data _crsp;
set a_stock.msf;
where permno=70923 and year(date)=2013;
keep permno date prc altprc shrout;
run;
