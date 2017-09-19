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
