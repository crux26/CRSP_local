%macro loopEx(data=);
data &data;
set &data;
%do i = 1 to 10;
y = i**2 + i;
output;
run;
%mend loopEx;
