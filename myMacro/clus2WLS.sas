/*From http://acct.wharton.upenn.edu/~dtayl/code.htm.*/


/******************************************************************************************/
/*   WLS (Weighted-Least-Squares) with two-way cluster-robust SEs, t-stats, and p-values  */
/******************************************************************************************/

%MACRO clus2WLS(data, out, yvar, xvars, weights, cluster1, cluster2);
    options nonotes nosource;
    ods listing close;
    ods exclude all;
    ods graphics off;
	/* do interesection cluster*/
	proc surveyreg data=&data; weight &weights; cluster &cluster1 &cluster2; model &yvar= &xvars /  covb; ods output CovB = CovI; quit;
	/* Do first cluster */
	proc surveyreg data=&data; weight &weights; cluster &cluster1; model &yvar= &xvars /  covb; ods output CovB = Cov1; quit;
	/* Do second cluster */
	proc surveyreg data=&data; weight &weights; cluster &cluster2; model &yvar= &xvars /  covb; ods output CovB = Cov2 ParameterEstimates = params;	quit;

	/*	Now get the covariances numbers created above. Calc coefs, SEs, t-stats, p-vals	using COV = COV1 + COV2 - COVI*/
	proc iml; reset noprint; use params;
		read all var{Parameter} into varnames;
		read all var _all_ into b;
		use Cov1; read all var _num_ into x1;
	 	use Cov2; read all var _num_ into x2;
	 	use CovI; read all var _num_ into x3;

		cov = x1 + x2 - x3;	/* Calculate covariance matrix */
		dfe = b[1,3]; stdb = sqrt(vecdiag(cov)); beta = b[,1]; t = beta/stdb; prob = 1-probf(t#t,1,dfe); /* Calc stats */

		print,"Parameter estimates",,varnames beta[format=8.4] stdb[format=8.4] t[format=8.4] prob[format=8.4];

		  conc =    beta || stdb || t || prob;
  		  cname = {"estimates" "stderror" "tstat" "pvalue"};
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
%MEND clus2WLS;

/*%clus2WLS(data=ds, out=clus2WLS, yvar=dependentvariable, xvars=listofindependentvariables, weights=firmsize, cluster1=gvkey, cluster2=fyear);*/
