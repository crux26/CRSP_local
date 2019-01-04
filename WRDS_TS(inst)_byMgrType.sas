/* ********************************************************************************* */
/* ************** W R D S   R E S E A R C H   A P P L I C A T I O N S ************** */
/* ********************************************************************************* */
/* Summary   : Construct Time Series of the Number of Institutions by Manager Type   */
/* Date      : May 18, 2009                                                          */
/* Author    : Rabih Moussawi and Luis Palacios                                      */
/* Variables : - INPUT : s34type1 dataset                                            */
/*             - OUTPUT: Frequency dataset                                           */
/* ********************************************************************************* */
 
/* Read S34type1 Dataset, with Holdings Report Date (RDATE) and TYPECODE Information */
/* FDATE is the Vintage Date; TR-13F carries forward stale data for up to 8 quarters */
libname tfn "/wrds/tfn/sasdata/s34";
proc means noprint data=tfn.s34type1 (where= (rdate=fdate));
class rdate typecode;
var mgrno;
output out=InstCounts (where=( _TYPE_=3)) n=numero;
run;  /* _TYPE_=3 identifies the summary by both rdate and typecode variables */
 
/* Transpose Frquencies into 5 Variables for Better Presentation */
proc transpose data=InstCounts (drop= _TYPE_ _FREQ_) out=TimeSeries
(drop=_name_ _label_
rename = (
  _1 = Bank
  _2 = Insurance
  _3 = Mutual_Funds
  _4 = Investment_Advisors
  _5 = Others
          )
);
var numero;
by rdate;
id typecode;
run;
 
/* Final Table for Presentation with Grand Total */
data TimeSeries;
set TimeSeries;
Total = sum(bank,insurance,mutual_funds,investment_advisors,others);
format rdate yyqp6. total comma.;
label rdate = "Effective Report Date, Year.Quarter";
run;
 
/* Print Results; Only at Year End */
proc print data=TimeSeries noobs;
Title 'Time Series of the Number of Institutions by Manager Type';
where month(rdate)=12; format rdate year.;
run;
 
/* Plot Results */
symbol interpol =join w = 4;
proc gplot data =TimeSeries; format rdate year.;
Title 'Time Series of the Number of Institutions by Manager Type' ;
plot (Total bank insurance mutual_funds investment_advisors others)*rdate / overlay legend;
run;
quit;
 
/* End */
 
/* ********************************************************************************* */
/* *************  Material Copyright Wharton Research Data Services  *************** */
/* ****************************** All Rights Reserved ****************************** */
/* ********************************************************************************* */
