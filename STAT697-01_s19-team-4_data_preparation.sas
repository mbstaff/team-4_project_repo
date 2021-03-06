*******************************************************************************;
**************** 80-character banner for column width reference ***************;
* (set window width to banner width to calibrate line length to 80 characters *;
*******************************************************************************;

* 
[Dataset 1 Name] frpm1516
[Dataset Description] Student Poverty Free or Reduced Price Meals (FRPM) Data, 
AY2015-16
[Experimental Unit Description] California public K-12 schools in AY2015-16
[Number of Observations] 10,453
                    
[Number of Features] 28
[Data Source] The file http://www.cde.ca.gov/ds/sd/sd/documents/frpm1516.xls
was downloaded and edited to produce file frpm1415-edited.xls by deleting
worksheet "Title Page", deleting row 1 from worksheet "FRPM School-Level Data",
reformatting column headers in "FRPM School-Level Data" to remove characters
disallowed in SAS variable names, and setting all cell values to "Text" format
[Data Dictionary] http://www.cde.ca.gov/ds/sd/sd/fsspfrpm.asp
[Unique ID Schema] The columns "County Code", "District Code", and "School 
Code"form a composite key, which together are equivalent to the unique id 
column CDS_CODE in dataset dropouts17, and which together are also equivalent 
to the unique id column CDS in dataset act17.
;
%let inputDataset1DSN = frpm1516_raw;
%let inputDataset1URL =
https://github.com/stat697/team-4_project_repo/blob/master/data/frpm1516_edited.xls?raw=true
;
%let inputDataset1Type = XLS;


*
[Dataset 2 Name] frpm1617
[Dataset Description] Student Poverty Free or Reduced Price Meals (FRPM) Data,
AY2016-17
[Experimental Unit Description] California public K-12 schools in AY2016-17
[Number of Observations] 10,478
                    
[Number of Features] 28
[Data Source] The file http://www.cde.ca.gov/ds/sd/sd/documents/frpm1617.xls
was downloaded and edited to produce file frpm1415-edited.xls by deleting
worksheet "Title Page", deleting row 1 from worksheet "FRPM School-Level Data",
reformatting column headers in "FRPM School-Level Data" to remove characters
disallowed in SAS variable names, and setting all cell values to "Text" format
[Data Dictionary] http://www.cde.ca.gov/ds/sd/sd/fsspfrpm.asp
[Unique ID Schema] The columns "County Code", "District Code", and "School 
Code" form a composite key, which together are equivalent to the unique id 
column CDS_CODE in dataset dropouts17, and which together are also equivalent 
to the unique id column CDS in dataset act17.
;
%let inputDataset2DSN = frpm1617_raw;
%let inputDataset2URL =
https://github.com/stat697/team-4_project_repo/blob/master/data/frpm1617_edited.xls?raw=true
;
%let inputDataset2Type = XLS;


*
[Dataset 3 Name] dropouts17
[Dataset Description] Grade seven through twelve dropouts and enrollment by 
race/ethnic designation and gender by school, AY2016-17
[Experimental Unit Description] California public K-12 schools in AY2016-17
[Number of Observations] 59,599  
 
[Number of Features] 20
[Data Source] The file
http://dq.cde.ca.gov/dataquest/dlfile/dlfile.aspx?cLevel=School&cYear=2016-17&cCat
=Dropouts&cPage=filesdropouts was downloaded and edited to produce file gradaf15.xls
by importing into Excel and setting all cell values to "Text" format
[Data Dictionary] https://www.cde.ca.gov/ds/sd/sd/fsdropouts.asp
[Unique ID Schema] The column CDS_CODE is a unique id.
;
%let inputDataset3DSN = dropouts17_raw;
%let inputDataset3URL =
https://github.com/stat697/team-4_project_repo/blob/master/data/dropouts17.xls?raw=true
;
%let inputDataset3Type = XLS;


*
[Dataset 4 Name] act17
[Dataset Description] ACT Test Results, AY2016-17
[Experimental Unit Description] California public K-12 schools in AY2016-17
[Number of Observations] 2,252 
 
[Number of Features] 16
[Data Source] The file http://www3.cde.ca.gov/researchfiles/satactap/act17.xls
was downloaded and edited to produce file act17-edited.xls by opening in Excel
and setting all cell values to "Text" format
[Data Dictionary] https://www.cde.ca.gov/ds/sp/ai/reclayoutact17.asp
[Unique ID Schema] The column CDS is a unique id.
;
%let inputDataset4DSN = act17_raw;
%let inputDataset4URL =
https://github.com/stat697/team-4_project_repo/blob/master/data/act17_edited.xls?raw=true
;
%let inputDataset4Type = XLS;


* set global system options;
options fullstimer;


* load raw datasets over the wire, if they doesn't already exist;
%macro loadDataIfNotAlreadyAvailable(dsn,url,filetype);
    %put &=dsn;
    %put &=url;
    %put &=filetype;
    %if
        %sysfunc(exist(&dsn.)) = 0
    %then
        %do;
            %put Loading dataset &dsn. over the wire now...;
            filename
                tempfile
                "%sysfunc(getoption(work))/tempfile.&filetype."
            ;
            proc http
                method="get"
                url="&url."
                out=tempfile
                ;
            run;
            proc import
                file=tempfile
                out=&dsn.
                dbms=&filetype.;
            run;
            filename tempfile clear;
        %end;
    %else
        %do;
            %put Dataset &dsn. already exists. Please delete and try again.;
        %end;
%mend;
%macro loadDatasets;
    %do i = 1 %to 4;
        %loadDataIfNotAlreadyAvailable(
            &&inputDataset&i.DSN.,
            &&inputDataset&i.URL.,
            &&inputDataset&i.Type.
        )
    %end;
%mend;
%loadDatasets


* check frpm1516_raw for bad unique id values, where the columns County_Code,
District_Code, and School_Code are intended to form a composite key;
proc sql;
    /* check for duplicate unique id values; after executing this query, we
       see that frpm1516_raw_dups only has one row, which just happens to 
       have all three elements of the componsite key missing, which we can
       mitigate as part of eliminating rows having missing unique id component
       in the next query */
    create table frpm1516_raw_dups as
        select
             County_Code
            ,District_Code
            ,School_Code
            ,count(*) as row_count_for_unique_id_value
        from
            frpm1516_raw
        group by
             County_Code
            ,District_Code
            ,School_Code
        having
            row_count_for_unique_id_value > 1
    ;
    /* remove rows with missing unique id components, or with unique ids that do
	   not correspond to schools; after executing this query, the new dataset 
	   frpm1516 will have no duplicate/repeated unique id values,and all unique 
	   id values will correspond to our experimenal units of interest, which are
	   California Public K-12 schools; this means the columns County_Code, 
	   District_Code, and School_Code in frpm1516 are guaranteed to form a 
	   composite key */
    create table frpm1516 as
        select
            *
        from
            frpm1516_raw
        where
            /* remove rows with missing unique id value components */
            not(missing(County_Code))
            and
            not(missing(District_Code))
            and
            not(missing(School_Code))
            and
            /* remove rows for District Offices and non-public schools */
            School_Code not in ("0000000","0000001")
    ;
quit;


* do the same process as frpm1516: first check frpm1617_raw for bad unique id 
  values, where the columns County_Code, District_Code, and School_Code are 
  intended to form a composite key, then remove rows with missing unique id 
  components, or with unique ids that do not correspond to schools;

proc sql;
    create table frpm1617_raw_dups as
        select
             County_Code
            ,District_Code
            ,School_Code
            ,count(*) as row_count_for_unique_id_value
        from
            frpm1617_raw
        group by
             County_Code
            ,District_Code
            ,School_Code
        having
            row_count_for_unique_id_value > 1
	;
    create table frpm1617 as
	    select
		    *
		from
		    frpm1617_raw
		where
		    not(missing(County_Code))
			and
			not(missing(District_Code))
			and
            not(missing(School_Code))
			and
			School_Code not in ("0000000","0000001")
	;
quit;


* check dropouts17_raw for bad unique id values, where the column CDS_CODE is 
  intended to be a primary key;

proc sql;
    /* check for unique id values that are repeated, missing, or correspond to
       non-schools; after executing this query, we see that 
       dropouts17_raw_bad_unique_ids only has non-school values of CDS_Code 
       that need to be removed */
    create table dropouts17_raw_bad_uqique_ids as
	    select 
		    A.*
		from
		    dropouts17_raw as A
			left join
			(
			    select
				    CDS_CODE
					,count(*) as row_count_for_unique_id_value
				from
				    dropouts17_raw
				group by
				    CDS_CODE
			)as B
			on A.CDS_CODE= B.CDS_CODE
		having
		    row_count_for_unique_id_value >1
			or
			missing(CDS_CODE)
			or
			substr(CDS_CODE, 8,7) in ("0000000","0000001")
		;
    create table dropouts17 as 
	    select
		    *
		from
		    dropouts17_raw
		where 
		    substr(CDS_CODE,8, 7) not in ("0000000","0000001")
			
	;
quit;


* check act17_raw for bad unique id values, where the column cds is intended to
  be a primary key;

proc sql;
    /* check for unique id values that are repeated, missing, or correspond to 
       non-schools; after executing this query, we see that 
       act17_raw_bad_unique_ids only has non-school values of cds that need to 
       be removed */
    create table act17_raw_bad_uqique_ids as
	    select 
		    A.*
		from
		    act17_raw as A
			left join
			(
			    select
				    cds
					,count(*) as row_count_for_unique_id_value
				from
				    act17_raw
				group by
				    cds
			)as B
			on A.cds= B.cds
		having
		    row_count_for_unique_id_value >1
			or
			missing(cds)
			or
			substr(cds, 8,7) in ("0000000","0000001")
		;
    create table act17 as 
	    select
		    *
		from
		    act17_raw
		where 
		    /* ne means not equal to */
		    substr(cds,8, 7) ne "0000000"
			
	;
quit;

 
* because the numer of the total enrollment and dropout is not including the 
  grade seven and grade eight, also the total number of the enrollment and 
  dropout is saprate by ehic and gender, we should edit the dropouts17 first;
* edit dropouts17into distinct CDS_CODE also add the grade seven and grade
  eight into the total enrollment and total drop number individually, then 
  name the new work drop17;

/*
	proc sql;
    	create table drop17_ as
    	select CDS_CODE, 
           	E7+E8+ ETOT as TE,
           	D7+D8+ DTOT  as TD 
	    from dropouts17;

	proc sql;
    	create table drop17 as
    	select CDS_CODE, sum(TE) as TTE, sum(TD)as TTD
	    	from drop17_
			group by CDS_CODE;
 
	quit;
	*/

* inspect columns of interest in cleaned versions of datasets;

	/*
	title "Inspect Percent_Eligible_Free_K12 in frpm1516";
	proc sql;
    	select
	 	min(VAR22) as min
		,max(VAR22) as max
		,mean(VAR22) as mean
		,median(VAR22) as med
		,nmiss(VAR22) as missing
   	 from
		frpm1516
  	  	;
	quit;
	title;
	title "Inspect Percent_Eligible_Free_K12 in frpm1617";
	proc sql;
    		select
	 	min(VAR20) as min
		,max(VAR20) as max
		,mean(VAR20) as mean
		,median(VAR20) as med
		,nmiss(VAR20) as missing
    		from
		frpm1617
    		;
	quit;
	title;
	title "Inspect PctGE21, after converting to numeric values, in act17";
	proc sql;
    		select
	 	min(input(PctGE21,best12.)) as min
		,max(input(PctGE21,best12.)) as max
		,mean(input(PctGE21,best12.)) as mean
		,median(input(PctGE21,best12.)) as med
		,nmiss(input(PctGE21,best12.)) as missing
    		from
		act17
    		;
		quit;
		title;
	title "Inspect NUMTSTTAKR, after converting to numeric values, in act17";
	proc sql;
    		select
	 	input(NumTstTakr,best12.) as Number_of_testers
		,count(*)
    		from
		act17
    		group by
		calculated Number_of_testers
    		;	
	quit;
	title;
	
	title "Inspect TOTAL, after converting to numeric values, in dropouts17";
	proc sql;
		select
		min(DTOT) as min
		,max(DTOT) as max
		,mean(DTOT) as mean
		,median(DTOT) as med
		,nmiss(DTOT) as missing
    		from
		dropouts17
    		;
	quit;
	title;
	*/
*combine frpm1516 and frpm1617 horizontally using a data-step match-merge;

	/*
	data twoyears;
		retain
			School_Code
			Academic_Year
			District_Code
			School_Code
			School_Type
			VAR22
			VAR23
			VAR24
				;
		keep
		    School_Code
			Academic_Year
			District_Code
			School_Code
			School_Type
	        VAR22
			VAR23
			VAR24
	    ;
	   merge
	        frpm1516(
	            rename=(
				VAR22 = Percent_Elgible
				VAR23 = Enrollment
				VAR24 = Meal_Count
	                    )
	              ) 

	        frpm1617(
	            rename=(
				VAR22 = Percent_Elgible
				VAR23 = Enrollment
				VAR24 = Meal_Count
			
	                    )
	             )
	;
	    by  School_Code;
	run; 

	proc sort data = twoyears;
	    by School_Code;
	run;

	* combine frpm1617 and frpm1516 horizontally using proc sql;

	proc sql;
	    create table sqltwoyears as
	        select
	             coalesce(A.School_Code,B.School_Code) as School_Code
	            ,coalesce(A.var22) as Percent_elgible
	            ,coalesce(A.var23) as Enrollment
				,coalesce(A.var24) as Meal_Count
	        from
	            frpm1516 as A
	            full join
	            frpm1617 as B
	            on A.School_Code=B.School_Code
	        order by
	            School_Code

	    /*  
	    title "Inspect Percent_Eligible_Free_K12 in frpm1516";
	    proc sql;
	        select
		     min(VAR22) as min
		    ,max(VAR22) as max
		    ,mean(VAR22) as mean
		    ,median(VAR22) as med
		    ,nmiss(VAR22) as missing
	        from
		    frpm1516
	        ;
	    quit;
	    title;
	    title "Inspect Percent_Eligible_Free_K12 in frpm1617";
	    proc sql;
	        select
		     min(VAR20) as min
		    ,max(VAR20) as max
		    ,mean(VAR20) as mean
		    ,median(VAR20) as med
		    ,nmiss(VAR20) as missing
	        from
		    frpm1617
	        ;
	    quit;
	    title;
	    title "Inspect NUMTSTTAKR, after converting to numeric values, in act17";
	    proc sql;
	        select
		     input(NumTstTakr,best12.) as Number_of_testers
		    ,count(*)
	        from
		    act17
	        group by
		    calculated Number_of_testers
	        ;
	    quit;
	    title;
	    title "Inspect TOTAL dropout, after converting to numeric values, in drop17";
	    proc sql;
	        select
		     min(TTD) as min
		    ,max(TTD) as max
		    ,mean(TTD) as mean
		    ,median(TTD) as med
		    ,nmiss(TTD) as missing
	        from
		    drop17
	        ;
	    quit;
	    title;
	    title "Inspect TOTAL enrollment, after converting to numeric values, in drop17";
	    
	    proc sql;
	        select
		     min(TTE) as min
		    ,max(TTE) as max
		    ,mean(TTE) as mean
		    ,median(TTE) as med
		    ,nmiss(TTE) as missing
	        from
		    drop17
	        ;
	    quit;
	    title;
	    */


	* combine act17 and drop17 horizontally using a data-step match-merge;
	* note: After running the data step and proc sort step below several times
	  and averaging the fullstimer output in the system log, they tend to take
	  about 0.06 seconds of combined "real time" to execute and a maximum of
	  about 1.2 MB of memory (990 KB for the data step vs. 2895 KB for the
	  proc sort step) on the computer they were tested on;

	/*
	data act_and_drop17_v1;
	    retain
		    CDS_code
			School
			District
			Number_of_ACT_Takers
			Number_Dropout
	        Number_Erollment
		;
		keep
		    CDS_code
			School
			District
			Number_of_ACT_Takers
			Number_Dropout
	        Number_Erollment
	    ;
	   merge
	        drop17(
	            rename=(
				TTD = Number_Dropout
				TTE = Number_Erollment
	                    )
	              ) 

	        act17(
	            rename=(
				cds = CDS_code
				sname = School
				dname= District
			
	                    )
	             )
	;
	    by  CDS_code;
	    Number_of_ACT_Takers=input(NumTstTakr, best12.);
	run; 

	proc sort data=act_and_drop17_v1;
	    by CDS_code;
	run;

	* combine act17 and drop17 horizontally using proc sql;
	* note: After running the proc sql step below several times and averaging
	  the fullstimer output in the system log, they tend to take about 0.04
	  seconds of "real time" to execute and about 6760k of memory on the computer
	  they were tested on. Consequently, the proc sql step appears to take roughly
	  the same amount of time to execute as the combined data step and proc sort
	  steps above, but to use roughly twice times as much memory;

	proc sql;
	    create table act_and_drop17_v2 as
	        select
	             coalesce(A.CDS,B.CDS_Code) as CDS_Code
	            ,coalesce(A.sname) as School
	            ,coalesce(A.dname) as District
	            ,input(A.NumTstTakr,best12.) as Number_of_ACT_Takers
	            ,coalesce(B.TTD) as Number_Dropout
				,coalesce(B.TTE) as Number_Erollment
	        from
	            act17 as A
	            full join
	            drop17 as B
	            on A.CDS=B.CDS_Code
	        order by
	            CDS_Code

	    ;
	quit;



	* verify that twoyears and sqltwoyears are identical;
	proc compare
	        base=twoyears
	        compare=sqltwoyears
	        novalues
	    ;
	run;

	* verify that act_and_drop17_v1 and act_and_drop17_v2 are identical;
	proc compare
	        base=act_and_drop17_v1
	        compare=act_and_drop17_v2
	        novalues
	    ;
	run;
	*/
