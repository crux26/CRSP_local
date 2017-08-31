/* ODS OUTPUT of ParamEstimates: EstType, Parameter, Estimate, StdErr, tValue, Probt, DF. */
/* --> Seems there's no way to retrieve p-value, t-value but to use ODS OUTPUT. */
/* SAS wouldn't give it by default. */
/*(SEE <https://communities.sas.com/t5/SAS-Statistical-Procedures/output-p-value-and-t-statistics/td-p/79399> for this.)*/


data msf; set a_stock.msf; 
where date between '01Jan2001'd and '31Dec2006'd
and permno between 10000 and 20000;
run;

/*---------------------WITH ODS OUTPUT-----------------------*/
/* Note that w/ and w/o ODS OUTPUT prints different results. */

ods listing close; ods html close;

proc model data=msf ;
/* OUTPARMS=: All the parameter estimates. */
/* PARMSDATA=: names the SAS data set that contains the parameter estimates. */
	instruments const;
	ret=const;
	fit ret/gmm kernel=(bart,3,0);
	ods output ParameterEstimates = _params ResidSummary= _resid; 
	/* ParameterEstimates include: EstType, Parameter, Estimate, StdErr, tValue, Probt, DF. */
	/* ResidSummary include: Equation, ModelDF, ERrorDF, SS, MS, RMSE, RSquare, AdjRSq, Label. */
	quit;
ods listing; ods html;


/*-------------------------NO ODS OUTPUT--------------------------------*/
proc model data=msf noprint outparms=_result;
/* OUTPARMS=: All the parameter estimates. */
/* PARMSDATA=: names the SAS data set that contains the parameter estimates. */
	instruments const;
	ret=const;
	fit ret/gmm kernel=(bart,3,0) out=_out0 outest=_out1 outs=_out2 outused=_out3 outv=_out4 ;
/* OUT=: residuals, actuals, and predicted values of DEPVAR. */
/* OUTEST=: parameter estimates (covariance estimates of parameter estimates as well if requested). */
/* OUTS=: estimate of the covariance matrix of the residuals across equations. */
/* OUTUSED=: covariance matrix of the residuals across equations used to define the objective function. */
/* OUTV=: estimate of the variance matrix. */
quit;

/*-------------------------------------------------------------------------------------------------------------------------------------------------------------------*/
/*--------------------------------------------BELOW from '?????? HW1 - SDF via GMM'---------------------------------------------------------*/
/*-------------------------------------------------------------------------------------------------------------------------------------------------------------------*/
proc model data = raw_data ;			* GMM part;

parms a b s h;
*exogenous Mkt_RF SMB HML;
SDF = a + (b * Mkt_RF) + (s * SMB) + (h * HML);

eq.m1 = SDF * (SMALL_LoBM) - 1;  eq.m2 = SDF * (ME1_BM2) - 1;  eq.m3 = SDF * (ME1_BM3) - 1;  eq.m4 = SDF * (ME1_BM4) - 1;  eq.m5 = SDF * (SMALL_HiBM) - 1;
eq.m6 = SDF * (ME2_BM1) - 1;  eq.m7 = SDF * (ME2_BM2) - 1;  eq.m8 = SDF * (ME2_BM3) - 1;  eq.m9 = SDF * (ME2_BM4) -1;  eq.m10 = SDF * (ME2_BM5) - 1;
eq.m11 = SDF * (ME3_BM1) - 1;  eq.m12 = SDF * (ME3_BM2) - 1;  eq.m13 = SDF * (ME3_BM3) - 1;  eq.m14 = SDF * (ME3_BM4) - 1;  eq.m15 = SDF * (ME3_BM5) - 1;
eq.m16 = SDF * (ME4_BM1) - 1;  eq.m17 = SDF * (ME4_BM2) - 1;  eq.m18 = SDF * (ME4_BM3) - 1;  eq.m19 = SDF * (ME4_BM4) - 1;  eq.m20 = SDF * (ME4_BM5) - 1;
eq.m21 = SDF * (BIG_LoBM) - 1; eq.m22 = SDF * (ME5_BM2) - 1; eq.m23 = SDF * (ME5_BM3) - 1; eq.m24 = SDF * (ME5_BM4) - 1; eq.m25 = SDF * (BIG_HiBM) - 1;

	fit m1 m2 m3 m4 m5 m6 m7 m8 m9 m10 m11 m12 m13 m14 m15 m16 m17 m18 m19 m20 m21 m22 m23 m24 m25 
		/  gmm KERNEL = (BART,13,0) SDATA = Identity_Matrix OUTS = GMM_OUTS MAXITER = 100 NOPRINT ; *OUTV=GMM_Var ; *NOPRINT ; *PRINTALL;  *NO2SLS;
run;

fit m1 m2 m3 m4 m5 m6 m7 m8 m9 m10 m11 m12 m13 m14 m15 m16 m17 m18 m19 m20 m21 m22 m23 m24 m25 
		/  gmm KERNEL = (BART,13,0) out = GMM_2stage outest = GMM_2stage_est SDATA=GMM_OUTS OUTS = GMM_OUTS2 MAXITER = 100 ; *PRINTALL;  *2SLS;

		test b ,/ WALD LR LM;
		test s ,/ WALD LR LM;
		test h ,/ WALD LR LM;
		test s,h ,/ WALD LR LM;  * tests whether parameters are jointly equal to 0 ;
run;




