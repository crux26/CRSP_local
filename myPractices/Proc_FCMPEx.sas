
proc fcmp outlib=sasuser.funcs.trial;
   function study_day(intervention_date, event_date);
      n = event_date - intervention_date;
         if n >= 0 then
            n = n + 1;
         return (n);
   endsub;
run;

options cmplib=sasuser.funcs;
data _null_;
   start = '15Feb2010'd;
   today = '27Mar2010'd;
   sd = study_day(start, today);
   put sd=;
run;

/*Ex.1: Using numeric data in the FUNCTION statement.*/
proc fcmp;
   function inverse(in);
      if in=0 then inv=.;
      else inv=1/in;
      return(inv);
   endsub;
run;

/*Ex.2: Using character data in the FUNCTION statement.*/
options cmplib = work.funcs;

proc fcmp outlib=work.funcs.math;
   function test(x $) $ 12;
   if x = 'yes' then
      return('si si si');
      else
      return('no');
   endsub;
run;

data _null_;
   spanish=test('yes');
   put spanish=;
run;

/*Ex.3: Using variable arguments with an array.*/
options cmplib=sasuser.funcs;

proc fcmp outlib=sasuser.funcs.temp;
function summation (b[*]) varargs;
    total = 0;
    do i = 1 to dim(b);
        total = total + b[i];
    end;
return(total);
endsub;
sum=summation(1,2,3,4,5);
   put sum=;
run;
