/*Creating a customized sort order.*/
/*http://support.sas.com/documentation/cdl/en/sqlproc/62086/HTML/default/viewer.htm#a001395751.htm*/

data chores;
	input project $ hours season $;
	cards;
weeding         48  summer  
pruning         12  winter  
mowing          36  summer  
mulching        17  fall    
raking          24  fall    
raking          16  spring  
planting         8  spring  
planting         8  fall    
sweeping         3  winter  
edging          16  summer  
seeding          6  spring  
tilling         12  spring  
aerating         6  spring  
feeding          7  summer  
rolling          4  winter 
;
run;

proc sql;
	title 'Garden Chores by Season in Logical Order';
	select Project, Hours, Season
		from (select Project, Hours, Season,
			case
				when Season = 'spring' then 1
				when Season = 'summer' then 2
				when Season = 'fall' then 3
				when Season = 'winter' then 4
				else .
			end 
		as Sorter
			from chores)
				order by Sorter;
quit;
