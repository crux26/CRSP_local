%let xx=3;
%let x= 7;

data tmp;
y=symget('xx')+1;
z = &x * 2;
run;

%put _user_;
%SYMDEL xx;
%SYMDEL x;
