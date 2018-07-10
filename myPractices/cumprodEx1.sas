/*cumprod by id.*/

data have;
input id $2. month y x z;
datalines;
aa 1 0.5 0.1 0.8
aa 2 3 3 3
aa 3 2 2 2
aa 4 3 3 3
aa 5 2 2 2
aa 6 1 1 1
aa 7 2 2 2
aa 8 2 2 2
aa 9 2 2 2
aa 10 3 3 3
bb 1 5 1 8
bb 2 3 3 3
bb 3 2 2 2
bb 4 3 3 3
bb 5 2 2 2
bb 6 1 1 1
bb 7 2 2 2
bb 8 2 2 2
bb 9 2 2 2
bb 10 3 3 3
;
run;

data want;
set have;
by id;
array products[*] yproduct xproduct zproduct;
retain yproduct xproduct zproduct;
if first.id then do i = 1 to dim(products);  /* Initialise products at start of id */
   products[i] = 1;
   end;
yproduct = yproduct * y;
xproduct = xproduct * x;
zproduct = zproduct * z;
keep id x y x yproduct xproduct zproduct;
run;
