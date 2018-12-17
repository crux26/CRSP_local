/* Checking done! (2018.11.16) */
/* This yields a lot more nonmissing data than "B2M ratio - FF.sas". */
/* Too many are considered as missing using "B2M ratio - FF.sas". */
/*Using either csho or csho_ld1 is not wrong. prcc_c is measured at DEC, whereas csho is not.*/
/*prcc_c is in the middle of each fyear, not the end.*/
/* Note that w/o trim/winsorizing, there are explosions in BM (ex: gvkey=003066, permno=. BM_COMP=286396).*/
/* Also note that firms with nonsensical BM usually do not have PERMNO.*/
/*Deleted my comments. Refer to "B2M ratio - DT" for details.*/
/*Now ME is calendar year's DEC value, no matter what fiscar year-end month is.*/
/*All I have to do is to match this cal year t's values with cal year (t+1)'s June through cal year (t+2)'s May.*/
/*This won't be done here, but implementation step.*/
/*fic: contains many countries - 30-40. Use fic in ('USA', 'CAN') for North America. */
/*curcd: {'USD', 'CAD'} */
/* *************************************************************************** */
/* ********* W R D S   R E S E A R C H   A P P L I C A T I O N S ************* */
/* *************************************************************************** */
/*  Program      : market_to_book.sas                                          */
/*  Author       : Denys Glushkov, WRDS                                        */
/*  Date Created : Aug 2011                                                    */
/*  Last Modified: Aug 2011                                                    */
/*                                                                             */
/*  Description  : Calculate Raw and Industry Adjusted Market-to-Book Ratio    */
/*                 using separately Compustat only and CRSP-Compustat Merged   */
/*                 Compares the coverage, compute industry-level M/B ratios as */
/*                 well as industry-adjusted M/B at the company level          */
/* Output        : The output table INDADJMB contains firm-level raw M/B Ratios*/
/*                 using both approaches as well as their industry-adjusted    */
/*                 counterparts                                                */
/*                                                                             */
/*  Notes        : The program is based on a book-equity definition used by    */
/*                 Daniel and Titman in their "Market Reactions to Tangible    */
/*                 and Intangible Information" (Journal of Finance, 2006).     */
/*                 RA focuses on US companies, but can be extended to include  */
/*                 Canadian and international companies                        */
/*                                                                             */
/*                 Compustat Xpressfeed Total Liabilities(LT) no longer include */
/*                 the minority interest (MIB).Therefore, the new balance sheet */
/*                 equation Total Assets (AT) = Total Liabilities (LT) +       */
/*                 Minority Interest (MIB) + Stockholders' Equity (SEQ)        */
/* *************************************************************************** */
/* Calculating Market-to-Book using Compustat only                             */
/* Advantage: captures many firms that are in Compustat, but not in CRSP       */
%let bdate=01jun1983;
%let edate=31dec2012;
%let comp=comp;
%let crsp=a_stock;

/* Standard Compustat Filter*/
%let comp_filter=consol='C' and indfmt='INDL' and datafmt='STD' and popsrc='D';
%let ind=10;

/* Step 1. Create Book Equity (BE) measure                                     */
data comp_extract;
	/*data comp_extract/view=comp_extract;*/
	set &comp..funda;

	/*	where (at>0 or not missing(sale)) and &comp_filter and fic in ('USA');*/
	where (at>0 or not missing(sale)) and &comp_filter and fic in ('USA', 'CAN');
	calyear=year(datadate);

	if not missing(SEQ) then
		SHE=SEQ;
	else if nmiss(CEQ,PSTK)=0 then
		SHE=CEQ+PSTK;
	else if nmiss(AT,LT)=0 then
		SHE=AT-sum(LT,MIB);
	else SHE=.;
	PS = coalesce(PSTKRV, PSTKL, PSTK, .);
	BE0 = SHE-PS;

	if year("&bdate"d) - 1<=calyear<=year("&edate"d) + 1;
	keep gvkey calyear fyr fyear BE0 indfmt consol sich  
		datafmt popsrc datadate TXDITC prcc_f prcc_c csho curcd fic;
run;

proc sort data=comp_extract;
	by gvkey curcd datadate;
run;

proc printto log=junk_DT;
run;

options nonotes;

proc expand data=comp_extract out=comp_extract_;
	id datadate;
	convert prcc_c = prcc_c_ld1 / transformout=(reverse lag 1 reverse);
	convert csho = csho_ld1 / transformout=(reverse lag 1 reverse);
	by gvkey curcd;
run;

options notes;

proc printto;
run;

