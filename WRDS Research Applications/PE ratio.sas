/* ********************************************************************************* */
/* ************** W R D S   R E S E A R C H   A P P L I C A T I O N S ************** */
/* ********************************************************************************* */
/*********************************************************************************** */
/*Program      : PE.sas                                                              */
/*Author       : Denys Glushkov, WRDS                                                */
/*Date Created : Oct 2010, Last Modified: Sep 2011                                   */
/*Last Modified: Oct 2010                                                            */
/*Location     : /wrds/comp/samples                                                  */
/*                                                                                   */
/*Input  : Specify beginning (BEGINDATE) and ending (ENDDATE) for                    */
/*         sample dates for P/E rati calculation, type of Compustat income variable  */
/*        (macro variable INCOME) to be used (IBQ - excluding extraordinary items or */
/*         NI - including extraordinary items)                                       */
/*         The horizon for long-term P/E ratio (PY) - number of past years over      */
/*         which income will be averaged)                                            */
/*                                                                                   */
/*Output : The program calculates 4 types of P/E ratios:                             */
/*         a) Trailing 12 months (PE_tt12m)                                          */
/*         b) Shiller's long-term P/E (PE10y)                                        */
/*         c) Unlevered P/E (PE_Unlevered)                                           */
/*         d) Forward-looking P/E (PE_forward)                                       */
/*                                                                                   */
/*         Values of P/E ratios will be stored in the datasets with respective names */
/*         P/E ratios are calculated both at the firm level as well as for S&P 500   */
/*         Index and major ten S&P 500 sectors.                                      */
/*                                                                                   */
/*         Firm-specific P/E ratios  are aggregated using 4 different methods        */
/*         1) Median                                                                 */
/*         2) Mean of positive-only P/E ratios                                       */
/*         3) Inverted Mean Earning Yield (EY)                                       */
/*         4) Total Market Value/Total Earnings                                      */
/*                                                                                   */
/* Examples of output datasets:                                                      */
/* PE_tt12m_Financials contains trailing 12 months P/E for S&P500 Financials sector  */
/* PE_PE10y_CompLtd contains Shiller P/E ratio for S&P 500 Composite Index           */
/* PE_Forward_Energy contains Forward P/E ratio for S&P 500 Energy Sector            */
/*                                                                                   */
/* Numbers at the end of variable name in a dataset refer to the method used for P/E */
/* aggregation within the index                                                      */
/*  E.g., PE_tt12m_heathcare3 variable in PE_tt12m_Healthcare file is aggregate P/E  */
/*  for S&P 500 HealthCare sector calculated using inverted E/P yield method         */
/*                                                                                   */
/*                                                                                   */
/*IMPORTANT : To be able to run the program, a user should have access to CRSP,      */
/*            Compustat, CRSP-Compustat Merged and IBES                              */
/*********************************************************************************** */
   
libname home '~'; /*home directory*/
 
%let begindate=01jan1950; /* start calendar date of fiscal period end                */
%let enddate=30jun2011;   /* end calendar date of fiscal period end                  */
%let income=ibq;          /* use Income Before Extraordinary Items                   */
%let PY=10;               /* years to go back in calculating long-term Shiller's P/E */
%let Comp=Compq;          /* Annual or Monthly updates for Compustat data            */
%let Crsp=Crspq;          /* Annual or Quarterly updates for CRSP data               */
   
/*Retrieve basic fundamental data from Compustat Quarterly  */
/*Unlevered Earnings=Earnings+Interest Expense (Welch, 2009)*/
data Comp_Earnings; set &Comp..Fundq;
  where "&begindate"d<=datadate<="&enddate"d and consol='C'
         and popsrc='D' and indfmt='INDL' and datafmt='STD';
  keep gvkey ajexq niq ibq xiq xintq dlttq rdq saleq atq prccq cshoq conm
       cshoq_adj fyearq fqtr datadate fyr epsx12 mcap prccq_adj
       unlevered_&income leverage rdq_new;
  mcap=abs(prccq*cshoq);
  prccq_adj=abs(prccq/ajexq);cshoq_adj=abs(cshoq*ajexq);
  unlevered_&income=sum(&income,xintq);leverage=(dlttq/atq);
  /* if RDQ is missing, assume earnings become public */
  /* 45 days following the fiscal year end            */
  rdq_new=coalesce(rdq, intnx('day',datadate,45));
  format rdq_new date9.; 
