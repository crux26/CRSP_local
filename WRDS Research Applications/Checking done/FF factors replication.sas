/*Checking Done! (2017.06.15).*/
/* See "DGTW.sas" or "Size Portfolios for CRSP common stocks and NYSE Size Break Points.sas" */
/* for more flexible size & B2M percentiles. */

/*Output data sets: ff_factors, ff_nfirms, ff_vwret. */

/* Compare with %SIZE_BM(). */
/* Note that calculation details are slightly different. */

/* www.crsp.com) PERMCO: CRSP's permanent company identifier */
/*PERMNO: CRSP'S permanent issue identifier. One PERMNO belings to only one PERMCO.*/
/*One PERMCO can have one or more PERMNOs. */

/* *************************************************************************** */
/* ********* W R D S   R E S E A R C H   A P P L I C A T I O N S ************* */
/* *************************************************************************** */
/*  Program        : fama_french_factors_replication.sas                       */
/*  Authors        : Luis Palacios (WRDS), Premal Vora (Penn State)            */
/*  Date           : 04/2009                                                   */
/*  Last modified  : 08/2011                                                   */
/*  Description    : Replicates Fama-French (1993) SMB & HML Factors           */
/* *************************************************************************** */
   
/*%let comp=compq;*/
/*%let crsp=crspq;*/
/* compq: OLD library name of North America - Monthly Update. Now it is "comp (or compm)". */
%let comp=mysas;
%let crsp=mysas;
/* Major files in comp. & crsp. are copied to mysas. */

   
/************************ Part 1: Compustat ****************************/
/* Compustat XpressFeed Variables:                                     */
/* AT      = Total Assets                                              */
/* PSTKL   = Preferred Stock Liquidating Value                         */
/* TXDITC  = Deferred Taxes and Investment Tax Credit                  */
/* PSTKRV  = Preferred Stock Redemption Value                          */
/* SEQ     = Total Parent Stockholders' Equity                         */
/* PSTK    = Preferred/Preference Stock (Capital) - Total              */
   
/* In calculating Book Equity, incorporate Preferred Stock (PS) values */
/*  use the redemption value of PS, or the liquidation value           */
/*    or the par value (in that order) (Fama, French, JFE, 1993, p. 8)            */
/* USe Balance Sheet Deferred Taxes TXDITC if available                */
/* Flag for number of years in Compustat (<2 likely backfilled data)   */
   
%let vars = AT PSTKL TXDITC PSTKRV SEQ PSTK ;
data comp;
  set &comp..funda
  (keep= gvkey datadate fyr fyear &vars indfmt datafmt popsrc consol);
/*(gvkey, datadate, indfmt, datafmt, popsrc, consol), sextuple, comprises an unique observation. */
  by gvkey datadate;
  where indfmt='INDL' and datafmt='STD' and popsrc='D' and consol='C'
  and datadate >='01Jan1959'd;
 /* Two years of accounting data before 1962 */
/* COMPUSTAT data prior to 1962 are often missing, and have survivorship bias (Fama, French, 1993). */
  PS = coalesce(PSTKRV,PSTKL,PSTK,0);
/* If all above three missing, then set PS to 0. */
  if missing(TXDITC) then TXDITC = 0 ;
  BE = SEQ + TXDITC - PS ;
  if BE<0 then BE=.;

  year = year(datadate);
/* DATADATE: calendar year of COMPUSTAT. Different from FYEAR. */
  label BE='Book Value of Equity FYEAR t-1 for FYR le May, FYEAR t for FYR ge Jun' ; 
/*Above label true for only FYR b/w [Jan, May]. */ 
/* Firms whose FYR is b/w [Jun, Dec] have FYEAR t*/
  label datadate="COMPUSTAT date";
  
  drop indfmt datafmt popsrc consol ps &vars;
  retain count;
/* If RETAIN statement not used, then COUNT below will not work. --> Checked not working. */
/* RETAIN: Causes a variable that is created by an INPUT or assignment statement
  to retain its value from one iteration of the DATA step to the next. */
  if first.gvkey then count=1;
  else count = count+1;
  label count="Number of observations in COMPUSTAT";
