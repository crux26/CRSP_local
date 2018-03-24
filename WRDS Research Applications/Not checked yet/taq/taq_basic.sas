/* ************************************************************************* */
/* ************** W R D S   R E S E A R C H   A P P L I C A T I O N S ****** */
/* ************************************************************************* */
/* Program   : TAQ basic       						                         */
/* Date      : Modified Aug, 2011                                            */
/* Author    : Mark Keintz	                            		             */
/* ***************************************************************************/

options msglevel=I;   /* Ask SAS to report when indexes are being used */

data out_sample;
     set taq.ct_199303:  open=defer; /* reads all daily files for March 1993 */
	 /* The trailing colon (":") tells SAS to read all daily datasets whose name begins with ct_199303. */
	 /* It's a great way to easily avoid non-trading dates (e.g. Saturdays and Sundays). */
	 /* The "open=defer" tells SAS to not bother making memory buffer space for every incoming */ 
	 /* data set, but to use one buffer space for each data set in succession. */
     /* It saves memory and time. */
     where symbol in ('IBM', 'F') and time between '09:30:00't and '16:00:00't  ; 
run;

proc print data=out_sample(obs=20); run;

/* ********************************************************************************* */
/* *************  Material Copyright Wharton Research Data Services  *************** */
/* ****************************** All Rights Reserved ****************************** */
/* ********************************************************************************* */