run;
   
/* Determine the closest trading date following a known or an imputed EAD*/
proc sql;
 create view Eads as select distinct rdq_new from comp_earnings;
 create view Close_Trade_Date
  as select a.*, b.date as close_trade_day format=date9.
  from eads a left join
  (select distinct date from &Crsp..dsi where "&begindate"d<=date<="&enddate"d) b
  on b.date-a.rdq_new>=0
  group by rdq_new
  having (b.date-a.rdq_new)=min(b.date-a.rdq_new);
     
/* Supplement missing market values from Compustat Security Monthly            */
/* Calculate market values as of the end of the month of earnings announcement */
/* as it includes price response to the most recent earnings announcement      */
 create table Comp_Earnings (drop=close_trade_day)
  as select a.*, coalesce(b.prccd*a.cshoq,mcap) as mcap_final,
  (b.prccd/b.ajexdi) as prccd_adj
  from (select c.*, d.close_trade_day from Comp_Earnings c
        left join Close_Trade_Date d on c.rdq_new=d.rdq_new) a
  left join
  &Comp..Sec_Dprc (keep=gvkey iid datadate prccd ajexdi where=(iid='01')) b
  on a.gvkey=b.gvkey and a.close_trade_day=b.datadate;
quit;
   
/*Merge in CRSP identifiers. Needed later to merge GVKEY with IBES Ticker*/
proc sql;
 create view Crsp_IDs
  as select a.*, b.lpermno as permno, b.lpermco as permco
  from Comp_Earnings a left join &Crsp..Ccmxpf_Linktable b
  on a.gvkey=b.gvkey and (b.linkdt<=a.rdq_new<=b.linkenddt
     or (b.linkdt<=a.rdq_new and missing(b.linkenddt)))
    and b.usedflag=1 and b.linkprim in ('P','C')
  group by a.gvkey, datadate, permno
  having fyearq=min(fyearq);
      
/*If firm has duplicate gvkey-datadate observations due the fiscal year change  */
/*keep the record with the latest fiscal quarter for a given gvkey-datadate pair*/
 create table Comp_Earnings
  as select a.*, b.ibtic
  from Crsp_IDs a left join
  (select distinct gvkey, ibtic from &Comp..Security
  where not missing(ibtic) and iid='01') b
  on a.gvkey=b.gvkey
  group by a.gvkey, a.datadate
  having fqtr=max(fqtr)
 order by a.gvkey, a.datadate;
quit;
 
/*Sanity check: are there duplicate gvkey-datadate observations*/
/*should be zero duplicates                                    */ 
proc sort data=Comp_Earnings nodupkey; by gvkey datadate;run;
   
/*CRSP-IBES link  table */
%iclink;
   
/*which firms have permnos, but have no matching IBES ticker*/
data Noticker/view=noticker; set Comp_Earnings;
 where not missing(permno) and missing(ibtic);
 drop ibtic;
run;
/*link in additional IBES ticker-PERMNO  matches*/
proc sort data=Home.Iclink (where=(score in (0,1))) out=Ibeslink;
 by permno ticker score;
run;
data Ibeslink; set Ibeslink;
 by permno ticker; if first.permno;
run;
proc sql; create table Noticker1
 as select a.*, b.ticker as ibtic
 from Noticker a left join Ibeslink b
 on a.permno=b.permno
 order by gvkey, datadate;
quit;
   
/*append the additional GVKEY-IBES Ticker links*/
data Comp_Earnings; set Comp_Earnings
(where=(missing(permno) or not missing(ibtic))) Noticker1;
 unlevered_mcap=mcap_final/(1-leverage);
 if unlevered_mcap<0 then unlevered_mcap=.;
 label ibtic='IBES Ticker';
 drop leverage ajexq dlttq xintq;
run;
   
