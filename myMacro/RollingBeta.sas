%macro RollingBeta(S=, begdate=, enddate=, window=, minwin=, index=);

libname a_index "D:\Dropbox\WRDS\CRSP\sasdata\a_indexes";
libname a_stock "D:\Dropbox\WRDS\CRSP\sasdata\a_stock";
libname ff "D:\Dropbox\WRDS\ff\sasdata";
libname mysas "D:\Dropbox\WRDS\CRSP\mysas";
libname myMacro "D:\Dropbox\SAS_scripts\myMacro";
 
%let S=&S;              /* Monthly/Daily; use S=m(S=d) for CRSP Monthly(Daily) data */
%let START= &begdate;  /* Sample Start Date */
%let END  = &enddate;  /* Sample End Date */
%let WINDOW = &WINDOW;            /* Window of Estimation. ex) 36 for S=m, 250 for S=d */
%let MINWIN = &MINWIN;        /* Minimum Window of Estimation for non-missing betas. ex) 12 for S=m, 60 for S=d */
%let INDEX = &index;     /* Market Return Variable, with default Value-Weighted (VWRETD) */
 
/* START. Computing Betas from &sf Using &WINDOW Estimation Window */
%let sf       = mysas.&S.sf; /* CRSP Stock Dataset: Daily vs. Monthly */
%let si       = mysas.&S.sia ; /* CRSP Index Dataset: Daily vs. Monthly */
 
/* Read CRSP Stock Dataset */
data _crsp1 /view=_crsp1;
set &sf. ;
where "&START."D<=date<="&END."D;
keep permno date ret;
run;
 
/* Add Index Return Data */
proc sql;
create table _crsp2
as select a.*, b.&index,
  b.&index*(abs(a.ret)>=0) as X, a.ret*b.&index as XY,
  (abs(a.ret*b.&index)>=0) as count
from _crsp1 as a, &si. as b
where a.date=b.date
order by a.permno, a.date;
quit;
 
/* Compute Components for Covariances and Variances for Market Model Regression */
proc printto log = junk; run;
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

%mend RollingBeta;