/*If fyr b/w [1,5], then prcc_c is from last Dec. Should match fyr with this calyear Dec's ME, so using lead1.*/
/*--> This is because ME in BE/ME is measured at the end of December of any given year.*/
data comp_extract__(drop=prcc_c_ld1 csho_ld1);
	set comp_extract_;

	if 1 <= fyr <=5 then
		do;
			prcc_c = prcc_c_ld1;
			csho = csho_ld1;
		end;
	if csho<=0 then mcap_c = .;
	else mcap_c = abs(prcc_c)*csho;
	label mcap_c="prcc_c*csho. Market Value of Equity at Dec end of calendar year t";
	label prcc_c="Calyear t's DEC value. Different from COMPUSTAT (last DEC's value if fyr b/w 1, 5)";
	label prcc_f="Same as comp.secm.prccm(datadate), no matter what (fyear, fyr) is.";
	label csho="Same as comp.funda.csho(datdate), no matter what (fyear, fyr) is.";
run;

proc sql;
	create table comp_be 
		as select  
			a.gvkey, a.calyear, a.fyr, a.datadate, a.fyear, a.mcap_c,
			a.csho,
			a.prcc_f, a.prcc_c, sum(a.BE0, a.TXDITC, -b.PRBA) as BE, a.curcd, a.fic, a.sich 
		from comp_extract__ as a 
			left join  
				&comp..aco_pnfnda (where=(&comp_filter)) as b 
				on a.gvkey=b.gvkey and a.datadate=b.datadate;
quit;

/* Step 2: calculate the market value as of calendar year t's Dec end.*/
/*SECM.datadate: Calendar date.*/
proc sort data=&comp..secm(where=( primiss='P' and fic in ('USA', 'CAN') and "&bdate"d<=datadate<="&edate"d) keep= gvkey iid datadate prccm curcdm cshoq fic primiss sortedby=gvkey iid datadate)
	out=secm(drop=iid primiss);
	by gvkey curcdm datadate;
run;

/**/
proc printto log=junk;
run;

proc expand data=secm out=mvalue;
	id datadate;
	convert cshoq / method=step;
	by gvkey curcdm;

proc printto;
run;

/**/
data mvalue_;
	set mvalue;
	where month(datadate)=12;
	mcap_dec = prccm*cshoq;
	rename prccm = prc_dec;
	label mcap_dec="prccm*cshoq, from comp.secm. Alternative to mcap_c. Use it only when missing(mcap_c)";
	keep gvkey datadate prccm curcdm cshoq mcap_dec fic;
run;

/*Some duplicates exist; seem to be due to data error.*/
proc sort data=mvalue_ nodupkey;
	by gvkey curcdm datadate;
run;

/* Step 3a. Create Book to Market (BM) ratios using COMPUSTAT only.   */
/*More obs with (be>0)*be/mcap_c (which are from comp.funda).*/
proc sql;
	create table bm_comp 
		as select a.gvkey, a.datadate format date9., a.calyear, a.fyr, a.fyear,  
			a.prcc_f, a.prcc_c, b.prc_dec, c.prccm,
			a.curcd, a.fic, a.sich, 
			a.csho, b.cshoq,
			a.be, a.mcap_c, b.mcap_dec, mdy(12,31,a.fyear) as fyear_end format=date9.,  
			coalesce( ( (be>0)*be/mcap_c), ( (be>0)*be)/mcap_dec ) as bm_comp 
		from comp_be as a 
			left join 
				mvalue_ as b 
				on a.gvkey=b.gvkey and a.calyear=year(b.datadate) and a.curcd=b.curcdm and a.fic=b.fic
			left join
				mvalue as c
				on a.gvkey=c.gvkey and a.calyear=year(c.datadate) and a.curcd=c.curcdm and a.fic=c.fic
			order by a.gvkey, a.curcd, a.datadate;
quit;

/* Step 3b. Alternatively, one can use Market value from CRSP as of  */
/* Dec end of fiscal year (instead using that of COMPUSTAT). */
/*Adjusted for CFACPR and CFACSHR for ME calculation in MSF.*/
/*ALTPRC: last non-missing price in the month. missing(PRC) does not mean 0 MktCap.*/
/*Use cal year DEC data for BM calculation.*/
data msf;
	set a_stock.msf(keep=permno date altprc shrout cfacpr cfacshr);
	date = intnx('month', date, 0, 'end');
run;

proc sql;
	create table bm_comp_crsp
		as select distinct a.*, b.lpermno as permno, b.lpermco as permco,  
			((a.be>0)*a.be) / ( ( abs(c.altprc)/c.cfacpr * c.shrout*c.cfacshr)/1000) as bm_crsp,  
			coalesce(a.sich,d.siccd) as sic 
			, d.siccd, d.exchcd, d.shrcd
		from bm_comp as a 
			left join
				a_ccm.ccmxpf_linktable as b 
				on 
				a.gvkey=b.gvkey and b.usedflag=1 
				and b.linkdt<=a.datadate and (a.datadate<=b.linkenddt or missing(b.linkenddt)) and linkprim in ('P','C')  
			left join 
				msf as c 
				on 
				b.lpermno=c.permno and intnx('year', a.datadate, 0, 'end') = c.date
			left join
				(select distinct permno, siccd, exchcd, shrcd, min(namedt) as mindate,  max(nameenddt) as maxdate 
					from a_stock.stocknames group by permno, siccd, exchcd, shrcd) as d 
						on
						b.lpermno=d.permno and d.mindate<=a.datadate<=d.maxdate
					order by a.gvkey, a.datadate, sic;
