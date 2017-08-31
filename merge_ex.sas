/* Below from DGTW.sas */
/* Add Historical PERMCO identifier */

/* Add Historical PERMCO identifier */
proc sql;
  create table comp2
  as select a.*, b.lpermco as permco, b.linkprim
/*LINKPRIM: Primary issue marker for the link. P, J, C, N.*/
  from comp1 as a, a_ccm.ccmxpf_linktable as b
  where a.gvkey = b.gvkey and
  b.LINKTYPE in ("LU","LC") and
/* LC: Link research complete. Standard connection between databases */
/* LU: Unresearched link to issue by CUSIP */
/*LINKTYPE: LC, LU, LX, LD, LN, LS, NR, NU*/
 (b.LINKDT <= a.datadate) and (a.datadate <= b.LINKENDDT or missing(b.LINKENDDT));
/*LINKDT: first effective date of the current link*/
/*LINKENDDT: last effective date of the current link record. If the name represents the current link info.,*/
/*the LINKENDDT is set to 99,999,999*/
quit;
/*--------------------------------------------------------------------------------------------*/
/* Below from market_to_book.sas */

/* Step 3b. Alternatively, one can use Market value from CRSP as of  */
/* Dec end of fiscal year. Note that this will restrict the sample   */
/* to CRSP stocks only                                               */
/* Select Compustat's SICH as primary SIC code, if not available     */
/* then use CRSP's historical SICCD                                  */
proc sql; create table mysas.bm_comp_crsp
  as select a.*, b.lpermno as permno,
			b.lpermco as permco, 
          	((a.be>0)*a.be) / (abs(c.prc*c.shrout)/1000 ) as bm_crsp, 
          	coalesce(a.sich,d.siccd) as sic
   from mysas.bm_comp a left join &crsp..ccmxpf_linktable b
/*CCM is used here for merge*/
   on a.gvkey=b.gvkey and b.linkdt<=a.datadate and b.usedflag=1
   and linkprim in ('P','C')
   and (a.datadate<=b.linkenddt or missing(b.linkenddt)) 
   
  /* market value from CRSP as the Dec end of fiscal year end*/
  left join &crsp..msf (keep=permno date prc shrout) c 
  /*dsf is more than needed as Dec end is the only relevant*/

/*put(source,format) returns character, converting source into specified format*/
/*input(source,format) returns numeric*/
  on b.lpermno=c.permno and put(a.fyear_end, yymmn6.) = put(c.date, yymmn6.)
  /*Merge in historical SIC code from CRSP*/
  left join (select distinct permno, siccd, min(namedt) as mindate, 
          max(nameenddt) as maxdate
          from &crsp..stocknames group by permno, siccd) d
  on b.lpermno=d.permno and d.mindate<=a.fyear_end<=d.maxdate
  order by a.gvkey, a.datadate, sic;
quit;