/*Bring in closest available analyst consensus estimate */
/*for future EPS before earnings announcement           */
proc sql; create view Forecasts
 as select a.*, b.statpers, b.numest, b.medest, b.meanest, b.fpedats
 from Comp_Earnings a left join
  (select ticker, statpers, numest, medest, meanest, anndats_act, fpedats, fpi
   from Ibes.Statsum_EpsUS
   where fiscalp='ANN' and fpi='2' and statpers=min(statpers, anndats_act)) b
 on a.ibtic=b.ticker and a.datadate < b.statpers <=a.rdq_new
 group by gvkey,datadate
 having statpers=max(statpers) /*this would pick the consensus to closest to EAD*/
 order by gvkey, datadate;
quit;
   
/*Push the available consensus forecasts forward until either the next one is*/
/*available or 15 months have passed, whichever happens first                */
/*15 months is based on the average forward duration of issued forecasts     */
data Comp_Earnings_Ibes; set Forecasts;
 by gvkey datadate;
  retain statpers1 numest1 medest1 meanest1 fpedats1;
  if first.gvkey or not missing(statpers) then do;
  statpers1=statpers; numest1=numest; medest1=medest;
  meanest1=meanest; fpedats1=fpedats;end;
  statpers=statpers1; numest=numest1; medest=medest1;
  meanest=meanest1; fpedats=fpedats1;
  if intck('month',statpers, datadate)>15 then do;
  statpers=.;fpedats=.;medest=.;meanest=.;numest=.;end;
 drop statpers1 numest1 medest1 meanest1 fpedats1;
run;
   
/*Adjusting "P" and "E" Components of P/E Ratio for Inflation as in Shiller(2005) */
/*CRSP CPI data has more history compared to Compustat (the latter starts in 1981)*/
proc sql; create table Final
 as select a.*, b.cpiind/100 as cpi,
(a.&income/(b.cpiind/100)) as &income._infladj label='Inflation-Adjusted Earnings',
(a.mcap_final/(b.cpiind/100)) as mcap_infladj label='Inflation-Adjusted Market Value'
 from Comp_Earnings_Ibes a left join &Crsp..Mcti (keep=caldt cpiind) b
 on put(a.rdq_new, yymmn.)=put(b.caldt, yymmn.)
 order by a.gvkey, a.datadate;
quit;
 
/* Sanity check: should be no duplicates before proc expand is run*/
proc sort data=Final nodupkey; by gvkey datadate;run;
 
/*Calculate Trailing-Twelve Months Earnings                */
/*Nomiss ensures that 4 non-missing income numbers are used*/
proc printto log=junk;run;
proc expand data=Final out=Final method=none;
 by gvkey; id datadate;
 convert &income=&income._tt12m/
         transformout=(nomiss movsum 4 trimleft 3);
 convert unlevered_&income=unlevered_&income._tt12m/
         transformout=(nomiss movsum 4 trimleft 3);
 convert &income._infladj=&income._infladj_tt12m/
         transformout=(nomiss movsum 4 trimleft 3);
quit;
 
/* Sorting ensures that seasonal averaging is performed      */
proc sort data=Final; by gvkey fqtr datadate;run; 
 
/* Averaging "Trailing 12 months" earnings for Shiller's P/E */
proc expand data=Final out=Ready_For_Ratios;
by gvkey fqtr; id datadate;
convert &income._infladj_tt12m=&income.&py.y/
        transformout=(nomiss movave &py trimleft %eval(&py-1)) method=none;
quit;
proc printto;run;
 
proc sort data=Ready_For_Ratios; by gvkey datadate;run;
 