/* To count the number of observations of given company. */
run;
   
/************************ Part 2: CRSP **********************************/
/* Create a CRSP Subsample with Monthly Stock and Event Variables       */
/* This procedure creates a SAS dataset named "CRSP_M"                  */
/* Restrictions will be applied later                                   */
/* Select variables from the CRSP monthly stock and event datasets      */
%let msevars = ticker ncusip shrcd exchcd;
%let msfvars = permco prc ret retx shrout cfacpr cfacshr;
   
/*%include '/wrds/crsp/samples/crspmerge.sas';*/
%include myMacro('crspmerge.sas');   
%crspmerge(s=m,start=01jan1959,end=31dec2016,
/*sfvars=&msfvars,sevars=&msevars,filters=exchcd in (1,2,3), outset=crsp_m);*/
sfvars=&msfvars,sevars=&msevars,filters=exchcd in (1,2,3,4), outset=crsp_m);
/* EXCHCD=1,2,3,4: NYSE, NYSE MKT (AMEX), NASDAQ, Arca, respectively.  */

/* CRSP_M is sorted by date and permno and has historical returns     */
/* as well as historical share codes and exchange codes               */
/* Add CRSP delisting returns */
proc sql;
create table crspm2
 as select a.*, b.dlret,
  sum(1,ret)*sum(1,dlret)-1 as retadj "Return adjusted for delisting",
/*can use sum(ret, dlret) instead (ignoring small difference). */
  abs(a.prc)*a.shrout/1000 as MEq 'Market Value of Equity in unit of million dollars'
/*shrout: reported in the unit of #1k. */
 from crsp_m as a
left join
&crsp..msedelist(where=(missing(dlret)=0)) as b
/* where dlret is not missing */
 on a.permno=b.permno and
    intnx('month',a.date,0,'E')=intnx('month',b.DLSTDT,0,'E')
/* crsp_m observations remain even if "on" clauses are not met (as crsp_m is "a" and it's left join). */
/* Return adjusted for delisting if month(a.date) = month(b.dlstdt). */
/* On the delisted month, "crsp_m" writes RET as missing, and "msedelist" writes DLRET as non-missing. */
/* Note that crsp_m.date is month's end date, and msedelist.date is mostly not month's end date. */
/*b.dlstdt: Delisting date */
 order by a.date, a.permco, MEq;
quit;

/* www.crsp.com) PERMCO: CRSP's permanent company identifier */
/*PERMNO: CRSP'S permanent issue identifier. One PERMNO belings to only one PERMCO.*/
/*One PERMCO can have one or more PERMNOs. */

/* There are cases when the same firm (permco) has two or more         */
/* securities (permno) at same date. For the purpose of ME for         */
/* the firm, we aggregated all ME for a given permco, date. This       */
/* aggregated ME will be assigned to the Permno with the largest ME.    */
/*--> That is, if 1 permco(aa) has 2 permno (111,222) where ME111=10, ME222=20. */
/* Then assign 30 to "222", so ME222=30. */
data crspm2a (drop = MEq); set crspm2;
  by date permco Meq;
  retain ME;
/* If RETAIN statement isn't used, then aggregating ME over PERMCO may not work. */
  if first.permco and last.permco then do;
/* If a firm has only one PERMNO, then it will have only one observation of PERMCO each date. */
  ME=meq;
  output; /* most common case where a firm has a unique permno*/
  end;
  else do ;
    if  first.permco then ME=meq;
/* If one PERMCO has multiple PERMNO, then PERMCO having the same value will have multiple observations */
/* on each date, each for different PERMNOs. */
/*meq: calculated w.r.t. PERMNO in above table crspm2. */
    else ME=sum(meq,ME);
/*If PERMCO has multiple observations (note that value of PERMCO remains same over multiple observations),  */
/* then aggregate it ("cumulative sum" over different PERMNO, paired with one single PERMCO). */
    if last.permco then output;
  end;
run;
   
