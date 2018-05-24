/* ********************************************************************************* */
/* ******************** W R D S   R E S E A R C H   M A C R O S ******************** */
/* ********************************************************************************* */
/* WRDS Macro: VW_AVGPRICE                                                           */
/* Summary   :                                                                       */
/*                                                                                   */
/*                                                                                   */
/*                                                                                   */
/* Date      :                                                                       */
/* Version:   1.0                                                                    */
/* Author    : Mark Keintz, WRDS                                                     */
/* Variables : -                                                                     */
/*             -                                                                     */
/* ***********************************************************************************/
%macro vw_avgprice(indsn=,outdsn=
			,begdate=,enddate=,beghms=09:30:00,endhms=16:00:00,inthms=00:00:60
			,symlist=_ALL_,symdsn=
			,p_var=price,v_var=size,d_var=date,t_var=time,s_var=symbol,nt_var=
			,help=no)
			/ des="Generate Volume-weighted average price over user-specified time intervals";
	%local vrs;
	%let vrs=1.2;

	%if %lowcase(&help)=yes %then
		%do;
			%put *********************************************************************************;
			%put ** VW_AVGPRICE: Volume Weighted Average Trade Price.                           **;
			%put **                                                                             **;
			%put **  Version &vrs                                                               **;
			%put **                                                                             **;
			%put **     Generates a dataset of volume-weighted average trade prices             **;
			%put **     for user-specified time intervals (e.g. minute-by-minute,               **;
				%put **     30 seconds, 5 minutes, etc.).                                           **;
			%put **                                                                             **;
			%put **     The output dataset will have the following variables:                   **;
			%put **       SYMBOL       (Or user-designated trading ticker var)                  **;
			%put **       DATE         (Or the user-designated date var).  Note                 **;
			%put **                    that if the D_VAR argument (see below) is                **;
			%put **                    set to null, then no date variable will be               **;
			%put **                    written to the output dataset.                           **;
			%put **       INTRVL_BEGTIME (SAS time stamp for beginning of each time             **;
				%put **                      interval)                                              **;
			%put **       VW_AVG_PRICE (Vol-weighted avg price for the interval)                **;
			%put **       TOTAL_VOL    (Total trade-vol for this time interval)                 **;
			%put **       N_TRADES     (Number of trades for this time interval)                **;
			%put **                                                                             **;
			%put **     The output will be sorted by SYMBOL DATE INTRVL_BEGTIME.                **;
			%put **                                                                             **;
			%put **  Parameter list:  (Note all parameters are in the "name=value"              **;
				%put **     form, and may be used in any order).                                    **;
			%put **                                                                             **;
			%put **  INDSN= (Required)  Name of input dataset. Must have variablles             **;
			%put **    SYMBOL DATE TIME PRICE and SIZE (the "volume" variable).                 **;
			%put **    (Other varnames can be substitued - see parameters below).               **;
			%put **    Must be sorted by SYMBOL DATE TIME.                                      **;
			%put **                                                                             **;
			%put **  OUTDSN= (Required) Name of output dataset to generate.  It                 **;
			%put **    will be sorted by SYMBOL DATE INTRVL_BEGTIME (time at                    **;
				%put **    beginning of interval) and will also have vars TOTAL_VOL                 **;
			%put **    VW_AVG_PRICE and N_TRADES.                                               **;
			%put **                                                                             **;
			%put **  BEGDATE= (Optional, default=blank).  Beginning date, in date9              **;
			%put **    form, without the quotes (e.g. 02DEC2008).  Accept no INDSN              **;
			%put **    record PRECEDING begdate.  If blank, then no BEGDATE                     **;
			%put **    filtering needed.  Also if D_VAR is blank, no BEGDATE filtering          **;
			%put **    will be done, regardless of BEGDATE value.                               **;
			%put **                                                                             **;
			%put **  ENDDATE= (Optional, default=blank).  Ending date in date9 form,            **;
			%put **    without the quotes (e.g. 02DEC2008).  Accept no INDSN                    **;
			%put **    records after enddate.  If blank then no ENDDATE filtering               **;
			%put **    needed.  Also if D_VAR is blank, no ENDDATE filtering will be            **;
			%put **    done, regardless of ENDDATE value.                                       **;
			%put **                                                                             **;
			%put **  BEGHMS= (Optional, default=09:30:00).  Beginning time, in                  **;
			%put **    hh:mm:ss form. Accept only records with                                  **;
			%put **    TIME >= BEGHMS.  Note BEGHMS is treated differently                      **;
			%put **    than ENDHMS.  Records with time=BEGHMS are included,                     **;
			%put **    while records with time=ENDHMS are excluded.                             **;
			%put **                                                                             **;
			%put **  ENDHMS= (Optional, default=16:00:00).  Ending time, in                     **;
			%put **    hh:mm:ss form.  Accept only records with                                 **;
			%put **    TIME <= ENDHMS. Note ENDHMS is treated differently                       **;
			%put **    than BEGHMS.  Records with time=BEGHMS are included,                     **;
			%put **    while records with time=ENDHMS are excluded.                             **;
			%put **                                                                             **;
			%put **  INTHMS= (Optional, default=00:00:60)  Interval size in                     **;
			%put **    hh:mm:ss form.  Length of intervals over which volume-                   **;
			%put **    weighted means will be calculated.                                       **;
			%put **                                                                             **;
			%put **  SYMLIST= (Optional, default=_ALL_). Space-separated list of                **;
			%put **    stock SYMBOLS (without quote marks) to accept from INDSN.                **;
			%put **    If symlist=_ALL_, then take all symbols from INDSN.                      **;
			%put **                                                                             **;
			%put **  SYMDSN= (Optional, default=blank).  For use when the SYMLISST              **;
			%put **    parameter becomes too large.  SYMDSN names a dataset with the            **;
			%put **    set of symbols to use in filtering INDSN.  Note this dataset             **;
			%put **    must use the same variable name for trading symbol as in INDSN.          **;
			%put **    NOTE: If SYMLIST has any value other than _ALL_, then SYMDSN             **;
			%put **    is ignored.                                                              **;
			%put **                                                                             **;
			%put **  HELP= (optional, default=no). If help=yes (any case), generate             **;
			%put **     these notes.                                                            **;
			%put **                                                                             **;
			%put **                                                                             **;
			%put **  The parameters below specify the actual variable names used in             **;
			%put **    this macro.  Note that they default to the varnames used in              **;
			%put **    the TAQ trades datasets (i.e. the "ct" datasets).                        **;
			%put **                                                                             **;
			%put **  P_VAR= (Optional, default=price).  Name of the trading price               **;
			%put **    price variable in the INDSN dataset.                                     **;
			%put **                                                                             **;
			%put **  V_VAR= (Optional, default=size).  Name of the trading volume               **;
			%put **    variable in the INDSN dataset.                                           **;
			%put **                                                                             **;
			%put **  D_VAR= (Optional, default=date).  Name of the date variable                **;
			%put **    in the INDSN dataset.  Must be stored as a SAS data value.               **;
			%put **    Note that if you set D_VAR to a null value, then no date                 **;
			%put **    variable is read from INDSN nor output to OUTDSN, and no                 **;
			%put **    date filtering will be done.                                             **;
			%put **                                                                             **;
			%put **  T_VAR= (Optional, default=time).  Name of the time variable in             **;
			%put **    the INDSN dataset.  Must be stored as a SAS time value.                  **;
			%put **                                                                             **;
			%put **  S_VAR. (Optional, default=symbol).  Name of the trading ticker             **;
			%put **    variable in the INDSN dataset. Must be a character variable.             **;
			%put **                                                                             **;
			%put **  NT_VAR. (Optional, default=blank). Name of var (if any) that               **;
			%put **    contains the number of trades represented by the current                 **;
			%put **    INDSN record.  If blank then assume each incoming record                 **;
			%put **    represents one trade.                                                    **;
			%put **                                                                             **;
			%put **                                                                             **;
			%put ** Usage Examples:                                                             **;
			%put %nrstr(    %VW_AVGPRICE(indsn=taq.ct_20081202,outdsn=mydata,beghms=12:00:00,inthms=05:00));
			%put **     generates dataset MYDATA, with volume-weighted average                  **;
			%put **     prices for 5-minutes intervals, for all trades between noon             **;
			%put **     noon and 4PM from taq.ct_20081202                                       **;
			%put **                                                                             **;
			%put **    Note that all parameters are entered in the form                         **;
			%put **      param_name1=param_value1,param_name2=param_value2,...                  **;
			%put **                                                                             **;
			%put **    There are no positional parameters, and the "name="                      **;
			%put **    parameters may be entered in any order.                                  **;
			%put **                                                                             **;
			%put ** DEPENDENCIES:                                                               **;
			%put **    DBLQUOTELIST (a WRDS macro)                                              **;
			%put **                                                                             **;
			%put ** VERSION 1.0: Initial version.                                               **;
			%put **                                                                             **;
			%put ** VERSION 1.1: Allow specification of different price, volume,                **;
			%put **   date, and time variables.  Also add provision for the NT_VAR              **;
			%put **   parameter.                                                                **;
			%put **                                                                             **;
			%put ** VERSION 1.2: Permit specification of user-specified dataset of              **;
			%put **   requested symbols, instead of a user-specified list.                      **;
			%put **                                                                             **;
			%put ** ******************************************************************************;
			%goto done;
		%end;

	%local        /****************************************************************/

	/* Other local macrovars:                                       */
	/*                                                              */
	sym_method  /* =1 if symbol filtering to be done via a WHERE clause.        */

	/* =2 if symbol filtering to be done via a JOIN/MERGE.          */
	/* =3 if no symbol filtering to be done.                        */
	/*                                                              */
	qsymlen     /* Estimated length of comma-separated list of quoted symbols.  */

	/*                                                              */
	qsymlist    /* symlist with symbols quoted, comma-separated.                */

	/*                                                              */
	wh_filter   /* Where filter to apply to current record.                     */

	/*                                                              */
	wh_text     /* Utility, starts as a blank, becomes "and", for building      */

	/* compound where expressions.                                  */
	/*                                                              */
	int_secs    /* Interval size, in seconds.                                   */

	/*                                                              */
	int_text    /* Interval size as text (e.g. minute, 5-minute, 30 seconds),   */

	/*   to be used in dataset and variable labels.                 */
	/*                                                              */
	nt_yn       /* If nt_var is blank, then NT_YN=no, else NT_YN=yes.           */

	/* **************************************************************/
	;
	/* First determine SYM_METHOD */
	%if %upcase(&symlist) ^= _ALL_ %then
		%let sym_method=1;
	%else %if &symdsn =            %then
		%let sym_method=3;
	%else
		%do;

			proc sql noprint;
				select sum(length(trim(&s_var))+3) into : qsymlen from (select distinct &s_var from &symdsn);

				%if &qsymlen > 32700 %then
					%do;
						%let sym_method=2;
						%put +----------------------------------------------------------+;
						%put |  Too many &s_var values (total length=&qsymlen.).        |;
						%put |  Will use SYM_METHOD 2 (Merge of &indsn with &symdsn).;
						%put +----------------------------------------------------------+;
					%end;
				%else
					%do;
						%let sym_method=1;
						%put +----------------------------------------------------------+;
						%put |  Length of all &s_var values is &qsymlen..               |;
						%put |  Will convert to SYM_METHOD 1 (i.e. WHERE clause).       |;
						%put +----------------------------------------------------------+;
						select distinct &s_var into : symlist separated by ' ' from &symdsn;
					%end;
			quit;

		%end;

	%let int_secs = %sysfunc(inputn(&inthms,time8.));/* Interval Size, in seconds */

	/* Construct interval size in text form (e.g. "2 Minutes", "30 Seconds", "03:30") */
	%if       &int_secs < 60 %then
		%let int_text = &int_secs Seconds;
	%else %if &int_secs = 60                %then
		%let int_text = Minute;
	%else %if %sysfunc(mod(&int_secs,60))=0 %then
		%let int_text = %eval(&int_secs/60) Minutes;
	%else                                         %let int_text = %sysfunc(putn(time8.));
	%let wh_text =  ;     /* change  to "and" after setting first filter component */
	%let wh_filter= ;     /* Initialize where filter for trade data */

	/* Begin building the compound where conditions */
	/* Add "&S_VAR in ("AAA" "BBB" ... ) " filter, if requested */
	%if       &sym_method=3 %then;        /* &S_VAR filter NOT needed */
	%else %if &sym_method=2 %then;        /* &S_VAR filter wlll be done via MERGE */
	%else %if &sym_method=1 %then
		%do;
			/* &S_VAR filter using WHERE is needed */
			%let qsymlist  = %dblquotelist(&symlist);
			%let wh_filter = &wh_filter &wh_text ( &s_var in ( &qsymlist ) );
			%let wh_text   = %str(and);
		%end;

	/* Add a DATE RANGE filter, if requested */
	%if &d_var = %then ;                      /* DATE filter not possible */
	%else %if &begdate= and &enddate= %then ; /** DATE filter not needed */
	%else
		%do;
			/* DATE filter IS needed */
			%if &begdate = &enddate %then
				%let wh_filter = &wh_filter &wh_text ( &d_var = "&begdate"d );
			%else %if &begdate =    %then
				%let wh_filter = &wh_filter &wh_text ( &d_var <= "&enddate"d );
			%else %if &enddate =    %then
				%let wh_filter = &wh_filter &wh_text ( &d_var >= "&begdate"d );
			%else                         %let wh_filter = &wh_filter &wh_text ( &d_var between "&begdate"d and "&enddate"d );
			%let wh_text = %str(and);
		%end;

	/* Add a TIME RANGE filter, if requested */
	%if &beghms=00:00:00 and &endhms=24:00:00 %then;/* TIME filter NOT needed */
	%else
		%do;
			/* TIME filer IS needed */
			%if       &beghms = 00:00:00 %then
				%let wh_filter = &wh_filter &wh_text ( &t_var <= ("&endhmst"t -1) );
			%else %if &endhms = 24:00:00 %then
				%let wh_filter = &wh_filter &wh_text ( &t_var >= "&beghms"t );
			%else                              %let wh_filter = &wh_filter &wh_text ( &t_var between "&beghms"t and ("&endhms"t - 1) );
			%let wh_text = %str(and);
		%end;

	/* With completed WHERE clause, convert it to dataset name parameter format */
	%if wh_text ^= %then
		%let wh_filter= %str( where= ( &wh_filter ) );
	%else                %let wh_filter= %str( where=(1));

	/* Set up nt_yn, to be used a few times below */
	%if &nt_var= %then
		%let nt_yn=no;
	%else %let nt_yn=yes;

	/* If sym_method requires join or merge, prepare dataset of requested symbols */
	%if &sym_method=2 %then
		%do;

			proc sort data=&symdsn (keep=&s_var) out=_symlist_ nodupkeys;
				by &s_var;
			run;

		%end;

	/* Make a data view, in which each specific time is mapped to its time-interval */
	data vtemp (keep=&s_var &d_var intrvl_begtime &p_var &v_var &nt_var )  / view=vtemp;
		%if &sym_method=2 %then
			%str(
			merge &indsn ( in=indata &wh_filter ) _symlist_ (in=inkeep);
			by &s_var;
			if inkeep=indata;
				);
		%else %str( set &indsn ( &wh_filter ); );

		/* If NT_VAR exists, divide by Volume, so weighted PROC MEANS yields right N_TRADES */
		%if &nt_yn=yes %then
			%str(&nt_var = &nt_var / &v_var;);

		/* Establish beginning of each time interval */
		INTRVL_BEGTIME= &t_var - mod(&t_var,&int_secs);
		attrib INTRVL_BEGTIME  label = "Current &int_text Start Time" format=time8.0 length=4;
	run;

	proc means data=vtemp noprint;
		by &s_var &d_var intrvl_begtime;
		var &p_var &nt_var;
		weight &v_var;
		output out=&outdsn (
		label="%upcase(&v_var)-Weighted Average %upcase(&p_var), &int_text BY &int_text"
		drop=_TYPE_ _FREQ_
		sortedby = &s_var &d_var intrvl_begtime
		)
		mean(&p_var)=VW_AVG_PRICE  
/*		sumwgt(&p_var)=TOTAL_VOL*/
/*		%if &nt_yn=yes %then sum(&nt_var) = N_TRADES;*/
/*		%else                           n = N_TRADES;*/
		;
	run;

	/* Assign Attributes of new variables */
	/* NB: macrovar SYSDSN is the library and name of the last dataset created */
	proc datasets nolist library=%scan(&sysdsn,1,%str( ));
		modify %scan(&sysdsn,2,%str( ));
/*		label TOTAL_VOL    = "Total Shares Traded This &int_text";*/
/*		label VW_AVG_PRICE = "Volume Weighted Average &p_var this &int_text";*/
/*		label N_TRADES     = "Number of Trades This &int_text";*/
	run;

	quit;

%done:
	;
%mend vw_avgprice;

/* ********************************************************************************* */
/* *************  Material Copyright Wharton Research Data Services  *************** */
/* ****************************** All Rights Reserved ****************************** */
/* ********************************************************************************* */
