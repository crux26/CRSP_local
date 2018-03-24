%macro AddVar_Nest(alpha=, vlist=, prefix=, postfix=);
	%let nwords=%sysfunc(countw(&vlist));

	%do i=1 %to &nwords;
		%let RegkeyVar = %scan(&vlist, &i);
        %AddVar(RegkeyVar=&RegkeyVar.,
            data=tsreg_&prefix.&RegkeyVar.&alpha.&postfix._, set=tsreg_&prefix.&RegkeyVar.&alpha.&postfix.);
        %end;
%mend AddVar_Nest;
