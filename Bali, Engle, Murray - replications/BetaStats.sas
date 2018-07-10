/* Checking done! (2017.07.06) */
/*FactorLoadingStatsDaily -> BetaStats.*/


/* Instead of using rrloop over all observations and selectively appending might be slower than */
/* generating some indicator variables first and selectively doing rolling regression based on that */
/* variables. However, couldn't find the way for the latter yet. (2017.07.06) */

/* Generate datasets through <FactorLoadingStatsDaily.sas>. */

%let begdate = '03JAN1963'd;
%let enddate = '31DEC2012'd;
%let vars = ticker comnam prc vol ret shrout shrflg;
%let mkt_index = vwretd;
%let begyear = year(&begdate);
%let endyear = year(&enddate);
/*WINDOW, MINWIN needed for rolling regression, which is NOT run here.*/
/*When using Rolling regression, missing data shouldn't be discarded. */
%let WINDOW = 252; /*Rolling regression needs a window "cap", as it runs overlapping regressions daily*/
%let MINWIN = 200;

/*-----------------------------------------*/
%include mymacro('rrloop.sas');
%rrloop(data=bem.dsf_smaller, out_ds=bem.beta1m, model_equation=exret=mktrf, id=permno, date=date,
start_date=&begdate, end_date=&enddate, freq=month, step=1, n=1, regprint=noprint, minwin=15);

%rrloop(data=bem.dsf_smaller, out_ds=bem.beta3m, model_equation=exret=mktrf, id=permno, date=date,
start_date=&begdate, end_date=&enddate, freq=month, step=3, n=3, regprint=noprint, minwin=50);

%rrloop(data=bem.dsf_smaller, out_ds=bem.beta6m, model_equation=exret=mktrf, id=permno, date=date,
start_date=&begdate, end_date=&enddate, freq=month, step=6, n=6, regprint=noprint, minwin=100);

%rrloop(data=bem.dsf_smaller, out_ds=bem.beta12m, model_equation=exret=mktrf, id=permno, date=date,
start_date=&begdate, end_date=&enddate, freq=month, step=12, n=12, regprint=noprint, minwin=200);

%rrloop(data=bem.dsf_smaller, out_ds=bem.beta24m, model_equation=exret=mktrf, id=permno, date=date,
start_date=&begdate, end_date=&enddate, freq=month, step=24, n=24, regprint=noprint, minwin=450);

/*-----------------------------------------*/
/* Generating "year month day". See <SummRegResult_custom> for this. */
data bem.beta1m; set bem.beta1m; year=year(date2); month=month(date2); day=day(date2); run;
data bem.beta3m; set bem.beta3m; year=year(date2); month=month(date2); day=day(date2); run;
data bem.beta6m; set bem.beta6m; year=year(date2); month=month(date2); day=day(date2); run;
data bem.beta12m; set bem.beta12m; year=year(date2); month=month(date2); day=day(date2); run;
data bem.beta24m; set bem.beta24m; year=year(date2); month=month(date2); day=day(date2); run;

/*-----------------------------------------*/
/* Not sorting just w.r.t. date2, but "year month day". See <SummRegResult_custom> for this. */
proc sort data=bem.beta1m; by year month day permno; run;
proc sort data=bem.beta3m; by year month day permno; run;
proc sort data=bem.beta6m; by year month day permno; run;
proc sort data=bem.beta12m; by year month day permno; run;
proc sort data=bem.beta24m; by year month day permno; run;

/*-----------------------------------------*/
%include myMacro('SummRegResult_custom.sas');
/*%SummRegResult_custom(data=BEM.beta1m, out=BEM.beta1mPrdcStat, var=intercept mktrf, by=year month);*/
%SummRegResult_custom(data=BEM.beta1m, out=BEM.beta1mPrdcStat, var=intercept mktrf, by=year);
%SummRegResult_custom(data=BEM.beta3m, out=BEM.beta3mPrdcStat, var=intercept mktrf, by=year);
%SummRegResult_custom(data=BEM.beta6m, out=BEM.beta6mPrdcStat, var=intercept mktrf, by=year);
%SummRegResult_custom(data=BEM.beta12m, out=BEM.beta12mPrdcStat, var=intercept mktrf, by=year);
%SummRegResult_custom(data=BEM.beta24m, out=BEM.beta24mPrdcStat, var=intercept mktrf, by=year);
/*-----------------------------------------*/

%include myMacro('Trans.sas');
%Trans(data=BEM.beta1mPrdcStat, out=BEM.beta1mPrdcStat, var=intercept mktrf, id=_STAT_, by=year );
%Trans(data=BEM.beta3mPrdcStat, out=BEM.beta3mPrdcStat, var=intercept mktrf, id=_STAT_, by=year );
%Trans(data=BEM.beta6mPrdcStat, out=BEM.beta6mPrdcStat, var=intercept mktrf, id=_STAT_, by=year );
%Trans(data=BEM.beta12mPrdcStat, out=BEM.beta12mPrdcStat, var=intercept mktrf, id=_STAT_, by=year );
%Trans(data=BEM.beta24mPrdcStat, out=BEM.beta24mPrdcStat, var=intercept mktrf, id=_STAT_, by=year );

/*-----------------------------------------*/
%include myMacro('ObsAvg.sas');
%ObsAvg(data=BEM.beta1mprdcstat, out=BEM.beta1mAvgStat, by=year coeff, drop=_TYPE_ _FREQ_);
%ObsAvg(data=BEM.beta3mprdcstat, out=BEM.beta3mAvgStat, by=year coeff, drop=_TYPE_ _FREQ_);
%ObsAvg(data=BEM.beta6mprdcstat, out=BEM.beta6mAvgStat, by=year coeff, drop=_TYPE_ _FREQ_);
%ObsAvg(data=BEM.beta12mprdcstat, out=BEM.beta12mAvgStat, by=year coeff, drop=_TYPE_ _FREQ_);
%ObsAvg(data=BEM.beta24mprdcstat, out=BEM.beta24mAvgStat, by=year coeff, drop=_TYPE_ _FREQ_);


%let month_list = 1M 3M 6M 12M 24M;
%macro loop(varlist);
%let nVar = %sysfunc(countw(&varlist));
%do i=1 %to &nVar.;
%let currVar = %scan(&varlist, &i);

proc means data=BEM.beta&currVar.AvgStat(where=(~(coeff="Intercept")) drop=year) noprint nway;
output out=beta&currVar._tmp mean()=;
run;

data beta&currVar._result(drop=_TYPE_ _FREQ_);
retain group mean StdDev skew kurt min p5 p25 median p75 p95 max n;
set beta&currVar._tmp;
group = "beta_&currVar.";
run;

proc sql;
drop table beta&currVar._tmp;
quit;

%end;
%mend loop;
%loop(&month_list);

data beta_mrgd;
length group $ 8;
set beta1M_result beta3M_result beta6M_result beta12M_result beta24M_result;
run;
