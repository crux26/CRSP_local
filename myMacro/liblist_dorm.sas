%macro liblist_dorm;
libname srv_wrk "F:\WRDS\server_work";
libname a_index "F:\WRDS\CRSP\sasdata\a_indexes";
libname a_stock "F:\WRDS\CRSP\sasdata\a_stock";
libname a_ccm "F:\WRDS\CRSP\sasdata\a_ccm";
libname a_treas "F:\WRDS\CRSP\sasdata\a_treasuries";
libname comp "F:\WRDS\comp\sasdata\naa";
libname ff "F:\WRDS\ff\sasdata";
libname frb "F:\WRDS\frb\sasdata";
libname mysas "F:\WRDS\CRSP\mysas";
libname myOption "F:\WRDS\CRSP\myOption";
libname myMacro "E:\Dropbox\GitHub\CRSP_local\myMacro";
libname optionm "E:\optionm\sasdata";
libname BEM "E:\Dropbox\GitHub\CRSP_local\Bali, Engle, Murray - replications";
libname ff_repl "F:\WRDS\CRSP\ff_repl";
libname VIX "F:\WRDS\cboe\sasdata";
libname myVIX "F:\WRDS\CRSP\myVIX";

/*libname OpFull "F:\WRDS\CRSP\myOption_full";*/
libname OpFull "C:\myOption_full";

libname HighMmt "E:\Dropbox\GitHub\CRSP_local\Codes - Papers\HigherMoments\data";
libname TRP "E:\Dropbox\GitHub\CRSP_local\Codes - Papers\TRP\data";
libname XSREG "F:\WRDS\XSREG\sasdata";
libname ambig "E:\Dropbox\GitHub\CRSP_local\Codes - Papers\ambiguity_premium\data";
libname AHXZ "E:\Dropbox\GitHub\CRSP_local\Codes - Papers\AHXZ_2006\data";
libname Barras "E:\Dropbox\GitHub\CRSP_local\Codes - Papers\Barras_Malkhozov_2016\data";
libname FF92 "E:\Dropbox\GitHub\CRSP_local\Codes - Papers\FF_92\data";
libname myModule "E:\Dropbox\GitHub\CRSP_local\myModule";
libname ibes "F:\WRDS\ibes\sasdata";
libname BBT "E:\Dropbox\GitHub\CRSP_local\Codes - Papers\BBT_2017\data";
libname BBG "E:\Dropbox\GitHub\CRSP_local\Codes - Papers\BBG_2018\data";
libname HW17 "E:\Dropbox\GitHub\CRSP_local\Codes - Papers\HW_2017\sasdata";
libname tfn "F:\WRDS\tfn\sasdata";
libname taq "F:\WRDS\taq\sasdata";

%mend liblist_dorm;
