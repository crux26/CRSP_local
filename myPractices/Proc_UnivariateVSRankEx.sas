/*PROC UNIVARIATE*/
proc univariate data=beta12M noprint;
	var mktrf;
	by year;
	output out=beta_brkpt pctlpre=beta pctlpts=10 20 40 60 80 90;
run;

data beta_12M_PF;
	merge beta12M beta_brkpt;

	if mktrf < beta10 then
		group=1;
	else if beta10 <= mktrf < beta20 then
		group=2;
	else if beta20 <= mktrf < beta40 then
		group=3;
	else if beta40 <= mktrf < beta60 then
		group=4;
	else if beta60 <= mktrf < beta80 then
		group=5;
	else if beta80 <= mktrf < beta90 then
		group=6;
	else if beta90 <= mktrf then
		group=7;
	by year;
	drop beta:;
run;

/*PROC RANK*/
proc rank data=beta12M out=beta12M_rank percent;
	var mktrf;
	ranks beta_rank;
	by year;
run;

data beta_12M_PF;
	set beta12M_rank;

	if beta_rank <= 10 then
		group=1;
	else if 10 < beta_rank <= 20 then
		group=2;
	else if 20 < beta_rank <= 40 then
		group=3;
	else if 40 < beta_rank <= 60 then
		group=4;
	else if 60 < beta_rank <= 80 then
		group=5;
	else if 80 < beta_rank <= 90 then
		group=6;
	else if 90 < beta_rank then
		group=7;
run;
