libname a_stock "E:\Dropbox\GitHub\OptionsData\data\a_stock";

data a_stock.msenames_0;
    set a_stock.msenames;
    keep cusip exchcd namedt nameendt;
run;

proc contents data=a_stock.msenames_0;
run;

