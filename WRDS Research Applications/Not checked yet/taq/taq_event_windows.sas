/**  **************************************************************************/
/**  Program        : TAQ_EVENT_WINDOWS                                      **/
/**  Author         : Mark Keintz                                            **/
/**  Version        : 1.0                                                    **/
/**  Date Created   : 10/26/2008                                             **/
/**  Last Modified  : 10/26/2008                                             **/
/**                                                                          **/
/**  Description    : Retrieves trade or quote data from TAQ for             **/
/**                   user-specified SYMBOLS, each with a unique             **/
/**                   date and time range.                                   **/
/**                                                                          **/
/**  Usage: Two stages:                                                      **/
/**    Stage 1 :  Prepare a dataset with the following variables:            **/
/**                   SYMBOL BEGDATE BEGTIME ENDDATE ENDTIME                 **/
/**               For example:                                               **/
/**                                                                          **/
/**               data mysample;                                             **/
/**                 length symbol $10. ;                                     **/
/**                 informat begdate enddate yymmdd8. ;                      **/
/**                 informat begtime endtime time8.0 ;                       **/
/**                 input symbol begdate begtime enddate endtime;            **/
/**               datalines;                                                 **/
/**               AZTC 19990301 10:00:00 19990307 15:00:00                   **/
/**               UBID 19990505 10:30:00 19990505 14:30:00                   **/
/**               run;                                                       **/
/**                                                                          **/
/**    Stage 2 : Call the TAQ_EVENT_WINDOWS1 macro as here:                  **/
/**                                                                          **/
/**              %taq_event_windows1(type=CQ,keydataset=mysample             **/
/**                   ,keepvars=,sortord=SDT                                 **/
/**                   ,outdata=want,outtype=dataset,verbosity=some);         **/
/**                                                                          **/
/**              (See the beginning of the TAQ_EVENT_windows1 macro for an   **/
/**               explanation of the parameters).                            **/
/**                                                                          **/
/**                                                                          **/
/******************************************************************************/


