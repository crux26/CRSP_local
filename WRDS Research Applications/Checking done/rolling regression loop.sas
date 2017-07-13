/*Checking not done yet. See and compare RRLOOP.sas and RRLOOP2.sas again*/
/* if there's no error remaining.*/

/*regression variable name should be changed*/

%macro RRLOOP (year1= 2001, year2= 2005,  nyear= 2, in_ds=temp1, out_ds=work.out_ds);
  
%local date1 date2 date1f date2f yy mm;
  
/*Extra step to be sure to start with clean, null datasets for appending*/
proc datasets nolist lib=work;
  delete all_ds oreg_ds1;
run;
  
/*Loop for years and months*/
 %do yy = &year1 %to &year2;
   %do mm = 1 %to 12;
  
	 /*Set date2 for mm-yy end point and date1 as 24 months prior*/
	 %let xmonths= %eval(12 * &nyear); *Sample period length in months;
	 %let date2=%sysfunc(mdy(&mm,1,&yy));
	 %let date2= %sysfunc (intnx(month, &date2, 0,end)); *Make the DATE2 last day of the month;
	 %let date1 = %sysfunc (intnx(month, &date2, -&xmonths+1, begin)); *set DATE1 as first (begin) day;
	 /*FYI --- INTNX quirk in SYSFUNC:  do not use quotes with 'month' 'end' and 'begin'*/
	  
	/*An extra step to be sure the loop starts with a clean (empty) dataset for combining results*/
	proc datasets nolist lib=work;
	  delete oreg_ds1;
	run;
	  
	/*Regression model estimation -- creates output set with coefficient estimates*/
	proc reg noprint data=&in_ds outest=oreg_ds1 edf;
	  where date between &date1 and &date2;  *Restricted to DATE1- DATE2 data range in the loop;
	  model retrf = vwretdrf;
	  by permno;
	run;
	  
	/*Store DATE1 and DATE2 as dataset variables
	and rename regression coefficients as ALPHA and BETA;*/
	data oreg_ds1;
	  set oreg_ds1;
	  date1=&date1;
	  date2=&date2;
	  rename intercept=alpha  vwretdrf=beta;
	  nobs= _p_ + _edf_;
	  format date1 date2 yymmdd10.;
	run;
	  
	/*Append loop results to dataset with all date1-date2 observations*/
	proc datasets lib=work;
	  append base=all_ds data=oreg_ds1;
	run;
  
 	%end;  % /*MM month loop*/
  
%end; % /*YY year loop*/
  
/*Save results in final dataset*/
data &out_ds;
  set all_ds;
run;
  
%mend RRLOOP;