/* There should be no duplicates*/
proc sort data=crspm2a nodupkey; by permno date; run;
   
/* The next step does 2 things:                                        	*/
/* crspm3 - Create weights for later calculation of VW returns. 	*/
/* Each firm's "monthly" return RET "t" willl be WEIGHTED by 		*/
/* ME(t-1) = ME(t-2) * (1 + RETX (t-1)) <-- "t" is an index of month */
/* where RETX is the without-dividend return.                  		*/
/* decme - Create a File with December t-1 Market Equity (ME)*/
data crspm3 (keep=permno date retadj weight_port ME exchcd shrcd cumretx)
decme (keep = permno date ME rename=(me=DEC_ME) )  ;
/*DEC_ME: ME in December. 	decme: subset of crspm3. Containing DEC values only. */
/* 2 output sets: crspm3, decme (both generated from crspm2a) */
set crspm2a;
by permno date;
retain weight_port cumretx me_base;
Lpermno=lag(permno);
LME=lag(me); 
/*LME: last month's ME. */
    if first.permno then do;
    	LME=me/(1+retx); 
		cumretx=sum(1,retx);
		me_base=LME;
		weight_port=. ;
	end;
    else do;
    	if month(date)=7 then do;
        	weight_port= LME;
/*weight_port: no cumretx here, because July is the base month, so nothing cumulated. */
        	me_base=LME; 
        	cumretx=sum(1,retx);
/*cumretx: has a base month of June. Cumulates return from June to current date. */
		end;
		else do; /* month(date) ^= July */
	        if LME>0 then weight_port = cumretx * me_base ;
/* me_base: Update only at July with June's value. */
/* If date<July, then me_base = ME(first.permno). If date>=July, then me_base = ME(this year's June). */
/*weight_port: me_base (of July) times cumretx (from June upto current date). */
	        else weight_port=.;
	        cumretx=cumretx*sum(1,retx);
    	end;
	end;
output crspm3;
if month(date)=12 and ME>0 then output decme;
run;

   
/* Create a file with data for each June with ME from previous December */
proc sql;
  create table crspjune (label="CRSP only, June only (no COMPUSTAT or ccmxpf_linktable)") as
  select a.*, b.DEC_ME, b.date as date_lastDEC
  from crspm3 (where=(month(date)=6)) as a, decme as b
  where a.permno=b.permno and
  intck('month',b.date,a.date)=6;
/*b.date + 6 = a.date. b.date: "last December", a.bdate: "this June"*/
quit;
   
/***************   Part 3: Merging CRSP and Compustat ***********/
/* Add Permno to Compustat sample */
proc sql;
  create table ccm1(label="COMPUSTAT & ccmxpf_linktable only") as
  select a.*, b.lpermno as permno, b.linkprim
/* LPERMNO: CRSP PERMNO link during link period. */
/*LINKPRIM=P: Primary, identified by COMPUSTAT. =C: Primary, assigned by CRSP. */
  from comp as a, &crsp..ccmxpf_linktable as b
  where a.gvkey=b.gvkey
  and substr(b.linktype,1,1)='L' and linkprim in ('P','C')
/*ex) Str="abcd3021". Then substr(Str,5,2)=30, substr(Str,6,3)=021. */
/*substr(b.linktype,1,1): 'L' or 'N'. L for link, N for no link available. */
/*LINKPRIM=P: Primary, identified by COMPUSTAT. =C: Primary, assigned by CRSP. */
  and (intnx('month', intnx('year', a.datadate, 0, 'E'), 6, 'E') >= b.linkdt)
/* result of above: where a.datadate's next year's June >= b.linkdt */
  and (b.linkenddt >= intnx('month',intnx('year',a.datadate,0,'E'), 6, 'E')
/* result of above: where a.datadate's next year's June <= b.linkenddt */
  or missing(b.linkenddt))
/*LINKENDDT="E": considered as missing (although it's not null).*/
  order by a.datadate, permno, b.linkprim desc;
quit;
   
