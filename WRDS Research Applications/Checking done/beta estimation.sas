/* Checking done. (2017.Jun.09)*/
/* Not so easy to extend it for multiple betas; will have to run regressions many times to get betas. */
/* To be specific, cannot define "X", being a matrix of multiple variables, properly in SAS, which is needed */
/* to calculate BETA = (X'X)^-1X'Y */

/* ********************************************************************************* */
/* ************** W R D S   R E S E A R C H   A P P L I C A T I O N S ************** */
/* ********************************************************************************* */
/* Summary   : Compute Market-Model Betas                                            */
/* Date      : January, 2011                                                         */
/* Author    : Rabih Moussawi                                                        */
/* Notes     : - Reads CRSP Daily or Monthly Return Datasets to compute Betas        */
/*             - Use Proc Expand Capabilities to compute covariances and variations  */
/*             - Saves output in BETA dataset                                        */
/*             - Can be modified to compute loadings for Fama&French 4 Factor Model  */
/* ********************************************************************************* */
 
libname crsp ("/wrds/crsp/sasdata/sm" "/wrds/crsp/sasdata/sd");
libname ff "/wrds/ff/sasdata";
 
%let S=m;              /* Monthly/Daily; use S=d for CRSP Daily data */
%let START=01JAN1990;  /* Sample Start Date */
%let END  =30JUN2001;  /* Sample End Date */
%let WINDOW=36;            /* Window of Estimation */
%let MINWIN=12;        /* Minimum Window of Estimation for non-missing betas */
%let INDEX=VWRETD;     /* Market Return Variable, with default Value-Weighted (VWRETD) */
 
/* Example for Daily Beta Computation */
/* %let S=d; %let WINDOW=250; %let MINWIN=60; */
 
/* START. Computing Betas from &sf Using &WINDOW Estimation Window */
*%let sf       = crsp.&s.sf ; /* CRSP Stock Dataset: Daily vs. Monthly */
*%let si       = crsp.&s.si ; /* CRSP Index Dataset: Daily vs. Monthly */
%let sf       = mysas.&s.sf ; /* CRSP Stock Dataset: Daily vs. Monthly */
%let si       = mysas.&s.sia ; /* CRSP Index Dataset: Daily vs. Monthly */

 
/* Read CRSP Stock Dataset */
/*VIEW is faster than w/o it. However, if double-click the table,*/
/*only the portion of the whole table shows up. To see the rest of it,*/
/*one has to drag it down to the bottom repeatedly.*/
data _crsp1 /view=_crsp1;
set &sf. ;
where "&START."D<=date<="&END."D;
keep permno date ret;
run;
 
/* Add Index Return Data */
/*used "create view" instead of "create table" in order to boost up*/
/*the computation speed*/
proc sql;
create view _crsp2
as select a.*, b.&index,
  b.&index*(abs(a.ret)>=0) as X, a.ret*b.&index as XY,
  (abs(a.ret*b.&index)>=0) as count
from _crsp1 as a, &si. as b
where a.date=b.date
order by a.permno, a.date;
quit;
 
/* Compute Components for Covariances and Variances for Market Model Regression */
proc printto log = junk; run;
/*under proc expand, too many WARNINGS will show up if*/
/*log is not printed to "junk"*/
proc expand data=_crsp2 out=_crsp3 method=none;
by permno;
id date;
convert X=X2      / transformout= (MOVUSS &WINDOW.);
convert X=X       / transformout= (MOVSUM &WINDOW.);
convert XY=XY     / transformout= (MOVSUM &WINDOW.);
convert ret=Y     / transformout= (MOVSUM &WINDOW.);
convert ret=Y2    / transformout= (MOVUSS &WINDOW.);
convert ret=tvol  / transformout= (MOVSTD &WINDOW.);
convert count=n   / transformout= (MOVSUM &WINDOW.);
quit;
run;
proc printto; run;
 
/* Calculate Betas, R-Squared, and Idiosyncratic Volatility */
data BETA;
set _crsp3;
if n>=&MINWIN. and (Y2-(Y**2)/n)>0 then
 do;
   beta     = (XY-X*Y/n) / (X2-(X**2)/n);
   alpha    =  Y/n- beta*X/n;
   R2       = (XY-X*Y/n)**2 / ( (X2-(X**2)/n) * (Y2-(Y**2)/n) );
   Sigma    = sqrt( ((Y2-(Y**2)/n) - beta*(XY-X*Y/n)) / (n-2) );
   Beta_std = sigma/sqrt(X2-(X**2)/n);
end;
label alpha = "Stock Alpha";
label beta = "Stock Beta";
label R2 = "Market Model R-Squared";
label Tvol = "Total Stock Volatility";
label Sigma = "Idiosyncratic Volatility";
label beta_std = "Beta Standard Deviation";
label n = "Number of Observations used to compute Beta";
drop X X2 XY Y Y2 COUNT;
format n beta beta_std comma8.2 Tvol ret alpha R2 Sigma &index percentn8.2;
run;
 
/* House Cleaning */
proc sql;
drop view _crsp1;
drop table _crsp2, _crsp3;
quit;
 
/* ********************************************************************************* */
/* *************  Material Copyright Wharton Research Data Services  *************** */
/* ****************************** All Rights Reserved ****************************** */
/* ********************************************************************************* */
