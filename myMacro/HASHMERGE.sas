/*%HASHMERGE - A macro to hash when it can, merge when it can't*/
/*W/i certain limitations there is nothing faster than using the DATA step component objects,*/
/*or "hasing", to merge 2 SAS tables.*/

/*Note) HASH may not work if hashed dataset's size is bigger than the memory size.*/

/*Note) HASH is to merge a smaller dataset with a bigger dataset.*/

%HASHMERGE(data=new, data_a=small, data_b=large, vars_b=largevar1 largevar2, by=keyvar, if=a);

