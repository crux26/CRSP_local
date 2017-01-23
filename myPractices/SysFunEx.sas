/*%SYSFUNC */
/*Execute SAS functions or user-written functions*/
/*The function cannot be a MACRO function*/

/*However, user-written "macro" functions can be used.*/
/*"MACRO function" denotes functions such as*/
/*%EVAL, %SCAN, %NRSTR, %SYMEXIST, %SYMGLOBL, %SYSEVALF, ...*/

%let dsid=open("Sasuser.Houses","i");

dsid=open("&mydata","&mode");

%let dsid = %sysfunc(open(Sasuser.Houses,i));

%let dsid=%sysfunc(open(&mydata,&mode));

%put _user_;

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

%put _user_;

%put 1 is licensed & 0 is not licensed: %sysprod(qc);
