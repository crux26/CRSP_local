data want; set have;
array var (*) var1-var3;
var1 = 3;
var2 = 55;
run;
/*var3 is missing*/
