/* ************************************************************************* */
/* ************** W R D S   R E S E A R C H   A P P L I C A T I O N S ****** */
/* ************************************************************************* */
/* Program   : taq_open_close_price.sas                                      */
/* Date      : Modified Aug, 2011                                            */
/* Author    : Mark Keintz                                                   */
/* ***************************************************************************/

options msglevel=I nosource nodate nocenter nonumber ps=max ls=72; title;

data mysample; 
  length symbol $10.;
  input symbol ;
datalines;
DELL
IBM 
MSFT
F
ABC
;
run;

/** Make macro LISTSYMS to look like "DELL","IBM","MSFT",.....  **/
proc sql noprint;
  select distinct    quote(symbol)  into : listsyms  separated by ','  from MYSAMPLE;
quit;


/* Get Open and Closing Price */

Data open_close (keep=date symbol time_open price_open price_close time_close); 
set taq.ct_199512: 
    taq.ct_199601:
	/* example covers all December 1995 and January 1996 daily files*/
   ; 
   where symbol in (&listsyms);
   /* where also  time between ('09:30:00't and '16:00:00't) ;  /* "WHERE ALSO" is a legal statement */
   by symbol date; 
   retain price_open time_open;

  /*Do not reset this variable to a missing value */; 
  if first.date then do;
	price_open=price; 
    time_open=time; format time_open time.;
  end;
  if last.date then do; 
    price_close=price; 
    time_close=time;  format time_close time.;
    output; 
  end; 
run;

proc print data=open_close (obs=60);
run;

/* ********************************************************************************* */
/* *************  Material Copyright Wharton Research Data Services  *************** */
/* ****************************** All Rights Reserved ****************************** */
/* ********************************************************************************* */


