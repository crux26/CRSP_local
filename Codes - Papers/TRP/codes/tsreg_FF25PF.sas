%macro tsreg_FF25PF(data=, out=, RegkeyVar=);
	proc reg data=&data.
	outest = &out. edf noprint;
	eq1: model s1b1_vwret_1M=mktrf_1m smb_1m hml_1m &RegkeyVar.;	eq2: model s1b2_vwret_1M=mktrf_1m smb_1m hml_1m &RegkeyVar.;	eq3: model s1b3_vwret_1M=mktrf_1m smb_1m hml_1m &RegkeyVar.;	eq4: model s1b4_vwret_1M=mktrf_1m smb_1m hml_1m &RegkeyVar.;	eq5: model s1b5_vwret_1M=mktrf_1m smb_1m hml_1m &RegkeyVar.;
	eq6: model s2b1_vwret_1M=mktrf_1m smb_1m hml_1m &RegkeyVar.;	eq7: model s2b2_vwret_1M=mktrf_1m smb_1m hml_1m &RegkeyVar.;	eq8: model s2b3_vwret_1M=mktrf_1m smb_1m hml_1m &RegkeyVar.;	eq9: model s2b4_vwret_1M=mktrf_1m smb_1m hml_1m &RegkeyVar.;	eq10: model s2b5_vwret_1M=mktrf_1m smb_1m hml_1m &RegkeyVar.;
	eq11: model s3b1_vwret_1M=mktrf_1m smb_1m hml_1m &RegkeyVar.;	eq12: model s3b2_vwret_1M=mktrf_1m smb_1m hml_1m &RegkeyVar.;	eq13: model s3b3_vwret_1M=mktrf_1m smb_1m hml_1m &RegkeyVar.;	eq14: model s3b4_vwret_1M=mktrf_1m smb_1m hml_1m &RegkeyVar.;	eq15: model s3b5_vwret_1M=mktrf_1m smb_1m hml_1m &RegkeyVar.;
	eq16: model s4b1_vwret_1M=mktrf_1m smb_1m hml_1m &RegkeyVar.;	eq17: model s4b2_vwret_1M=mktrf_1m smb_1m hml_1m &RegkeyVar.;	eq18: model s4b3_vwret_1M=mktrf_1m smb_1m hml_1m &RegkeyVar.;	eq19: model s4b4_vwret_1M=mktrf_1m smb_1m hml_1m &RegkeyVar.;	eq20: model s4b5_vwret_1M=mktrf_1m smb_1m hml_1m &RegkeyVar.;
	eq21: model s5b1_vwret_1M=mktrf_1m smb_1m hml_1m &RegkeyVar.;	eq22: model s5b2_vwret_1M=mktrf_1m smb_1m hml_1m &RegkeyVar.;	eq23: model s5b3_vwret_1M=mktrf_1m smb_1m hml_1m &RegkeyVar.;	eq24: model s5b4_vwret_1M=mktrf_1m smb_1m hml_1m &RegkeyVar.;	eq25: model s5b5_vwret_1M=mktrf_1m smb_1m hml_1m &RegkeyVar.;
%mend;
