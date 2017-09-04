%macro autocorr(datain=, dataout=);

data tmp0; set &datain;
lag_abnormal_vwret = lag(abnormal_vwret);
lag2_abnormal_vwret = lag2(abnormal_vwret);
lag3_abnormal_vwret = lag3(abnormal_vwret);
lag4_abnormal_vwret = lag4(abnormal_vwret);
lag5_abnormal_vwret = lag5(abnormal_vwret);
lag6_abnormal_vwret = lag6(abnormal_vwret);

lag_abnormal_ewret = lag(abnormal_ewret);
lag2_abnormal_ewret = lag2(abnormal_ewret);
lag3_abnormal_ewret = lag3(abnormal_ewret);
lag4_abnormal_ewret = lag4(abnormal_ewret);
lag5_abnormal_ewret = lag5(abnormal_ewret);
lag6_abnormal_ewret = lag6(abnormal_ewret);
run;

proc autoreg data=tmp0 outest=&dataout;
model abnormal_vwret = lag_abnormal_vwret lag2_abnormal_vwret lag3_abnormal_vwret lag4_abnormal_vwret lag5_abnormal_vwret lag6_abnormal_vwret / dw=6 dwprob noprint;
run;

%mend autocorr;