/*now calculating different types of P/E Ratios at the firm level:*/
/* 1) Shiller Long-Term P/E Ratios                                */
/* 2) P/E ratio,TTM                                               */
/* 3) Levered vs Unlevered PE                                     */
/* 4) Forward looking P/E, Analyst-Based                          */
data PEs/view=PEs; set Ready_For_Ratios;
 if missing(prccd_adj) then prc_adj=prccq_adj; else prc_adj=prccd_adj;
 pe&py.y=mcap_infladj/&income.&py.y;
 ey&py.y=&income.&py.y/mcap_infladj;
 pe_tt12m=mcap_final/&income._tt12m; 
 ey_tt12m=&income._tt12m/mcap_final;
 pe_unlevered=unlevered_mcap/unlevered_&income._tt12m;
 ey_unlevered=unlevered_&income._tt12m/unlevered_mcap;
 pe_forward=prc_adj/medest; 
 ey_forward=medest/prc_adj;
 label pe&py.y="Shiller's Long-Term P/E"
       ey&py.y="Shiller's Long-Term Earnings Yield"
       pe_tt12m='P/E, trailing 12 months'
       ey_tt12m='Earnings Yield, trailing 12 months'
       pe_unlevered='Unlevered P/E, trailing 12 months'
       ey_unlevered='Unlevered Earnings Yield, trailing 12 months'
       pe_forward='Forward P/E'
       ey_forward='Forward Earnings Yield';
 format pe&py.y best6. ey&py.y best12. pe_tt12m best6. ey_tt12m best12. rdq date9. 
        rdq_new date9. pe_unlevered best6. ey_unlevered best12. pe_forward best6. 
    ey_forward best12.;
 keep   gvkey datadate conm rdq rdq_new fyearq fqtr pe&py.y ey&py.y pe_tt12m 
        &income._tt12m ey_tt12m pe_unlevered ey_unlevered pe_forward ey_forward 
    mcap_infladj mcap_final unlevered_mcap permno unlevered_&income._tt12m 
    unlevered_mcap &income.&py.y &income._infladj_tt12m;
run;
   
/*Example: P/E ratios for S&P sector composite indexes*/
/*Constituents of S&P 500 sectors and S&P 500 index   */
proc sql;
 create table SP_Sectors
 (where=((index(conm,'500')>0 and index(conm,'1500')=0
 and index(conm,'.S')>0 and index(conm,'.SI')=0) or gvkeyx='000003'))
 as select distinct a.gvkeyx, a.gvkey, a.from format=date9., b.conm,
 coalesce(a.thru, .E) as thru format=date9.
 from &Comp..Idxcst_his a left join &Comp..Idx_Index b
 on a.gvkeyx=b.gvkeyx
 order by a.gvkeyx, a.from;
   
 create table PE_Ratios
 as select a.*, b.conm as index_name, b.gvkeyx,
 year(datadate)*100+qtr(datadate) as yearqq, qtr(datadate) as qtr
 from PEs a left join SP_Sectors b
 on a.gvkey=b.gvkey and
 (b.from<=a.datadate<=b.thru or (b.from<=a.datadate and b.thru=.E))
 order by yearqq, gvkeyx, gvkey;
quit;
   
/*Define percentiles for P/E ratios for handling outliers later*/
proc rank data=PE_Ratios out=PE_Ratios groups=100;
 by yearqq;
 var pe&py.y pe_tt12m pe_unlevered pe_forward
     ey&py.y ey_tt12m ey_unlevered ey_forward;
 ranks pe&py.y_rank pe_tt12m_rank pe_unlevered_rank pe_forward_rank
       ey&py.y_rank ey_tt12m_rank ey_unlevered_rank ey_forward_rank;
 run;
   
/*Extracting forecast for S&P 500 earnings*/
data EPS_SP500; set Ibes.StatSum_epsus;
 where ticker='SAP5'; *IBES ticker for S&P 500;
  if measure='EPS' and fiscalp='ANN' and fpi='1'
  and "&begindate"d<=statpers<="&enddate"d;
 keep ticker statpers medest meanest numest;
run;
   
/*Prepare for aggregation of firm-specific P/E's for different indexes*/
%let ratios=PE&py.y PE_tt12m PE_unlevered PE_forward;
%let eys=EY&py.y EY_tt12m EY_unlevered EY_forward;
%let numerator=&income._infladj_tt12m &income._tt12m unlevered_&income._tt12m;
%let denominator=mcap_infladj mcap_final unlevered_mcap;
   
/*Store S&P index gvkeys in a separate macro variable "indexes"*/
/*Store S&P index names in a separate macro variable "indnames"*/
proc sql noprint;
select distinct gvkeyx into: indexes separated by " " from pe_ratios ;
select distinct
compress(compress(substr(conm,index(conm,'500')+4, index(conm,'.')-
    index(conm,'500')-4), " "),"-") into: indnames separated by ' ' from sp_sectors;
quit;
   
