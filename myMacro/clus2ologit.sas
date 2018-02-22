/*From http://acct.wharton.upenn.edu/~dtayl/code.htm.*/

/**************************************************************************************************/
/*   Ordered Logit with two-way cluster-robust SEs, z-stats, and p-values   */
/**************************************************************************************************/

%MACRO clus2ologit(data, out, yvar, xvars, cluster1, cluster2);
    options nonotes nosource;
    ods listing close;
    ods exclude all;
    ods graphics off;
	/* do interesection cluster*/
	proc surveylogistic data=&data; class &yvar /descending; cluster &cluster1 &cluster2; model &yvar= &xvars /link=clogit covb; ods output CovB = CovI; quit;
	/* Do first cluster */
	proc surveylogistic data=&data; class &yvar /descending; cluster &cluster1; model &yvar= &xvars /link=clogit covb; ods output CovB = Cov1; quit;
	/* Do second cluster */
	proc surveylogistic data=&data; class &yvar /descending; cluster &cluster2; model &yvar= &xvars /link=clogit covb; ods output CovB = Cov2 ParameterEstimates = params (drop=df); quit;

	/*	Now get the covariances numbers created above. Calc coefs, SEs, t-stats, p-vals	using COV = COV1 + COV2 - COVI*/
	proc iml; reset noprint; use params;
		read all var{variable} into varnames;
		read all var _all_ into b;
		use Cov1; read all var _num_ into x1;
	 	use Cov2; read all var _num_ into x2;
	 	use CovI; read all var _num_ into x3;

		cov = x1 + x2 - x3;	/* Calculate covariance matrix */
		dfe = b[1,3]; stdb = sqrt(vecdiag(cov)); beta = b[,1]; z = beta/stdb; prob = 1-probf(z#z,1,dfe); /* Calc stats */
	
		print,"Parameter estimates",,varnames beta[format=8.4] stdb[format=8.4] z[format=8.4] prob[format=8.4];

		  conc =    beta || stdb || z || prob;
  		  cname = {"estimates" "stderror" "zstat" "pvalue"};
  		  create clus2dstats from conc [ colname=cname ];
          append from conc;

		  conc =   varnames;
  		  cname = {"varnames"};
  		  create names from conc [ colname=cname ];
          append from conc;
	quit;

	data &out; merge names clus2dstats; run;
    options notes source;
    ods listing ;
    ods exclude none;
    ods graphics;
%MEND clus2ologit;

/*%clus2ologit(data=ds_in, out=clus2ologit, yvar=dependentvariable, xvars=listofindependentvariables, cluster1=gvkey, cluster2=fyear);*/
