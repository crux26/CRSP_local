%macro tsreg_LoopOnExret_Nest_RV(alpha=, DepVarList=, IndepVarList=, data= );
	%let nwords=%sysfunc(countw(&IndepVarList));
	%do i1=1 %to &nwords;
		%let IndepVar = %scan(&IndepVarList, &i1);
		%put &=IndepVar;
		%put &=DepVarList;
	    %tsreg_LoopOnExret_RV(DepVarList=&DepVarList.., IndepVar=&IndepVar., data=&data., out=TRP.tsreg_exret_&IndepVar.RV_&alpha.);
	%end;
%mend tsreg_LoopOnExret_Nest_RV;
