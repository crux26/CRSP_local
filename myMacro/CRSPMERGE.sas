/* Reason of merging with mseall, msenames: when one needs SEVARS, such as TICKER, NCUSIP, EXCHCD, SHRCD, SICCD, ... */
/* Note that EXCHCD is also AVAILABLE in msf, in the name of HEXCD. */
/* HEXCD in (1,2,3,4): NYSE, NYSE MKT(AMEX), NASDAQ, Arca, respectively. */

/*Merges a_stock.msf, a_stock.mseall, a_stock.msenames */
/*Basically not so differnt from msf - variables relevant to asset pricing is mostly from msf*/
/*Variables from msf: &SFVARS - PRC RET SHROUT */
/*Variables from mseall: &SEVARS - NCUSIP, TICKER, EXCHCD, SHRCD, SICCD */

/* ********************************************************************************* */
/* ******************** W R D S   R E S E A R C H   M A C R O S ******************** */
/* ********************************************************************************* */
/* WRDS Macro: CRSPMERGE                                                             */
/* Summary   : Merges CRSP Stocks and Events Data                                    */
/* Date      : April 14, 2009                                                        */
/* Author    : Rabih Moussawi and Luis Palacios, WRDS                                */
/* Variables : - S: Monthly/Daily, defaults to Monthly, but s=d for CRSP Daily data  */
/*             - START, END: Start and End Dates. Example Date Format: 01JAN2000     */
/*             - SFVARS: Stock File Vars to extract. e.g. PRC VOL SHROUT             */
/*             - SEVARS: Event File Vars to extract. e.g. TICKER NCUSIP SHRCD EXCHCD */
/*                  warning: including DIVAMT may result in multiple obs per period  */
/*             - FILTERS: Additional screens using variables in SFVARS or SEVARS     */
/*                          (default: no filters)                                      */
/*             - OUTSET: Output Dataset Name (default: names crsp_m or crsp_d)        */
/* ********************************************************************************* */
%MACRO CRSPMERGE (s=m, START=01JAN2000, END=30JUN2001, SFVARS=vol prc ret shrout,
SEVARS=ticker cusip ncusip permco permno exchcd shrcd siccd dlret, FILTERS=, OUTSET=crsp_&s.);

/* Check Series: Daily or Monthly and define datasets - Default is Monthly. */
%if &s=D %then %let s=d; %else %if &s ne d %then %let s=m;
/*mseall and msenames are not so different.*/
%let sf       = mysas.&s.sf ;
%let se       = mysas.&s.seall ;
%let senames  = mysas.&s.senames ;
/* <WRDS overview of CRSP U.S. stock database> */
/* mse = msenames+msedist+msedelist+mseshares+msenasdin, the 5 types of events. */

/* Mseall: event type is not available. Items associated with a one-time event, such as dividend cash amount (divamt), */
/* will not be carried on to the next observation. If there are multiple one-time events within one month, */
/* multiple observations will appear for the same date. */
/* (Note that because event type is available in mse file, it writes each event on multiple observations, sharing the same date.) */

/* Stocknames: a cross b/w dseall and dsenames. It has only the most important identification variables, */
/* eliminating much of the noise of dseall.*/

%put ; 
%put #### START. Merging CRSP Stock File (&s.sf) and Event File (&s.se) ;

options nonotes;
/*Below changes date into format "5.": '01JAN2000' -> 14610 */
/*'DEC312012' -> 19358*/
%let sdate = %sysfunc(putn("&start"d,5.)) ; 
%let edate = %sysfunc(putn("&end"d,5.)) ; 

/*compbl(): removes multiple blanks from a character string*/
/*lowcase(): converts the whole string into lower cases */
/*nwords: macro. Returns number of words in the string. Words delimited by space.*/
%let sevars   = %sysfunc(compbl(&sevars));
%let sevars   = %sysfunc(lowcase(&sevars));
%include mymacro('nwords.sas');
%let nsevars  = %nwords(&sevars);

/* create lag event variable names to be used in the RETAIN statement */
/* tranwrd(): Replaces all occurrences of a substring in a character string */
/* e.g. tranwrd(source="apple", target="p", replacement="b") = "abble" */

/*example) SEVARS=ticker ncusip*/
/*By running below, sevars_l = lag_ticker lag_ncusip*/

/*If run "%let sevars_l = %sysfunc(tranwrd(&sevars,%str( ),%str( lag_)));", then*/
/*sevars_l = ticker lag_ncusip*/
%let sevars_l = lag_%sysfunc(tranwrd(&sevars,%str( ),%str( lag_))); 

/*length(): # of character string. length('ABC') = 3*/
%if %length(&filters) > 2 %then %let filters = and &filters; 
  %else %let filters = %str( );

