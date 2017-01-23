/****************************************************************/ 
/*          S A S   S A M P L E   L I B R A R Y                 */ 
/*                                                              */ 
/*    NAME: CORREX1                                             */ 
/*   TITLE: Documentation Example 1 for PROC CORR               */ 
/* PRODUCT: BASE                                                */ 
/*  SYSTEM: ALL                                                 */ 
/*    KEYS: correlation analysis                                */ 
/*   PROCS: CORR                                                */ 
/*    DATA:                                                     */ 
/*                                                              */ 
/* SUPPORT: Yang Yuan             UPDATE: Aug 21, 2007          */ 
/*     REF: PROC CORR, EXAMPLE 1                                */ 
/*    MISC:                                                     */ 
/****************************************************************/ 
 
*----------------- Data on Physical Fitness -----------------* 
| These measurements were made on men involved in a physical | 
| fitness course at N.C. State University.                   | 
| The variables are Age (years), Weight (kg),                | 
| Runtime (time to run 1.5 miles in minutes), and            | 
| Oxygen (oxygen intake, ml per kg body weight per minute)   | 
| Certain values were changed to missing for the analysis.   | 
*------------------------------------------------------------*; 
data Fitness; 
   input Age Weight Oxygen RunTime @@; 
   datalines; 
44 89.47 44.609 11.37    40 75.07 45.313 10.07 
44 85.84 54.297  8.65    42 68.15 59.571  8.17 
38 89.02 49.874   .      47 77.45 44.811 11.63 
40 75.98 45.681 11.95    43 81.19 49.091 10.85 
44 81.42 39.442 13.08    38 81.87 60.055  8.63 
44 73.03 50.541 10.13    45 87.66 37.388 14.03 
45 66.45 44.754 11.12    47 79.15 47.273 10.60 
54 83.12 51.855 10.33    49 81.42 49.156  8.95 
51 69.63 40.836 10.95    51 77.91 46.672 10.00 
48 91.63 46.774 10.25    49 73.37   .    10.08 
57 73.37 39.407 12.63    54 79.38 46.080 11.17 
52 76.32 45.441  9.63    50 70.87 54.625  8.92 
51 67.25 45.118 11.08    54 91.63 39.203 12.88 
51 73.71 45.790 10.47    57 59.08 50.545  9.93 
49 76.32   .      .      48 61.24 47.920 11.50 
52 82.78 47.467 10.50 
; 
 
 
ods graphics on; 
title 'Measures of Association for a Physical Fitness Study'; 
proc corr data=Fitness pearson spearman kendall hoeffding noprint;
/*          plots=matrix(histogram); */
/*   var Weight Oxygen RunTime; */
run; 
ods graphics off; 
