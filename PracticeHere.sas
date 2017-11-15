/*START AGAIN FROM /AMBIGUITY_CODES/SPXDATA_TRIM_2ND (2017.10.26)*/

/* Currently working on <indadjbm to portfolios>. */
/* # of result firms from <B2M ratio - DT> are too small compared to <B2M ratio - FF>. */

/* WARNING: in PROC SORT, NODUPKEY and NODUPLICATES are DIFFERENT. */
/* NODUPLICATES: delete duplicated observations (records identical to each other). */
/* NODUPKEY: delete observations with duplicate BY values (the sort BY variables). */


/* After that, re-check FF factors replication.sas, and find a way to form portfolio returns */
/* using indadjbm (industry-adjusted B2M). (2017.08.28) */

/*COMPUSTAT: NO MORE /d_na, but /naa (use /nam instead)*/

/*a_ccm.ccmxpf_linktable: almost equivalent to a_ccm.ccmxpf_lnkhist */

/* The identification of a fiscal year is the calendar year in which it ends.*/
/* FY: from t-1, July to t, June prior to 1976.*/
/*ex) FY17: Oct, 2016 ~ Sep, 2017. */
/*ex) datadate=20080531, fyear=2007, fyr=5 --> Jun, 2006 ~ May, 2007 written at 20080531. */
/*ex) datadate=20090930, fyear=2009, fyr=9 --> Aug, 2008 ~ Sep, 2009 written at 20090930. */

/*%include myMacro('SetDate.sas'); WILL NOT work unless */
/*-SASINITIALFOLDER "D:\Dropbox\GitHub\CRSP_local" added to sasv9.cfg in ...\nls\en and \ko*/

/* To automatically point to the macros in this library within your SAS program */
options sasautos=('D:\Dropbox\GitHub\CRSP_local\myMacro\', SASAUTOS) MAUTOSOURCE;
%liblist_lab;

options sasautos=('F:\Dropbox\GitHub\CRSP_local\myMacro\', SASAUTOS) MAUTOSOURCE;
%liblist_dorm;

/*Daniel, Titman(2006)'s criteria --> applied to &comp..funda.*/
%let comp_filter=consol='C' and indfmt='INDL' and datafmt='STD' and popsrc='D'; 
/*consol: Level of consolidation. {C(onsolidated), I, N, P, D, E, R}*/
/*indfmt: Industry Format. {FS (Financial Services), INDL (Industrial), ISSUE (Issue-level FUndamentals)} */
/*datafmt: Data Format. {STD, HIST_STD, RST_STD, SUMM_STD, PRE_AMENDS, PRE_AMENDSS} */
/*popsrc: Population Source. {D(omestic - NA companies), I(nternational)}*/

/*DGTW(1997)'s criteria --> applied to a_stock.xsf, xse.*/
/*Variables adjusted a little.*/
%let sfvars = permco permno prc ret vol shrout cfacpr cfacshr;
%let sevars = ticker cusip ncusip exchcd shrcd siccd dlret;
%crspmerge(s=m,start=01JAN1962, end=31DEC2016,
sfvars=&sfvars, sevars=&sevars, 
filters=(shrcd in (10,11)), outset=mysas.crsp_m); 

%crspmerge(s=d,start=01JAN1962, end=31DEC2016,
sfvars=&sfvars, sevars=&sevars, 
filters=(shrcd in (10,11)), outset=mysas.crsp_d); 

/**/
/**/
/**/
/*IDVOL calculation*/

%let freq=d;
%let window=20;
%let min=15;
%Trade_Date_Windows(freq=&freq, size=&window, minsize=&min, outdsn=_caldates);


proc format;
picture myfmt low-high = '%Y%0m%0d_%0H%0M%0S' (datatype=datetime);
run;

%put timestamp=%sysfunc(datetime(), myfmt.);
 %IDVOL(inset=crsp_d, outset=idvol_ff_21D, datevar=date, retvar=ret, freq=d, window=21, step=1, min=15, model=ff);
%put timestamp=%sysfunc(datetime(), myfmt.);

/*Below: PERMNO<10010*/
data crsp_d; set mysas.crsp_d(obs=24575); where permno < 10010; run;

%let dateff=date;
%let file=daily; 
%let inc=day;
%let inset=crsp_d;
%let vars=mktrf smb hml;
%let datevar=date;
%let retvar=ret;

    proc sql noprint;
        create table _vol
            as select a.*, b.*, (&retvar-rf) as exret
                from &inset as a left join ff.factors_&file (keep=&dateff rf &vars) as b
                    on a.&datevar=b.&dateff
                order by a.permno, a.&datevar;
        select distinct min(&datevar) format date9.,
            max(&datevar) format date9. into :mindate, :maxdate
            /*Above is equivalent to "%let mindate = min(&datevar)", maxdate=max(&datevar). */

        from _vol;
    quit;

/*------------------------------------------------------------------------------------------*/
/*------------------------------------------------------------------------------------------*/
/*------------------Find the below data in myoption.------------------------------*/

data opprcd2015; set optionm.opprcd2015; 
where secid=108105 and date between '01apr2015'd and '30apr2015'd;
strike_price=strike_price/1000; run;

/*Below includes SPX, SPXW, SPX EOM.*/
proc sort data=opprcd2015 out=have0_; by cp_flag exdate date strike_price; run;


data myoption.opprcd2015; set opprcd2015; run;
data myoption.have0_; set have0_; run;

data opprcd2015; set optionm.opprcd2015; if find(symbol,'W')=0 then output; 
where secid=108105; strike_price =strike_price/1000;run;

data opprcd2011; set optionm.opprcd2011; 
where secid=108105 and date between '01Oct2011'd and '31Dec2011'd; strike_price=strike_price/1000; run;

data myoption.opprcd2011; set opprcd2011; run;

data have1_ have1__; set have0_;
/*if findw(symbol, 'W')>0 then output have1_;*/
if find(symbol, 'W') > 0 then output have1_;
else output have1__;
run;

data have2011_; set opprcd2011;
if ss_flag=1;
run;


data spx_options; set opprcd1996 opprcd2011; run;

proc sort data=spx_options out=spx_options_sorted; by date exdate cp_flag strike_price; run;

proc export data = spx_options
outfile = "C:\Users\User\Desktop\spx_options.xlsx"
DBMS = xlsx REPLACE;
run;

proc export data = spx_options_sorted
outfile = "C:\Users\User\Desktop\spx_options_sorted.xlsx"
DBMS = xlsx REPLACE;
run;

proc export data = spx_options
outfile = "C:\Users\User\Desktop\spx_options.csv"
DBMS = csv REPLACE;
run;

proc export data = spx_options_sorted
outfile = "C:\Users\User\Desktop\spx_options_sorted.csv"
DBMS = csv REPLACE;
run;

data secprd1996; set optionm.secprd1996;
where secid=108105 and date between '01jul1996'd and '31jul1996'd;
run;

data secprd2011; set optionm.secprd2011;
where secid=108105 and date between '01oct2011'd and '31oct2011'd;
run;

data secprd; set secprd1996 secprd2011; run;

proc export data = secprd
outfile = "C:\Users\User\Desktop\secprd.csv"
DBMS = csv REPLACE;
run;