/* Get stock data */
proc sql;
    create table __sfdata 
    as select *
    from &sf (keep= permno date &sfvars)
    where date between &sdate and &edate 
    and permno in 
    (select distinct permno from 
      &senames(WHERE=(&edate>=NAMEDT and &sdate<=NAMEENDT) 
         keep=permno namedt nameendt) ) /*By keeping only relevants, can boost up the calculation speed*/
    order by permno, date; /*equivalent to PROC SORT. CREATE "VIEW" don't work with PROC SORT*/
    quit; 

/* Get event data */
proc sql;
   create table __sedata
   as select a.*
   from &se (keep= permno date &sevars) as a,
    (select distinct permno, min(namedt) as minnamedt from 
      &senames(WHERE=(&edate>=NAMEDT and &sdate<=NAMEENDT) 
         keep=permno namedt nameendt) group by permno) as b
/*In b, only permno and minnamedt will be stored (locally)*/
/*GROUP BY clause enables one to break query results into subsets of rows */
/*and to use an aggregate function in the SELECT clause or a HAVING clause*/
/*to instruct PROC SQL how to group the data*/
/*When one don't use an aggregate function, PROC SQL treats the GROUP BY clause as an ORDER BY clause*/
/*and any aggregate functions are aplied to the entire table*/
/*aggregate functions: avg(), mean(), max(), min(), range(), sum(), ...*/
    where a.date >= b.minnamedt and a.date <= &edate and a.permno =b.permno 
/*Why not just &sdate instead of b.minnamedt?*/
   order by a.permno, a.date;
   quit;
/*So within each permno, select min(namedt) from &senames satisfying WHERE condition*/


/* Merge stock and event data */
/*%let eventvars = ticker comnam ncusip shrout siccd exchcd shrcls shrcd shrflg trtscd nmsind mmcnt nsdinx;*/
%let eventvars = ticker comnam cusip ncusip permco permno shrout siccd exchcd shrcls shrcd shrflg dlret trtscd nmsind mmcnt nsdinx;

data &outset. (keep=permno date &sfvars &sevars);
merge __sedata (in=eventdata) __sfdata (in=stockdata);
/*in= Data Set Option creates a Boolean variable INTERNALLY that indicates whether the data set*/
/*contributed data to the current observation*/
/*If data from __sedata then eventdata=1. If from __sfdata, then stockdata=1*/
/*However, eventdata, stockdata never printed in Data set UNLESS they are assigned to a new variable*/
by permno date; retain &sevars_l;
/*Without a RETAIN statement, SAS automatically sets variables that are assigned values */
/*by an INPUT or assignment statement to missing before each iteration of the DATA step. */
/*Use a RETAIN statement to specify initial values for individual variables, a list of variables, or members of an array. */
%do i = 1 %to &nsevars;
  %let var   = %scan(&sevars,&i,%str( )); /*Reads in each variable through iteration delimited by space*/
  %let var_l = %scan(&sevars_l,&i,%str( ));
/*INDEX(source,excerpt): searches source, from left to right, for the first occurrence of the string specified in excerpt,*/
/*and returns the position in source of the string's first character*/
  %if %sysfunc(index(&eventvars,&var))>0 %then
   %do; 
     if eventdata or first.permno then &var_l = &var. ;
     else if not eventdata then &var = &var_l. ;
   %end;
%end;
if eventdata and not stockdata then delete; 
/*Don't see why, but above IF statement doesn't work w/o DO loops above*/
drop &sevars_l ;
/* Above DROP statement seems ineffective, because of KEEP statement data &outset.(keep=permno date &sfvars &sevars). */
/* Hence, &sevars_l seems to be dropped already. */
/* Whether running above DROP statement or not doesn't make any difference in &outset due to KEEP statement. */
/* But the reason why running the above code complains only in CRSPMERGE2() and NOT here is a mystery. */
/* --> This is because &var, a word in a word vector &sevars, is a subset of &eventvars, which is not the case of CRSPMERGE2(). */
run;

/* Some companies have many distribution on the same date (e.g. a stock and cash dist)  */
/* Records will identical except for different DISTCD and DISTAMT */
proc sort data=&outset. noduplicates;
where 1 &filters;
    by permno date;
run;

/* Don't see why, but there're observations having DATE and PERMNO only. */
/* I checked the DATE is wrong, which a prior month of a firm's NAMEDT. */
/* So, the DATA step below will remove it. */
/* This is probably because BY variables are DATE and PERMNO. */
data &outset.; set &outset.;
if missing(permco) then delete;
run;
/* PERMCO is always non-missing in MSEALL, so checking with PERMCO for empty observation seems fine. */
/* NOTE that PERMNO cannot be used for this, as this is a BY variable. */


/* House Cleaning */
proc sql; 
drop table __sedata, __sfdata; 
quit; 

options notes;
%put #### DONE . Dataset &outset. Created! ;
%put ;

%MEND CRSPMERGE;

/* ********************************************************************************* */
/* *************  Material Copyright Wharton Research Data Services  *************** */
/* ****************************** All Rights Reserved ****************************** */
/* ********************************************************************************* */
