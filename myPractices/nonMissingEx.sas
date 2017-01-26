libname myMacro "D:\Dropbox\GitHub\CRSP_local\myMacro";

data have;
input x1-x3;
cards;
1 3 5
2 . 7
3 6 .
4 5 2
5 2 .
;
%put var = x2 x3;

%include myMacro('nonMissing.sas');
%nonMissing(data=want, set=have(keep=x1-x3), var=x2 x3 );
