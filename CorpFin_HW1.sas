libname a_index "D:\Dropbox\WRDS\CRSP\sasdata\a_indexes";
libname a_stock "D:\Dropbox\WRDS\CRSP\sasdata\a_stock";
libname a_ccm "D:\Dropbox\WRDS\CRSP\sasdata\a_ccm";
libname a_treas "D:\Dropbox\WRDS\CRSP\sasdata\a_treasuries";
libname comp "D:\Dropbox\WRDS\comp\sasdata\naa";
libname ff "D:\Dropbox\WRDS\ff\sasdata";
libname frb "D:\Dropbox\WRDS\frb\sasdata";
libname mysas "D:\Dropbox\WRDS\CRSP\mysas";
libname myMacro "D:\Dropbox\GitHub\CRSP_local\myMacro";
libname optionm "\\Egy-labpc\WRDS\optionm\sasdata";
libname myOption "D:\Dropbox\WRDS\CRSP\myOption";
libname BEM "D:\Dropbox\GitHub\CRSP_local\Bali, Engle, Murray - replications";
libname ff_repl "D:\Dropbox\WRDS\CRSP\ff_repl";
libname CorpFin "D:\Dropbox\WRDS\CRSP\CorpFin_HW1";
options sasautos=('D:\Dropbox\GitHub\CRSP_local\myMacro\', SASAUTOS) MAUTOSOURCE;

%CRSPMERGE (s=m,START=01JAN2007,END=31DEC2016,
SFVARS=prc ret shrout hexcd, SEVARS=ticker cusip ncusip permco permno exchcd shrcd siccd dlret, OUTSET=CorpFin.crsp_&s._raw);
%CRSPMERGE (s=d,START=01JAN2007,END=31DEC2016,
SFVARS=prc ret shrout hexcd, SEVARS=ticker cusip ncusip permco permno exchcd shrcd siccd dlret, OUTSET=CorpFin.crsp_&s._raw);

proc sort data=CorpFin.crsp_d_raw out=CorpFin.crsp_d; by permno date; run;
proc sort data=CorpFin.crsp_m_raw out=CorpFin.crsp_m; by permno date; run;

/* Stock selection */
%StockSelect(freq=m, datain=CorpFin.crsp_m_raw, dataout=crsp_m_NYSE, picknum=3, filter_exchcd=1);
%StockSelect(freq=m, datain=CorpFin.crsp_m_raw, dataout=crsp_m_NASDAQ, picknum=3, filter_exchcd=3);
%StockSelect(freq=d, datain=CorpFin.crsp_d_raw, dataout=crsp_d_NYSE, picknum=3, filter_exchcd=1);
%StockSelect(freq=d, datain=CorpFin.crsp_d_raw, dataout=crsp_d_NASDAQ, picknum=3, filter_exchcd=3);

/* kurt, skew, normality test stat */
%kurt_skew(datain=crsp_m_NYSE, dataout=crsp_m_NYSE_stat, by=permno, var=ret);
%kurt_skew(datain=crsp_m_NASDAQ, dataout=crsp_m_NASDAQ_stat, by=permno, var=ret);
%kurt_skew(datain=crsp_d_NYSE, dataout=crsp_d_NYSE_stat, by=permno, var=ret);
%kurt_skew(datain=crsp_d_NASDAQ, dataout=crsp_d_NASDAQ_stat, by=permno, var=ret);

/* Portfolio return calculation */
%weighted_ret(datain=crsp_m_NYSE, dataout=crsp_m_NYSE_PF_ret); 
%weighted_ret(datain=crsp_m_NASDAQ, dataout=crsp_m_NASDAQ_PF_ret);
%weighted_ret(datain=crsp_d_NYSE, dataout=crsp_d_NYSE_PF_ret); 
%weighted_ret(datain=crsp_d_NASDAQ, dataout=crsp_d_NASDAQ_PF_ret);

/*-------------------------------------------------------------------------------------------*/
proc univariate data=crsp_m_NYSE_PF_ret noprint normaltest 
outtable=crsp_m_NYSE_PF_ret_stat(keep=_VAR_ _kurt_ _skew_ _normal_ _probn_) ;
var ewret vwret;
run;

proc univariate data=crsp_m_NASDAQ_PF_ret noprint normaltest 
outtable=crsp_m_NASDAQ_PF_ret_stat(keep=_VAR_ _kurt_ _skew_ _normal_ _probn_) ;
var ewret vwret;
run;

proc univariate data=crsp_d_NYSE_PF_ret noprint normaltest 
outtable=crsp_d_NYSE_PF_ret_stat(keep=_VAR_ _kurt_ _skew_ _normal_ _probn_) ;
var ewret vwret;
run;

proc univariate data=crsp_d_NASDAQ_PF_ret noprint normaltest 
outtable=crsp_d_NASDAQ_PF_ret_stat(keep=_VAR_ _kurt_ _skew_ _normal_ _probn_) ;
var ewret vwret;
run;
/*-------------------------------------------------------------------------------------------*/
/*sia: NYSE*/
/*sio: NASDAQ*/
