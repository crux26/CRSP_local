%let a='  DUE DATE';
%let b=left(a);
%put b;
%let d=%eval(10+20);
%let d2=%sysevalf(10.5+20.3);
%let d3=10+30;
%let d4 = "10+30";
%let d5='10+30';

%let a=1+2;
%let b=10*3;
%let c=5/3;
%let eval_a=%eval(&a);
%let eval_b=%eval(&b);
%let eval_c=%eval(&c);
%put &a is &eval_a;
%put &b is &eval_b;
%put &c is &eval_c;

%put _user_;

/*MACRO function works even in DATA step*/
data tmp;
a = %length(&d);
aa = %length(&b);

data abc;
set sashelp.vmacro;
run;

/*Following macro will remove all GLOBAL macro variables*/
%macro delvars;
  data vars;
    set sashelp.vmacro;
  run;
  data _null_;
    set vars;
    if scope='GLOBAL' then
      call execute('%symdel ' ||trim(left(name)) ||' ; ');
  run;
%mend;
%delvars

%put _user_ ;