/*  Cleaning Compustat Data for no relevant duplicates                      */
/*  Eliminating overlapping matching : few cases where different gvkeys     */
/*  for same (permno, date) --- some of them are not 'primary' matches in CCM  */
/*  Use linkprim='P' for selecting just one (gvkey, permno, date) combination   */
/* --> This is achieved by sorting descending linkprim (linkprim in ('P','C') above in table ccm1). */
data ccm1a (label="COMPUSTAT & ccmxpf_linktable only"); set ccm1;
  by datadate permno descending linkprim;
/*descending linkprim: P will appear first. Then C. */
/*--> If multiple observations for PERMNO, then P will be chosen, not C. */
  if first.permno;
/* If multiple observations for PERMNO for single datadate, drop all except the first one. */
run;
   
/* Sanity Check -- No Duplicates */
proc sort data=ccm1a nodupkey; by permno year datadate; run;
/* As "if first.permno" above in table ccm1a should drop all duplicates. */
   
/* 2. However, there are other types of duplicates within the year.                */
/* Some companiess change fiscal year end in the middle of the calendar year. */
/* In these cases, there are more than one annual record for accounting data. */
/* We will be selecting the "last" annual record in a given calendar year.      */
data ccm2a (label="COMPUSTAT & ccmxpf_linktable only"); set ccm1a;
  by permno year datadate;
  if last.year;
run;
   
/* Sanity Check -- No Duplicates */
proc sort data=ccm2a nodupkey; by permno datadate; run;
   
/* Finalize Compustat Sample.                              */
/* Merge CRSP with Compustat data, at June of every year.  */
/* Match fiscal year ending calendar year t-1 (DATADATE. Can be any month) with June t (DATE). */
proc sql; 
  create table ccm2_june (label="CRSP + COMPUSTAT & ccmxpf_linktable, matched at June") as
  select a.*, b.BE, b.BE/a.DEC_ME as BEME, b.count,
  b.datadate,
  intck('month',b.datadate, a.date) as dist label='(crspjune.date - ccm2a.datadate) in month'
  from crspjune as a, ccm2a as b
  where a.permno=b.permno and intnx('month',a.date,0,'E')=
  intnx('month',intnx('year',b.datadate,0,'E'),6,'E')
  order by a.date, a.permno;
quit;

/************** Part 4: Size and Book to Market Portfolios *************/
/* Forming Portolio by ME and BEME as of each June t                   */
/* Calculate NYSE Breakpoints for Market Equity (ME) and               */
/* Book-to-Market (BEME)                                               */
proc univariate data=ccm2_june noprint;
  where exchcd=1 and beme>0 and shrcd in (10,11) and me>0 and count>=2;
/*COUNT: Specific firm's number of observations in COMPUSTAT.COUNT=1: first.gvkey (sorted by gvkey datadate). */
/*--> why discard COUNT=1 or first.gvkey=1? (O) */
/* Table june below says it: "more than two years in COMPUSTAT". */
/*COUNT=1 or first.gvkey observation may not have a 12M or 1 full year data - only some portion of it. */
/*ex) DATE=19870630, PERMNO=10001, GVKEY=012994, DATADATE=19860630, FYEAR=1986, FYR=6*/

/*EXCHCD=1: NYSE, SHRCD, first digit=1: Ordinary common shares. */
/*SHRCD, second digit=0: Securities which have not been further defined. */
/*SHRCD, second digit=1: Securities which need not be further defined. */
  var ME BEME;
  by date; /*at June (ccm2_june.date: June only) */
  output out=nyse_breaks median = SIZEMEDN pctlpre=ME BEME pctlpts=30 70;
run;
   
/* Use Breakpoints to classify stock only at end of all June's */
proc sql;
  create table ccm3_june as
  select a.*, b.sizemedn, b.beme30, b.beme70
  from ccm2_june as a, nyse_breaks as b
  where a.date=b.date;
quit;
   
