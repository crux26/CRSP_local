/*This is for VIX, which uses options with TTM in [23D, 37D].*/
/*_ts2 has a term structure ranging from 1W to 26W, starting from KYTREASNOX=2000064.*/
/*Hence, below is enough.*/
data tfz_dly_ts2; set a_treas.tfz_dly_ts2;
where kytreasnox between 2000066 and 2000069
and caldt between '01jan1996'd and '31dec2015'd;
run;

/*proc sql;*/
/*create table minmax as*/
/*select min(tdduratn) as min_dur, max(tdduratn) as max_dur*/
/*from */
/*tfz_dly_ts2*/
/*group by kytreasnox;*/
/*quit;*/


proc export data=tfz_dly_ts2
outfile = "F:\Dropbox\GitHub\OptionsData\rawdata\tfz_dly_ts2.xlsx"
DBMS = xlsx REPLACE;
run;
