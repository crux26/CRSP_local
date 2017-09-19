/*Loop repeat*/
data _null_;
    i=1;
loop:
    put i=;

    if i eq 2 then
        goto done;
    i++1;
    goto loop;
done:
    put 'loop-repeat: ' i=;
run;

/*Do while*/
data _null_;
    do while (j < 3);
        put j=;
        j++1;
    end;

    put 'do j: ' j=;
run;

/*Do until*/
data _null_;
    k=1;

    do until(k>=3);
        put k=;
        k++1;
    end;

    put 'do k: ' k=;
run;

/*Do iterate*/
data _null_;
    l=0;

    do l=1 to 2;
        put l=;
    end;

    put 'do l: ' l=;
run;
