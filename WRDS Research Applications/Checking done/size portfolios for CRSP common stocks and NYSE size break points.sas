/*Checing done! (2017.06.29)*/
/*SIZE calculated similarly in "FF factors replication.sas", but for terciles only. */

/* ********************************************************************************* */
/* ************** W R D S   R E S E A R C H   A P P L I C A T I O N S ************** */
/* ********************************************************************************* */
/* Summary   : Size Portfolios for CRSP common stocks and                            */
/*             NYSE Size Break Points                                                */
/* Date      : October 2004 Revised March 2011                                       */
/* Author    : Michael Boldin and Luis Palacios, WRDS                                */
/* Note      : Use PC-SAS to take advantage of graphic capabilities                  */ 
/* ********************************************************************************* */


/*%let wrds = wrds.wharton.upenn.edu 4016;*/
/*options comamid=TCP remote=wrds;*/
/*signon username=_prompt_;*/
/**/
/*rsubmit; */

/* 1. Prepare the Data */


/* Creates a dataset (named crsp_m) produced from merrging the crsp event file (crsp.mse) and the 
crsp data file (crsp.msf) using a WRDS Macro. It contains common stock only and assigns the historic 
exchange code to each stock. */

/* To automatically point to the macros in this library within your SAS program */
/*options sasautos=('/wrds/wrdsmacros/', SASAUTOS) MAUTOSOURCE;*/
options sasautos=('D:\Dropbox\GitHub\CRSP_local\myMacro\', SASAUTOS) MAUTOSOURCE;

/* Merge historical codes with CRSP Monthly Stock File       */
%let begdate=01JAN2000;  
%let enddate=31DEC2009; 
/* Restriction on Share Code: common shares only (shrcd = 10 or 11)  */
%let filtr = ( shrcd in (10,11) ); 
/*  Selected variables from the CRSP Monthly Stock File      */
%let fvars =  prc ret shrout ; 
/*  Selected variables from the CRSP Monthly Event File      */
%let evars =  shrcd exchcd dlret; 

/* Invoke CRSPMERGE WRDS Research Macro. Data Output: CRSP_M */

%crspmerge(s=m,start=&begdate,end=&enddate,sfvars=&fvars,sevars=&evars,filters=&filtr); 


/* 2. Create weigths, adjust for delisting returns 
and calculate End-of-Quarter Size-Breakpoints from NYSE listed firms */
/*NYSE: exchcd=1*/
data msex2;
  set CRSP_M;
  by permno date;
  /* Create size variable */
  size=abs(prc)*shrout; 
/* Absolute Value of Price since, by convention
CRSP assigns a negative value when the Bid-Ask average is used */
/* Lag Size for weights*/
size_lag=lag(size);
if first.permno then size_lag = size / sum(1,ret);
/* Adding Delisting Returns */
r1 = sum(1,ret);
r2 = sum(1,dlret);
ret = r1*r2-1;
drop prc shrout r1 r2 dlret;
run;

/* Keeps only NYSE securities at the end of quarter 
and Calculates NYSE Size-Breakpoints */

proc sort data=msex2(keep=date size exchcd) out=msex3;
  where month(date) in (3,6,9,12) and exchcd=1;
  by date;
run;

proc univariate data=msex3 noprint;
  var size;
  by date;
  output out=nyse pctlpts = 10 to 90 by 10 pctlpre=dec;
run;

/*proc print data=nyse;*/
/*  title 'NYSE Size-Breakpoints';*/
/*  run; */


  /* 3. Create Portfolios of securities at the end of each Quarter */
/* Merge Breakpoints with datasets that contains all securities 
at portfolio formation date: end of the each quarter */
proc sql;
  create table x1
  as select a.permno, a.size, b.*
  from msex2(keep=permno date size where = ( month(date) in (3,6,9,12)) ) as a
  left join nyse as b
  on a.date= b.date;
quit;

/* Create Deciles ('group') variable comparing Size
with NYSE break points */;
data x2;
  set x1;
  if size <= 0                           then group =.;
  else if size >  0     and size < dec10 then group =1;
  else if size >= dec10 and size < dec20 then group =2;
  else if size >= dec20 and size < dec30 then group =3;
  else if size >= dec30 and size < dec40 then group =4;
  else if size >= dec40 and size < dec50 then group =5;
  else if size >= dec50 and size < dec60 then group =6;
  else if size >= dec60 and size < dec70 then group =7;
  else if size >= dec70 and size < dec80 then group =8;
  else if size >= dec80 and size < dec90 then group =9;
  else if size >= dec90                  then group =10;
  label group = 'DECILE';
  if group=. then delete;
  drop size dec: ;
run;

/* Each Security has a Decile. Quarterly Rebalanced */;
/*proc print data=x2;*/
/*  title 'Each security has a decile. The portfolio is rebalanced quarterly. Example for IBM at the end of the quarter';*/
/*  where permno = 12490;*/
/*run;*/

/*For ilustration purpose: Number of Securities per Portfolio*/
proc freq data=x2;
  where year(date)=2004;
  title 'Number of Securities when Portfolios were created: 2004';
  tables group*date / missing nocol norow nopercent;
  run; 


  /* 4. Assign Size Group to Entire Sample every quarter */
/* Create subset that includes all securities on size portfolios by quarter 
Portfolio is created at the end of each quarter and keep it for 3-months */

proc sql;
  create table msfx1
  as select a.*, b.group
  from msex2 as a, x2 as b
  where a.permno=b.permno and intck('qtr',b.date,a.date)= 1;
  quit; 


  /* 5. Calculate Weighted Average Returns */
  proc sort data=msfx1 out=msfx2;
    where size_lag >0;
    by group date;
  run;

  /*Calculates Value-Weighted Returns*/
  proc means data = msfx2 noprint;
    by group date;
    var ret / weight=size_lag ;
    output out = vwretdat mean= vwret; run;
  run;

  proc sort data=vwretdat; by group date ; run;

    /* title "Final Results" */
/*    proc print data=vwretdat;*/
/*      title "Monthly Returns by NYSE Size Deciles";*/
/*      var date group vwret;*/
/*      run; */



/*6. Compare Results with the CRSP portfolio returns. 
CRSP portfolio is rebalanced quarterly (file MSHISTQ) */

proc sql;
  create table x3
  as select a.*, b.totret as crsp_return label 'CRSP Return' 
  from vwretdat as a
/*  left join crsp.mhistq*/
  left join a_index.mhistq
  (keep=caldt prtnam totret where=(prtnam in ('1','2','3','4','5','6','7','8','9','10') ) )
  as b
  on a.date=b.caldt and a.group=11-input(b.prtnam,2.) 
  order by group, date;
quit;


/* CRSP's Portfolio Data */;
/*proc print data=x3(obs=30);*/
/*  title "Example of CRSP's Portfolio data";*/
/*run;*/

*Plots,;

/*symbol1 interpol=join ci=green w=3 co=green;*/
/*symbol2 interpol=join ci=blue co=blue value=star;*/
/*symbol3 interpol=join ci=red co=red;*/
/*symbol4 interpol=join ci=black co=black;*/
/*symbol5 interpol=join ci=brown co=brown;*/
/**/
/*proc gplot data=x3;*/
/*  title "Comparison with CRSP Portfolio returns";*/
/*  by group;*/
/*  plot crsp_return*date=1 vwret*date=2 / overlay legend;*/
/*run;*/

/*endrsubmit; */


/* ********************************************************************************* */
/* *************  Material Copyright Wharton Research Data Services  *************** */
/* ****************************** All Rights Reserved ****************************** */
/* ********************************************************************************* */






