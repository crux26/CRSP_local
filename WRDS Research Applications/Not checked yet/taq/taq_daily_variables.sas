/* ************************************************************************* */
/* ************** W R D S   R E S E A R C H   A P P L I C A T I O N S ****** */
/* ************************************************************************* */
/* Program   : taq_daily_variables.sas                                       */  
/* Date      : Modified Aug, 2011                                            */
/* Author    : Mark Keintz                                                   */
/* ***************************************************************************/

Data v_temp/view=v_temp; 
set taq.ct_1995:  ; /* all ct daily files for year 1995 */
by symbol date; 
where symbol in ('IBM','MSFT','DELL') and time between '09:30:00't and '16:00:00't;
trade_value=price*size;
run; 

proc means data=v_temp noprint; 
by symbol date; 
var price size trade_value;
output out=myresults n=n_trades min=min_price max=max_price sum(size)=volume_daily; 
run;

proc print data=myresults (obs=100);
var symbol date n_trades min_price max_price volume_daily;
run;

/* ********************************************************************************* */
/* *************  Material Copyright Wharton Research Data Services  *************** */
/* ****************************** All Rights Reserved ****************************** */
/* ********************************************************************************* */

