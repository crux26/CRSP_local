%macro a;
aaaaaa
%mend a;
%macro b;
bbbbbb
%mend b;
%macro c;
cccccc
%mend c;

/* "*" is a delimiter */
/*%SCAN searches for a "word", NOT a "character or letter"*/
%let x=%nrstr(%a*%b*%c);
%put X: &x;
%put The third word in X, with SCAN: %scan(&x,2,*);
%put The third word in X, with QSCAN: %qscan(&x,3,*);