/* Create portfolios as of June                       */
/* SIZE Portfolios          : S[mall] or B[ig]        */
/* Book-to-market Portfolios: L[ow], M[edium], H[igh] */
data june ; set ccm3_june;
 If beme>0 and me>0 and count>=2 then do;
 positivebeme=1;
 * beme>0 includes the restrictioncs that ME at Dec(t-1)>0
 * and BE (t-1) >0 and more than two years in Compustat ("count>=2");
	 if 0 <= ME <= sizemedn     then sizeport = 'S';
	 else if ME > sizemedn      then sizeport = 'B';
	 else sizeport=.;
/*can use '' instead of . for missing. */
/*SIZEPORT: non missing ONLY IF "beme>0 (and me>0 and count>=2)"*/
	 if 0 < beme <= beme30 then           btmport = 'L';
	 else if beme30 < beme <= beme70 then btmport = 'M' ;
	 else if beme  > beme70 then          btmport = 'H';
	 else btmport=.;
  end;
  else positivebeme=0;
/*BE: many of it missing --> BEME missing as well. */
/*ME: less often missing than BE. */

if cmiss(sizeport,btmport)=0 then nonmissport=1; else nonmissport=0;
/*cmiss(): counts the number of missing arguments. */
keep permno date sizeport btmport positivebeme exchcd shrcd nonmissport;
run;
   
/* Identifying each month the securities of              */
/* Buy and hold June portfolios from July t to June t+1  */
proc sql;
create table ccm4 as
 select a.*, b.sizeport, b.btmport, b.date as portdate label="Portfolio formation date" format date9., 
        b.positivebeme , b.nonmissport 
 from crspm3 as a, june as b
 where a.permno=b.permno and  1 <= intck('month',b.date,a.date) <= 12
/*b.date and a.date have the same calendar year date. */
 order by date, sizeport, btmport, permno;
quit;
   
/*************** Part 5: Calculating Fama-French Factors  **************/
/* Calculate monthly time series of weighted average portfolio returns */
proc means data=ccm4 noprint;
 where weight_port>0 and positivebeme=1 and exchcd in (1,2,3) 
      and shrcd in (10,11) and nonmissport=1;
/*WEIGHT_PORT: last month's ME * cumretx. Missing until firm's first July. */
/*That is, if first.DATE=19860831, then first.WEIGHT_PORT=19870731. */
 by date sizeport btmport;
 var retadj;
 weight weight_port;
 output out=vwret (drop= _type_ _freq_ ) mean=vwret n=n_firms;
/*Why n=1 whereas size, B2M portfolios contain far more than 1 firm? --> Unknown error. No more exists. */
run;
   
/* Monthly Factor Returns: SMB and HML */
proc transpose data=vwret(keep=date sizeport btmport vwret) 
 out=vwret2 (drop=_name_ _label_);
 by date ;
 ID sizeport btmport;
 Var vwret;
run;
   
/************************ Part 6: Saving Output ************************/
data ff_factors;
set vwret2;
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
proc transpose data=vwret(keep=date sizeport btmport n_firms) 
               out=vwret3 (drop=_name_ _label_) prefix=n_;
by date ;
ID sizeport btmport;
Var n_firms;
run;
   
data ff_nfirms;
set vwret3;
 N_H = n_sh + n_bh;
 N_L = n_sl + n_bl;
 N_HML = N_H + N_L;
 N_B =  n_bl + n_bm + n_bh;
 N_S =  n_sl + n_sm + n_sh ;
 N_SMB = N_S + N_B;
 Total1= N_SMB;
 label N_H   = 'N_firms High'
       N_L   = 'N_firms Low'
       N_HML = 'N_firms HML'
       N_S   = 'N_firms Small'
       N_B   = 'N_firms Big'
       N_SMB = 'N_firms SMB';
run;
   
/* Clean the house*/
/*proc sql; */
/*   drop table ccm1, ccm1a,ccm2a,ccm2_june,*/
/*              ccm3_june, ccm4, comp,*/
/*              crspm2, crspm2a, crspm3, crsp_m,*/
/*              decme, june, nyse_breaks;*/
/*quit;*/
 
/* ********************************************************************************* */
/* *************  Material Copyright Wharton Research Data Services  *************** */
/* ****************************** All Rights Reserved ****************************** */
/* ********************************************************************************* */
