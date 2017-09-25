/*SAS - Snell, Sugi 31, <Think Fast! ...>*/

data sequential; set sashelp.class; put _all_; output; run;
/*Records read sequentially from top to bottom (as one can see by the sequence of _N_). */

data direct; do i=2,3,9; set sashelp.class point=i; put _all_; output; end; stop; run;
/*Direct access is the concept of reading specific records from a table in no particular order.*/
/*For this, you must specify which row(s) to read.*/
