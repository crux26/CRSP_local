data have; 
input target a b c d e;
cards;
1 1 2 3 0 6
2 1 2 0 0 6
-1 1 2 0 8 16
-2 2 0 0 8 16
5 0 0 0 8 31
6 0 0 2 2 31
1 1 2 0 1 2
run;

%let list=a b c d e;

%macro loop(vlist);
%let nwords=%sysfunc(countw(&vlist));

%do i=1 %to &nwords;
	%do j=&i+1 %to &nwords;
		%put %scan(&vlist, &i) + %scan(&vlist, &j);
	%end;
%end;
%mend;

%loop(&list);
