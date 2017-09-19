/* Delete all user-defined macro variables */
/* http://support.sas.com/documentation/cdl/en/mcrolref/69726/HTML/default/viewer.htm#p0j1htu10wsx9tn1mig5g0b8mxxb.htm */
%macro delvars;
  data vars;
    set sashelp.vmacro;
  run;

  data _null_;
    set vars;
    temp=lag(name);
    if scope='GLOBAL' and substr(name,1,3) ne 'SYS' and temp ne name then
      call execute('%symdel '||trim(left(name))||';');
  run;

%mend delvars;