quit;

/* Step 4. Invoke FF industry classification                  */
data bm_comp_crsp;
	set bm_comp_crsp;
	by gvkey datadate;

	if last.datadate;
	%ffi&ind(sic);
run;

/* Trimming extreme values of Market-To-Book within industries */
proc sort data=bm_comp_crsp;
	by calyear ffi&ind._desc;
run;

proc rank data=bm_comp_crsp out=bm_comp_crsp groups=100;
	by calyear ffi&ind._desc;
	var bm_comp bm_crsp;
	ranks rbm_comp rbm_crsp; 
run;

data bm_comp_crsp;
	set bm_comp_crsp;

	if rbm_comp=99 then bm_comp=.; 

		if rbm_crsp=99 then
			bm_crsp=.;
run;
/* Step 6. Number of distinct companies with non-missing B/M */
/* based on COMPUSTAT only and based on CRSP-COMPUSTAT products*/
proc sql;
	create table bmcomp 
		as select distinct calyear,ffi&ind._desc,  
			count(distinct gvkey) as ngvkeys 
		from bm_comp_crsp where not missing(bm_comp)  and curcd in ('USD', 'CAD') and fic in ('USA', 'CAN')
			group by calyear, ffi&ind._desc;
	create table bmcrsp 
		as select distinct calyear,ffi&ind._desc,  
			count(distinct permco) as npermcos
		from bm_comp_crsp where not missing(bm_crsp)  and curcd in ('USD', 'CAD') and fic in ('USA', 'CAN')
			group by calyear, ffi&ind._desc;
quit;

data comparebmcov;
	merge bmcomp bmcrsp;
	by calyear ffi&ind._desc;
	diff=(ngvkeys-npermcos)/npermcos; /* <-- See Step 6. for this. */
	format diff percent7.4;
run;

proc transpose data=comparebmcov out=comparebmcov  
	(drop=_name_ label='Comparing Market-to-Book coverage between two methods');
	by calyear;
	id ffi&ind._desc;
	var diff; /* NGVKEY, NPERMCOs discarded here. */
run;

/*Step 7.  B/M ratios for different FF industries over time*/
/*Step 8. Industry-adjusted B/M ratios at the firm-year level*/
proc means data=bm_comp_crsp noprint;
	class calyear ffi&ind._desc;
	var bm_comp bm_crsp;
	where not missing(ffi&ind);
	output out=medians median=/autoname;
run;

proc sort data=medians;
	by calyear ffi&ind._desc;
run;

proc transpose data=medians out=temp 
	(label="Median Market-to-Book ratios for &ind  FF industries");
	by calyear;
	id ffi&ind._desc;
	var bm_comp_median;
run;

/* Take out the industry component                            */
/* INDADJBM contains the firm-level raw and industry-adjusted */
/* Book-to-Market ratios calculated using COMPUSTAT Only      */
/* as well as CRSP-COMPUSTAT Merged Product                   */
data indadjbm_DT;
	merge bm_comp_crsp medians;
	by calyear ffi&ind._desc;
	bm_comp_indadj = bm_comp - bm_comp_median;
	bm_crsp_indadj = bm_crsp - bm_crsp_median;

	if missing(ffi&ind._desc) then
		do;
			bm_comp_indadj = .;
			bm_crsp_indadj = .;
		end;

	label calyear='Calendar year of the fiscal period end'
		bm_comp='B/M ratio (Compustat Only)'
		bm_crsp='B/M ratio (CRSP-Compustat Merged)'
		bm_comp_indadj='Industry-adjusted B/M ratio (Compustat Only)'
		bm_crsp_indadj='Industry-adjusted B/M ratio (CRSP-Compustat Merged') 
		sic='Historical SIC code';

	if not missing(gvkey);
run;

proc sort data=indadjbm_DT;
	by gvkey datadate;
run;

data indadjbm_DT_;
	set indadjbm_DT;
	retain count;

	if first.gvkey then
		count=1;
	else count=count+1;
	label count="# of observations in COMPUSTAT";
	by gvkey datadate;
run;

proc sort data=indadjBM_DT_ out=indadjBM_DT_;
	by gvkey curcd datadate fyear fyr;
run;

data indadjbm_DT_final;
	set indadjBM_DT_;

	if last.fyr then
		output;
	by gvkey curcd datadate fyear fyr;
run;

/* Clean the house*/
proc sql;
	drop table comparebmcov, comp_be, bmcomp, bmcrsp, bm_comp,
		bm_comp_crsp, medians, temp, comp_extract, comp_extract_, comp_extract__, mvalue, mvalue_, indadjbm_DT, indadjbm_DT_, msf, secm;
quit;

/* ********************************************************************************* */
/* *************  Material Copyright Wharton Research Data Services  *************** */
/* ****************************** All Rights Reserved ****************************** */
/* ********************************************************************************* */