%macro taq_event_windows1(type=CQ,keydataset=mysample,keepvars=,sortord=SDT
                   ,outdata=want,outtype=dataset,verbosity=some)
  /DES="Trades or Quotes for selected symbols, with distinct DATE/TIME ranges";

  %local       /* These macrovars have local scope only:                      */
    TYPE       /* Either CQ (quotes) or CT (trades).  CQ is default.          */
    KEYDATASET /* Dataset with SYMBOLS + DATE/TIME ranges (default MYSAMPLE)  */
    KEEPVARS   /* List of user-requested vars (if blank, keep all vars)       */
    SORTORD    /* Output order, either SDT (SYMBOL/DATE/TIME) or DST          */
    OUTDATA    /* Name of dataset or dataview to output                       */
    OUTTYPE    /* Type of output, either DATASET or DATAVIEW                  */
    VERBOSITY  /* ALL (All sas notes/mprint/msglevel=I), or SOME or NONE      */
    ;


  /*** STEP 1: Set up parameters and options ***/

  %let type=%upcase(&type);
  %let sortord=%upcase(&sortord);
  %let outtype=%upcase(&outtype);
  %let verbosity=%upcase(&verbosity);

  %let keeplist1 = &keepvars;  
  %* ** If KEEPLIST1 is not blank or null, prepend a "keep="  **;
  %* ** Also append SYMBOL DATE TIME, needed for prelim steps **;
  %if %length(&keeplist1) ^=0 %then
    %let keeplist1=KEEP%str(=)&keeplist1 SYMBOL DATE TIME;

  %* ** Save prior NOTES, MPRINT, and MSGLEVEL options, for later resetting **;
  %local prior_options;
  %let prior_options=%sysfunc(getoption(NOTES)) %sysfunc(getoption(MPRINT))
      MSGLEVEL=%sysfunc(getoption(MSGLEVEL));

  %* ** if VERBOSITY is SOME or NONE, turn off notes, etc. for steps 2 & 3 **;
  %if %index(SOME NONE,&verbosity) ^= 0 %then
     %str(options nonotes nomprint msglevel=N;);
  %else 
     %str(options notes mprint msglevel=I;);
  ;


  /**** STEP 2: Determine list of TAQ datasets needed ****/

  %* ** 2a: Get minimum and maximum YYYYMMDD in KEYDATASET ;
  %local MIN_YYYYMMDD MAX_YYYYMMDD ;
  proc sql noprint;
    select min(begdate) format=yymmddn8. ,max(enddate) format=yymmddn8.
    into   : min_yyyymmdd                ,: max_yyyymmdd
    from &keydataset;
  quit;

  %* ** 2b: Convert min/max YYYYMMDD into begin/end taq dataset names **;
  %local BEG_DSN END_DSN ;
  %let beg_dsn=&type._&min_yyyymmdd;   %* e.g. 20081003 ==> CQ_20081003 **;
  %let end_dsn=&type._&max_yyyymmdd;

  %* ** 2c: Build list of all datasets from BEG_DSN through END_DSN **;
  %local DSLIST ;
  proc sql noprint;
    select distinct cats('TAQ.',trim(memname)) into :dslist
      separated by ' '
      from sashelp.vtable where
        libname="TAQ" and
        memname between "&beg_dsn" and "&end_dsn"
        ;
  quit;

  %* ** 2d: Get count of candidate dataset names **;
  %local N_DS ;
  %let n_ds=&sqlobs;
  %if &n_ds=0 %then %do;
    %put No &type TAQ datasets available for &min_yyyymmdd to &max_yyyymmdd ;
    %goto MACRODONE ;
  %end;


  /*** STEP 3: For each TAQ dataset (I=1 to N_DS), define a view  ***/

  %local I  YYYYMMDD  DATE;
  proc sql noprint;
  %do I=1 %to &n_ds;
    %local QSYMLIST&I /* List of quoted symbols for the Ith dataset   */
           NSYM&I     /* N SYMBOLS from Ith TAQ dataset               */
           WHENLIST&I /* "when" list (for SELECT statement) for Ith   */ ;

    %* ** Get the Ith date **;
    %let YYYYMMDD = %scan(&dslist,&i,%str( ));  %* Get Ith dsn **;
    %let YYYYMMDD = %scan(&yyyymmdd,2,_);     %* Part after the underscore **;
    %let DATE     = %sysfunc(inputn(&YYYYMMDD,yymmdd8.),date9.);

    select distinct quote(trim(symbol)) into : qsymlist&i 
      separated by ' '
      from &keydataset
      where "&date"d between begdate and enddate;

    %let NSYM&I = &sqlobs;

    %* ** Make list of "when" lines like
        "when ('IBM') do; if '09:30:01't<=time<='13:00:00't then output; end;" ;

    select distinct cats("when (",quote(trim(symbol)),") do; if (","'"
        ,put(begtime,tod8.0),"'t","<=time<=","'",put(endtime,tod8.0)
        ,"'t) then output; end;")
      into :whenlist&i
      separated by ' '
      from &keydataset
      where "&date"d between begdate and enddate;
  %end;
  quit;

  %local VLIST   /* List of preliminary daily data views to use */ ;
  %let vlist=;
  %do I=1 %to &n_ds;
    %if &&nsym&i ^= 0 %then %do;
      data vtemp&i / view=vtemp&i;
        set %scan(&dslist,&I,%str( )) (&keeplist1) ;
        where symbol in (&&qsymlist&i);
        select (symbol);
          &&whenlist&i 
        end;

      run;
      %let vlist=&vlist vtemp&i ;
    %end;
  %end;

  /** if VERBOSITY is SOME or ALL, turn on notes, etc. for the final step **/
  %if %index(SOME ALL,&verbosity) ^= 0 %then 
    %str(options notes mprint msglevel=I;);
  %else 
    %str(options nonotes nomprint msglevel=N;);

  /** STEP 4: Read all the data views into final data output **/

  data &outdata  %if &outtype=DATAVIEW %then %str(/ view=&outdata); ;
    set &vlist   %if &sortord=DST %then %str(open=defer)  ; ;
    /** See TAQ_BASIC for rationale on OPEN=DEFER **/
    %if &sortord=SDT %then 
      %str(BY SYMBOL DATE TIME;);
    %if %length(&keepvars) ^= 0 %then 
      %str(keep &keepvars;) ;
  run;

  %macrodone: options &prior_options ;
%mend taq_event_windows1 ;


/** STAGE 1: Make a "driver" file for the TAQ_EVENT_WINDOW macro **/

data mysample; 
  length symbol $10.;
  informat begdate enddate date9.  begtime endtime time8.0;
  format   begdate enddate date9.  begtime endtime tod8.0 ;
  input symbol   begdate enddate   begtime endtime;
datalines;
DELL  01OCT2009 08OCT2009 09:30:00 14:00:00
IBM   07OCT2009 14OCT2009 10:30:00 15:00:00
MSFT  13OCT2009 20OCT2009 11:30:00 16:00:00
run;

/** STAGE 2: Run the TAQ_EVENT_WINDOW macro **/

%taq_event_windows1(verbosity=none,type=ct,keepvars=symbol date price size
    ,outdata=want,outtype=dataset,sortord=DST);

/* ********************************************************************************* */
/* *************  Material Copyright Wharton Research Data Services  *************** */
/* ****************************** All Rights Reserved ****************************** */
/* ********************************************************************************* */