/*Various methods of aggregating firm-level P/E Ratios to alleviate 1/X issue     */
/* 1) Median                                                                      */
/* 2) Omitting firms with negative P/E and taking the mean                        */
/* 3) Invert Aggregate Earnings yield (E/P)                                       */
/* 4) Divide aggregate market value by aggregate earnings                         */
proc printto log=junk;run;
%macro PE_Tables;
%do i=1 %to %nwords(&ratios);
 %let ratio=%scan(&ratios, &i, %str(' '));
 %let ey=%scan(&eys, &i, %str(' '));
 %let earn=%scan(&numerator, &i, %str(' '));
 %let value=%scan(&denominator, &i, %str(' '));
    
 proc sql; create table &Ratio
 as select distinct yearqq from pe_ratios order by yearqq;
 quit;
     
  %do j=1 %to %nwords(&indexes);
   %let index=%scan(&indexes,&j, %str(' '));
   %let indname=%scan(&indnames,&j, %str(' '));
   
 /*Method 1: Taking the median P/E for an index*/
 proc means data=PE_Ratios noprint;
  where gvkeyx="&index";
  by yearqq; var : id datadate;
  output out=&Ratio._Method1 median=&ratio._&indname.1;
 run;
    
 /*Remove firm-level outliers in P/E values*/
 data PE_Ratios1/view=PE_Ratios1; set PE_Ratios;
 if &ratio._rank in (98,99) then &ratio=.;
 if &ey._rank in (0,1) then &ey=.;
 run;
    
 /*Method 2: Ignore Non-Positive Earnings firms*/
 proc means data=PE_Ratios1 noprint;
  where gvkeyx="&index" and &ratio>0;
  by yearqq; var :
  output out=&Ratio._Method2 mean=&ratio._&indname.2;
 run;
    
 /* Method 3: aggregating earnings yield and then inverting*/
 proc means data=PE_Ratios1 noprint;
  by yearqq; where gvkeyx="&index";
  var &ey;
  output out=EY mean=/autoname;
 run;
    
 data &Ratio._Method3; set EY;
  by yearqq;
  &ratio._&indname.3=1/&ey._mean;
  format &ratio._&indname.3 best5.;
  keep  _freq_ _type_ &ratio._&indname.3 yearqq;
 run;
   
 /*Method 4: Work with sums, add up all P's and all E's before aggregate P/E ratio*/
 /*is calculated. Merge in forecasts of EPS for S&P 500 index from IBES           */
 %if &index=000003 and &ratio=PE_forward %then %do;
  %let sums="";
  proc sql; create table &Ratio._Method4
   as select c.*, count(*) as _freq_, 1 as _type_,
   d.&ratio._&indname.4 format=best5. label="Forward P/E Ratio for &indname"
   from &Ratio c left join
     (select b.statpers, a.prccm/b.medest as pe_forward_&indname.4
     from &Comp..Idx_mth (where=(gvkeyx='000003')) a
   right join EPS_SP500 b on put(a.datadate, yymmn.)=put(b.statpers, yymmn.)
   group by put(a.datadate, yyq.) having statpers=max(statpers)) d
   on c.yearqq=year(d.statpers)*100+qtr(d.statpers)
   order by yearqq;
  quit;%end;
 %else %do;
  
 %if &ratio ne PE_forward %then %do;
 proc means data=PE_Ratios noprint;
  where gvkeyx="&index"; id qtr;
  by yearqq;
  where nmiss(&earn, &value)=0;
  var &earn &value;
  output out=Sums sum=/autoname;
 run;
 %end;
   
 /*Long-term average of total annual inflation-adjusted earnings for S&P sector indexes*/
 %if &ratio=PE&py.y %then %do;
 %let sums=sums1;
 proc sort data=sums; by qtr yearqq;run;
 proc expand data=Sums out=&Sums;
 by qtr; id yearqq;
 convert &income._infladj_tt12m_sum=&income.&py.y_&indname/
         transformout=(movave &py trimleft %eval(&py-1)) method=none;
 run;quit;
 proc sort data=&Sums; by yearqq qtr;run;
 %end;%else %let sums=sums;
   
 %if &ratio ne PE_forward %then %do;
 proc sort data=&Sums; by yearqq;run;
   data &Ratio._Method4; set &Sums;
    &ratio._&indname.4=&value._sum/&earn._sum;
    format &ratio._&indname.4 best5.;
    keep &ratio._&indname.4  _type_ _freq_ yearqq;
  run;
 proc sql; drop table &sums;quit;
 %end;%end;
   
 data &Ratio._&Indname; merge &Ratio (in=a)
  &Ratio._Method1 (drop=_type_ rename=(_freq_=N))
  &Ratio._Method2 (drop=_freq_ _type_)
  &Ratio._Method3 (drop=_freq_ _type_)
  &Ratio._Method4;
  by yearqq; format datadate yyq.;
  keep yearqq N datadate &ratio._&indname.1
  &ratio._&indname.2 &ratio._&indname.3 &ratio._&indname.4;
  Label N="Number of non-missing security records for index &indname"
        &ratio._&indname.1="Median P/E for &indname"
        &ratio._&indname.2="Mean P/E for &indname, Positive-only P/E included"
        &ratio._&indname.3="Mean P/E for &indname, Inverted Earnings Yield"
        &ratio._&indname.4="Mean P/E for &indname, Aggregate Earnings/Aggregate Value";
 run;
 %end;
 proc sql; drop table &Ratio, &Ratio._Method1,&Ratio._Method2,
                      &Ratio._Method3,&Ratio._Method4, Sums;quit;
 %end;%mend;
