/*This is a rolling regression*/

/*Faster than "RRLOOP.sas", but INADEQUATE for multiple betas.*/
/*THIS IS HARD-CODED (in some sense), SO BE CAUTIOUS WHEN USING.*/

/*Applicable only for simple linear regression*/
/*Applicable ONLY when the VWRETD is the only independent variable*/
/*Calculation of BETA doesn't apply anymore if there's other indep. variables*/

/*If further adjusted to compute loadings for FF4F, then namings of variables should change*/
/*e.g. "beta" is no longer just market beta, but vector of all dependent variables' sensitivities*/
/*w.r.t. perturbation in X, independent variables*/

/* ********************************************************************************* */
/* ******************** W R D S   R E S E A R C H   M A C R O S ******************** */
/* ********************************************************************************* */
/* Summary   : Compute Market-Model Betas                                            */
/* Date      : January, 2011                                                         */
/* Author    : Rabih Moussawi                                                        */
/* Variables : - S: Monthly/Daily, defaults to Monthly, but s=d for CRSP Daily data  */
/*             - BEGDATE: Sample Start Date                                          */
/*             - ENDDATE: Sample End Date                                            */
/*             - WINDOW: Window of Estimation                                        */
/*             - MINWIN: Minimum Window of Estimation for non-missing betas          */
/*             - INDEX: Market Return Variable, with default Value-Weighted (VWRETD) */
/*             - OUTSET: Output Dataset Name (default names crsp_m or crsp_d)        */
/* Notes     : - Reads CRSP Daily or Monthly Return Datasets to compute Betas        */
/*             - Use Proc Expand Capabilities to compute covariances and variations  */
/*             - Saves output in BETA dataset                                        */
/*             - Can be modified to compute loadings for Fama&French 4 Factor Model  */
/* ********************************************************************************* */
?
%MACRO BETA (s=m,START=01JAN2000,END=30JUN2001,WINDOW=36,MINWIN=12,INDEX=VWRETD,OUTSET=beta_&s.);
 
/* Check Series: Daily or Monthly and define datasets - Default is Monthly  */
%if &s=D %then %let s=d; %else %if &s ne d %then %let s=m;

/*%if (%sysfunc(libref(crsp))) %then %do;*/
/*  %let cs=/wrds/crsp/sasdata/;*/
/*  libname crsp ("&cs/m_stock","&cs/q_stock","&cs/a_stock");*/
/*%end;*/
/*%let sf = crsp.&s.sf ;*/
/*%let si = crsp.&s.si ;*/

%let sf = mysas.&s.sf ;
%let si = mysas.&s.sia ;
 
options nonotes;
%put #### START. Computing Betas from &sf Using &WINDOW Estimation Window ;
data _crsp1 /view=_crsp1;
set &sf. ;
where "&START."D<=date<="&END."D;
keep permno date ret;
run;

/*Note that vwretd is (likely to be) never null (considering the code below)*/
/*X: vwretd if a.ret is not null (if a.ret is not null, then abs(a.ret)>=0 must hold)*/
/*XY: null if a.ret is null*/
/*count: 0 if a.ret is null, 1 if a.ret is not null*/
proc sql;
create table _crsp2
as select a.*, b.&index,
	b.&index*(abs(a.ret)>=0) as X, a.ret*b.&index as XY,
  	(abs(a.ret*b.&index)>=0) as count
from _crsp1 as a left join &si. as b
on a.date=b.date
order by a.permno, a.date;
quit;
 
proc printto log = junk; run;
proc expand data=_crsp2 out=_crsp3 method=none;
by permno;
id date;
/*conver OLDVAR = NEWVAR, coming with operation with "transformout=" */
/*MOVSUM: Backward moving sum, MOVUSS: Backward moving uncorrelated sum of squares*/
/*MOVSTD: Backward moving weighted standard deviation*/
/*Other families:  MOVAVE, MOVGMEAN, MOVMAX, MOVMED, MOVMIN, MOVPROD,*/
/*MOVRANGE, MOVRANK, TRIM, TRIMLEFT, TRIMRIGHT*/
convert X=X2      / transformout= (MOVUSS &WINDOW.);
/*X is no more vwretd, but overwritten to be MovingSum(X=vwretd, &WINDOW.)*/
convert X=X       / transformout= (MOVSUM &WINDOW.);
/*XY is no more vwretd*msf.ret, but overwritten to be MovingSum(XY=vwretd*msf.ret, &WINDOW.)*/
convert XY=XY     / transformout= (MOVSUM &WINDOW.);
convert ret=Y     / transformout= (MOVSUM &WINDOW.);
convert ret=Y2    / transformout= (MOVUSS &WINDOW.);
convert ret=tvol  / transformout= (MOVSTD &WINDOW.);
/*n: moving sum of count, which is an indicator variable of non-null msf.ret data*/
convert count=n   / transformout= (MOVSUM &WINDOW.);
quit;
run;
proc printto; run;
 
data &outset;
set _crsp3;
if n>=&MINWIN. and (Y2-(Y**2)/n)>0 then
do;
	beta=(XY-X*Y/n) / (X2-(X**2)/n);
	alpha = Y/n - beta*X/n;
	R2 = (XY-X*Y/n)**2 / ( (X2-(X**2)/n) * (Y2-(Y**2)/n) ); /*simple regression's R-sq, which is a square of correlation*/
	Sigma = sqrt( ( (Y2-(Y**2)/n) - beta*(XY-X*Y/n) ) / (n-2) ) ;
	Beta_std = sigma/sqrt(X2-(X**2)/n) ;
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
 
options notes;
%put #### DONE . Dataset &outset. Created! ;    %put ;
 
%MEND BETA;
 
/* ********************************************************************************* */
/* *************  Material Copyright Wharton Research Data Services  *************** */
/* ****************************** All Rights Reserved ****************************** */
/* ********************************************************************************* */
