/*With daily return data, runs a regression on a monthly basis.*/
/*Moving window step: 1 month.*/

/*Below: PERMNO < 10010*/
data dsf_smaller2; set mysas.dsf_smaller2(obs=29663); run; 

proc format;
picture myfmt low-high = '%Y%0m%0d_%0H%0M%0S' (datatype=datetime);
run;

%put timestamp=%sysfunc(datetime(), myfmt.);
%RRLOOP(  data= dsf_smaller2,
			out_ds= result,
			model_equation=ret=mktrf ,
			id=permno , date=date ,
			start_date='01jan2010'd , 
			end_date='31dec2012'd , 
			freq=month, step=1, n=1,
			regprint=noprint,
			minwin=15
				);
%put timestamp=%sysfunc(datetime(), myfmt.);