%PE_Tables;
proc printto;run;
   
/*Plot some examples*/
/*Select the method: 1- for median; 2-for positive P/E only  */
/*                   3-for inverted E/P; 4- for Sums Approach*/
%let method1=2;%let method2=1;
%let vars1=pe&py.y_compltd&method1 pe_tt12m_compltd&method1
           pe_unlevered_compltd&method1 pe_forward_compltd&method1;
%let vars2=pe_tt12m_energy&method2
           pe_tt12m_financials&method2 pe_tt12m_informationtech&method2;
 
data Sample_Plot1; merge
 PE&py.y_compltd PE_tt12m_compltd PE_unlevered_compltd PE_forward_compltd;
 by yearqq; where datadate>='01jan1976'd;
 keep datadate &vars1;
 label pe&py.y_compltd&method1="Shillers Long-Term P/E"
       pe_tt12m_compltd&method1="P/E, Trailing 12 months"
       pe_unlevered_compltd&method1="Unlevered P/E, Trailing 12 months"
       pe_forward_compltd&method1="Forward P/E";
run;
   
/*Example 2: Median P/E for some industry sectors*/
data Sample_Plot2; merge
 PE_tt12m_energy PE_tt12m_financials PE_tt12m_informationtech;
 by yearqq;where datadate>='01jan1976'd;
 keep datadate &vars2;
run;  
 
options nodate orientation=landscape; 
ods pdf file="SP500_method&method1..pdf";
goptions device=pdfc; /* Plot Saved in Home Directory */
axis1 label=(angle=90 "Value of P/E");
axis2 label=("Year-Quarter");
symbol interpol=join w=4 l=1;
proc gplot data =Sample_Plot1;
 Title 'Various types of P/E Ratio for S&P 500 ("P/E>0" method)';
 plot (&vars1)*datadate /overlay legend vaxis=axis1 haxis=axis2;;
run;quit; 
ods pdf close;
ods pdf file="SP500sectors_method&method2..pdf";
proc gplot data =Sample_Plot2;
 Title 'Mean P/E Ratio for sample S&P sectors';
 plot (&vars2)*datadate /overlay legend vaxis=axis1 haxis=axis2;;
run;quit;
ods pdf close;
 
/*House Cleaning*/
proc sql; 
 drop view close_trade_date,comp_earnings1,eads,forecasts,pes,pe_ratios1;
 drop table comp_earnings,comp_earnings_ibes,dups,eps_sp500,ey,final, 
            sample_plot1, sample_plot2, sp_sectors, ready_for_ratios;
quit;
 
/* ********************************************************************************* */
/* *************  Material Copyright Wharton Research Data Services  *************** */
/* ****************************** All Rights Reserved ****************************** */
/* ********************************************************************************* */
