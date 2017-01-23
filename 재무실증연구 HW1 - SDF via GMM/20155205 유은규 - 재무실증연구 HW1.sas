proc import  datafile = "E:\Downloads\25_Portfolios_5x5_CSV\25_Portfolios_5x5.csv" out = raw_portfolio_data dbms = csv; run;
proc import  datafile = "E:\Downloads\F-F_Research_Data_Factors_CSV\F-F_Research_Data_Factors.csv" out = raw_factor_data dbms = csv; run;
proc import  datafile = "E:\Downloads\Ret_Squared.xlsx" out = Return_Squared dbms = xlsx; run;
proc import  datafile = "E:\Downloads\Identity_Matrix.xlsx" out = Identity_Matrix dbms = xlsx; run;

data raw_data; 
merge raw_portfolio_data raw_factor_data;
run;


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


proc print data = GMM_OUTS2;
run;

proc print data = GMM_2stage_est;  * outest =GMM_2stage_est contains parameter estimation results only;
run;

proc means data = GMM_2stage N MEAN STD VAR T PRT VARDEF = DF;

 OUTPUT OUT= descriptive_stat_GMM_2stage N= MEAN= T= PRT= /autoname;

* T 		:	Hypotheses T-test;
* PRT	:	P-value of T-statistics;
* VAR	: 	Variance;
run;


*//////////////////////////////  Hansen-Jagannathan distance part  /////////////////////////////////////////;


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
		/  gmm KERNEL = (BART,13,0) SDATA = Return_Squared OUTS = GMM_Ret_Sq_OUTS MAXITER = 100 NOPRINT ; *OUTV=GMM_Var ; *NOPRINT ; *PRINTALL;  *NO2SLS;
run;

fit m1 m2 m3 m4 m5 m6 m7 m8 m9 m10 m11 m12 m13 m14 m15 m16 m17 m18 m19 m20 m21 m22 m23 m24 m25 
		/  gmm KERNEL = (BART,13,0) out = GMM_2stage_Ret_Sq outest = GMM_2stage_Ret_Sq_est SDATA = GMM_Ret_Sq_OUTS OUTS = GMM_Ret_Sq_OUTS2 MAXITER = 100 ; *PRINTALL;  *2SLS;

		test b ,/ WALD LR LM;
		test s ,/ WALD LR LM;
		test h ,/ WALD LR LM;
		test s,h ,/ WALD LR LM;  * tests whether parameters are jointly equal to 0 ;
run;

proc print data = GMM_Ret_Sq_OUTS2;
run;

proc print data = GMM_2stage_Ret_Sq_est;  * outest =GMM_2stage_est contains parameter estimation results only;
run;


proc means data = GMM_2stage_Ret_Sq N MEAN STD VAR T PRT VARDEF = DF;

 OUTPUT OUT= des_stat_GMM_2stage_Ret_Sq N= MEAN= T= PRT= /autoname;

* T 		:	Hypotheses T-test;
* PRT	:	P-value of T-statistics;
* VAR	: 	Variance;
run;
