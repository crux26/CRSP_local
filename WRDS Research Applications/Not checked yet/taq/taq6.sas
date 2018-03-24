/* ************************************************************************* */
/* ************** W R D S   R E S E A R C H   A P P L I C A T I O N S ****** */
/* ************************************************************************* */
/*   Program  :   taq6.sas                                                   */
/*   Author   :   WRDS staff                                                 */
/*   Date     :   5/5/2005                                                   */
/*   Modified :   9/27/2011                                                  */
/* ************************************************************************* */
/*   Program Description:                                                    */ 
/*   Usage : Retrieve Transaction price for a fixed interval, e.g.,          */
/*             every 15 minutes.                                             */
/*                                                                           */
/*   1)  Output format (e.g., every 15 minutes)                              */
/*                                                                           */
/*           Obs  symbol         date       itime       iprice        rtime  */
/*           1     DELL     02SEP2003       9:30:00     33.340       9:30:00 */
/*           2     DELL     02SEP2003       9:45:00     33.370       9:44:59 */
/*           3     DELL     02SEP2003      10:00:00     33.070       9:59:59 */
/*           4     DELL     02SEP2003      10:15:00     33.250      10:14:59 */
/*           5     DELL     02SEP2003      10:30:00     33.230      10:29:59 */
/*           6     DELL     02SEP2003      10:45:00     33.140      10:44:58 */
/*           7     DELL     02SEP2003      11:00:00     33.260      10:59:56 */
/*           8     DELL     02SEP2003      11:15:00     33.190      11:14:50 */
/*           9     DELL     02SEP2003      11:30:00     33.350      11:29:54 */
/*          10     DELL     02SEP2003      11:45:00     33.320      11:44:51 */
/*                                                                           */
/*   2)  Definitions of several variables                                    */ 
/*                                                                           */
/*          symbol -- stock symbol                                           */
/*          date   -- transaction date                                       */
/*          itime  -- interval time                                          */
/*          iprice -- interval price corresponding to interval time (itime)  */
/*          rtime  -- real time (Trading time)                               */
/*                                                                           */
/*   3) Logic: choose records close to the interval time (before it).        */
/*                                                                           */
/*          For example, for 9:45:00 (09/02/2005, DELL), you will have       */
/*          iprice=33.370,which is the transaction price occurred at 9:44.59,*/ 
/*          see above record 2.                                              */
/*                                                                           */
/*   4) Inputs -- see input area (users should modify this area)             */
/*                                                                           */
/*          a) %let taq_ds=taq.ct0309: ;      * data set you are interested  */
/*          b) %let start_time = '9:30:00't;  * starting time                */
/*          c) %let interval_seconds = 15*60; * interval is 15 minutes       */
/*                                                                           */
/*   5) Some related issues                                                  */
/*                                                                           */
/*          a) only choose 3 stocks: SPY,IBM and DELL                        */
/*          b) only one day. If you want multiple-day data, modify the       */
/*               program accordingly                                          */
/*          c) for less frequently traded stocks, when no trades within an   */ 
/*	       interval, missing values will occur                           */
/*          d) no filter is used                                             */
/*                                                                           */
/*   6) If several records share the same time stamp, the program will pick  */
/*	up the first one.                                                    */
/*                                                                           */
/*   7) Step added by repeating the last available price if there are no     */
/*	trades during an interval. See  'do while(time >= itime)'  code.     */
/*                                                                           */
/* ************************************************************************* */

options nosource nodate nocenter nonumber ps=max ls=72;

/****** Input area **************************/

%let taq_ds=taq.ct_199512: ;     * data set you are interested (example for all daily files on December 1995);
%let start_time = '9:30:00't;    * starting time; 
%let interval_seconds =15*60;    * interval is 15*60 seconds (15 minutes);

/****** End of input area **********************/


/* Extract data for one day for 3 stocks, we consider the time 
  between  9:30am to 4:30pm,  only retrieve SYMBOL DATE TIME and PRICE;
data tempx;*/
     set &taq_ds(keep=symbol date time price); 
     where symbol in ('SPY','IBM','DELL')
     and time between '9:30:00't and '16:30:00't;
	 by symbol date time;
	 retain itime rtime iprice; *Carry time and price values forward;
        format itime rtime time12.;
     if first.symbol=1 or first.date=1 then do;
        */Initialize time and price when new symbol or date starts;*/ 
        rtime=time; 
        iprice=price;
        itime= &start_time;
     end;
     if time >= itime then do; /*Interval reached;*/
           output; /*rtime and iprice hold the last observation values;*/
           itime = itime + &interval_seconds;
           do while(time >= itime); /*need to fill in all time intervals;*/
               output; 
               itime = itime + &interval_seconds;
           end;
    end;
    rtime=time;
    iprice=price;
    keep symbol date itime iprice rtime;
run;

Title "Final output -- &interval_seconds seconds";
proc print data=tempx (obs=400); 
     var symbol date itime iprice rtime;
run;


/* ********************************************************************************* */
/* *************  Material Copyright Wharton Research Data Services  *************** */
/* ****************************** All Rights Reserved ****************************** */
/* ********************************************************************************* */

