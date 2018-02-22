/* USE "Size Portfolios for CRSP common stocks and NYSE Size Break Points.sas" instead. */

/*Usually SIZE breakpoints use NYSE stocks only, so this file, using all CRSP stocks, */
/* is less usable and practical. */

/* ********************************************************************************* */
/* ************** W R D S   R E S E A R C H   A P P L I C A T I O N S ************** */
/* ********************************************************************************* */
/* Summary   : Size Portfolios for all CRSP Securities                               */
/* Date      : October 2004 Revised March 2011 and August 2011                       */
/* Author    : Michael Boldin and Luis Palacios, WRDS                                */
/*           : August 2011: M Keintz                                                 */
/* Note      : Use PC-SAS to take advantage of graphic capabilities                  */ 
/* ********************************************************************************* */


/* Set paramaters:                                                                   */
/*    BEGDATE   First date of desired date, in unquoted ddmonyyyy format             */

%let begdate=01DEC2006;

/* 1. Extract data for creating deciles                                              */
/*   MSFX1:     Monthly file with SIZE and SIZEFLAG                                  */
/*   MSFX_DEC:  December record for dividing into deciles                            */

data msfx1    (keep=date permno size year_prev ret size_lag)
     msfx_dec (keep=permno size year) ;
  set crsp.msf; 
  where date >= "&begdate"d; 
  where also nmiss(prc,shrout,ret)=0;  ** Keep only "complete" cases **;

  by permno ;

/* Calculate Size.  If no trades in last trading day of month, then CRSP records PRC */
/* as the negative of bid-ask average.  Therefore abs(prc) must be used.             */
  size = abs(prc)*shrout; 
  
/* Get Size Lag for weighting.  For first rec of any PERMNO, estimate size_lag       */  
  size_lag=lag(size); 
  if first.permno then size_lag=size/(1+ret);

/* Calculate YEAR (for the December file) and YEAR_PREC (for the 12-month file).     */
/* These support matching all monthly records with size groups from prior December   */
  year=year(date);
  year_prev=year-1;

  output msfx1;  
  if month(date)=12 then output msfx_dec;
run;

/*  2. Compute Deciles for each year                                            */
/*     Sort December records by year so each year can be given its own deciles. */
/*     Use PROC RANK to create 10 groups (0 through 9) by size for each year.   */
/*     Recode Groups 0 through 9 to 1 through 10, for presentation purposes.    */
proc sort data=MSFX_DEC; 
  by year; 
run;  
proc rank data=MSFX_DEC out=groups group=10; 
  by year; 
  var size; 
  ranks group; 
  label group='Size Decile';
run;  
data groups; 
  set groups; 
  group=group+1;  
run;  
  
  
/*  3. Assign Size Group to Entire Sample of monthly records                */
/*     Match YEAR_PREV for each monthly record with YEAR in the group data  */
  
proc sql; 
  create table msfx2 
  as select a.*, b.group
  from msfx1 as a    left join    groups as b 
    on  (a.permno=b.permno and a.year_prev=b.year )
  where group^=. ;
quit;  

  
/* 4. Compute Size Weighted Average Returns for each GROUP/DATE            */
  
proc sort data=msfx2; 
  by group date; 
run; 

proc means data = msfx2 noprint; 
  by group date; 
  var ret / weight=size_lag ; 
  output out = vwretdat mean= vwret ; 
run;  
  
/* 5.  Join with the CRSP MSIX Size Decile Returns, for later comparisons    */
/*     MSIX contains CRSP-provide average monthly returns for portfolio by   */
/*          size (rebalanced every December).  Take the 10 decile returns    */

data msix1 (keep=caldt group decret) ;
  set crsp.msix;
  where caldt >= "&begdate"d; 
  array dret decret1-decret10;
  do group=1 to 10;
    decret=dret{group};
    output;
  end;
run;

proc sql; 
  create table x3 
  as select a.*, b.decret 
  from vwretdat as a  left join   msix1 as b 
  on a.date=b.caldt and a.group=b.group
  order by group, date;
quit;


/* 6. Graph the calculated decile returns with CRSP-supplied decile returns */
/*      Includes setting up ODS (Output Delivery System).  The graph output */
/*      below will be put into a PDF file (ps_graph.pdf)                    */

options orientation=landscape;                ** For the GPLOT output below **;
options nodate nonumber;            ** Do not print the date or page number **;
options device=pdfc;     ** Use "pdf color" as "Device" for graphics output **;

ods pdf file='./ps_graph.pdf';  ** Activate PDF output, specify destination **;

ods listing close; ** Turn off sasgraph.pdf, now superseded by ps_graph.pdf **;


/* 6. Plot calculated decile returns against CRSP-provided returns          */
  
symbol1 interpol=join ci=green co=green  w=3; 
symbol2 interpol=join ci=blue  co=blue   value=star; 
symbol3 interpol=join ci=red   co=red; 
symbol4 interpol=join ci=black co=black; 
symbol5 interpol=join ci=brown co=brown; 
  
proc gplot data=x3; 
  Title 'Compare Results with CRSP Portfolio Returns'; 
  by group; 
  plot decret*date=1 vwret*date=2 / overlay legend; 
run; 
  
ods listing;          ** Turn listing output back on **;
ods pdf close;        ** Turn off pdf output **;

  
/* ********************************************************************************* */
/* *************  Material Copyright Wharton Research Data Services  *************** */
/* ****************************** All Rights Reserved ****************************** */
/* ********************************************************************************* */
