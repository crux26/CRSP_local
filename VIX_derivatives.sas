/*Below to find VIX futures/options.*/
/*candidates: secid=117801, 121518, 152892, 203913, 137566, 137567*/
data _1;
set optionm.securd1;
where issuer contains ("index") or issuer contains ("CBOE");
run;


data _2;
set optionm.indexd;
where indexnam contains ("index") or indexnam contains ("CBOE");
run;

data _3;
set optionm.optionmnames;
where issuer contains ("index") or issuer contains ("CBOE");
run;

data _3_;
set _3;
where issuer contains ("VOLATILITY") or issuer contains ("VIX");
run;

data _4;
set optionm.secnmd;
where issuer contains ("index") or issuer contains ("CBOE");
run;

/*13m (lab)*/
data _;
set opfull.call_cmpt;
where year(date)=2016 and secid in (117801, 121518, 152892, 203913, 137566, 137577);
run;
