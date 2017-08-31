/* varlist, a global macro variable, contains variable names (or column names) of a given dataset. */

%macro varnames(dsid, varlist);
/*------------------------------------------------------------------------------------------------------*/
/* Overwriting GLOBAL macro variable not allowed, so deleting it before defining GLOBAL macro variable. */
  data vars; set sashelp.vmacro; run;
  data _null; set vars;
  if scope='GLOBAL' and name='&varlist' then call execute('%symdel ' || trim(left(name))|| ';');
  run;
/*------------------------------------------------------------------------------------------------------*/
  %global &varlist;
  %let dsid=%sysfunc(open(&dsid, i));
  %let num=%sysfunc(attrn(&dsid,nvars));
  %let &varlist=;
  %do i=1 %to &num  ;
    %let &varlist=&&&varlist %sysfunc(varname(&dsid, &i));
  %end;
  %put &varlist=&&&varlist;
%mend varnames;
