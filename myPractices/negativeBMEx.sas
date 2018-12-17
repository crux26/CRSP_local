/*bm_comp<0 results from mcap_c, mcap_dec<0.*/
/*prcc_c<0, prcc_f>0, prccm>0 case. Note that datdate differs.*/

/*bm_comp>>>0 due to csho=-0.000 or 0.000.*/

data have;
	set bm_comp;
	keep gvkey datadate prcc_c prcc_f csho be bm_comp;

	if ~missing(bm_comp) and bm_comp<0 then
		output;
run;

/**/

data have0;
set comp.secm(where=(gvkey='001258'));
keep gvkey datadate prccm cshom cshoq;
run;

/**/
