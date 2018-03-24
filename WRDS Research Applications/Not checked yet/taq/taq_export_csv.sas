/* ************************************************************************* */
/* ************** W R D S   R E S E A R C H   A P P L I C A T I O N S ****** */
/* ************************************************************************* */
/* Program   : taq_export_cvs.sas                                            */
/* Date      : Modified Aug, 2011                                            */
/* Author    : Mark Keintz                                                   */
/* ***************************************************************************/

/* SAS Program to Export a TAQ dataset to comma-delimited file */
/* Usage in UNIX: sas export_cq.sas -noterminal */
/* Note: You must use the "-noterminal" option because we're using "proc export" */
/* If you are processing a large file (>20 GB) then please run it in the background */
/* so that even if your SSH program disconnects, the program would keep running. */
/* Usage: nohup sas export_cq.sas -noterminal & */
/*        ps -ef |grep &lt;your username&gt;   to see if your program is still running */



/* Name of the TAQ files to export into comma-delimited format */

%let tables=CQ_199301 ; * all January 1993 cq files;

data  _v_&tables / view=_v_&tables ;
  set taq.&tables : ; * * the command ':' ask SAS to retrieve all January 1993 cq files;
  keep symbol date time price;
run;

proc export data=_v_&tables outfile=csv_mydata dbms=csv replace;
run;

/* ********************************************************************************* */
/* *************  Material Copyright Wharton Research Data Services  *************** */
/* ****************************** All Rights Reserved ****************************** */
/* ********************************************************************************* */

