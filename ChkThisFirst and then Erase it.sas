data mysas.tmp1;
set mysas.bm_comp_crsp;
where not missing(ffi10);
run;

proc means data=mysas.bm_comp_crsp noprint;
	class calyear ffi&ind._desc;
	var bm_comp bm_crsp;
	where not missing(ffi&ind);
	output out=mysas.medians11 median=/autoname;
run;


proc means data=mysas.bm_comp_crsp noprint;
	class calyear ffi10_desc;
	var bm_comp bm_crsp;
	where not missing(ffi10);
	output out=mysas.medians11 median=/autoname;
run;
