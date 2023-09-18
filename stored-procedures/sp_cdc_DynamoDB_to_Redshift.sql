CREATE OR REPLACE PROCEDURE public.sp_ddb_to_redshift_setup_schema_mv(kinesis_access_role character varying(256), account_number character varying(256), kds_name character varying(256))
 LANGUAGE plpgsql
AS $_$
	
DECLARE
    mv_sql varchar(1000);
    ext_schema_sql varchar(1000);
    role_string varchar(300);
    role_string1 varchar(300);
    cdc_name1 varchar(1000);
    Account_number2 varchar(100);
    mvsql_end varchar(10);
BEGIN
	role_string = 'arn:aws:iam::'+$2+':role/'+$1;
    role_string1 := ''''+ role_string + '''' ;
	ext_schema_sql = 
	'create external schema dynamodb_schema from kinesis
    iam_role ' + role_string1 ;
    raise info 'ext_schema_sql -> %',ext_schema_sql;
	cdc_name1 := '"'+ $3+ '"' ;
	mv_sql = 
		'create materialized view 
	    dynamodb_kds_rs_mv sortkey(1) 
		auto refresh yes as
	    select
		refresh_time,
		approximate_arrival_timestamp,
		partition_key,
		shard_id,
		sequence_number,
		json_parse(kinesis_data) as payload,
		kinesis_data
		from
			dynamodb_schema.' + cdc_name1 + '
		where
			can_json_parse(kinesis_data);';
	raise info 'mv_sql - > %',mv_sql;
    execute ext_schema_sql;
    execute mv_sql;
    mvsql_end = ':end';
    raise info 'Creation Completed - > schema dynamodb_schema. and materialized view dynamodb_kds_rs_mv %',mvsql_end;
END;
$_$

CREATE OR REPLACE PROCEDURE public.sp_ddb_to_redshift_setup_process_tables()
 LANGUAGE plpgsql
AS $$ 
BEGIN


	--3
	create table if not exists dynamodb_kds_mv_staging (
	    refresh_time timestamp,
		approximate_arrival_timestamp timestamp,
		partition_key varchar,
		shard_id varchar,
		sequence_number varchar,
		payload super, 
		kinesis_data super
	);
	
	CREATE TABLE if not exists  public.metadata_etl (
		jobname character varying(100) ENCODE lzo,
		startdate timestamp without time zone ENCODE az64,
		enddate timestamp without time zone ENCODE az64,
		status character varying(50) ENCODE lzo
	 ) DISTSTYLE AUTO;

	create table if not exists dynamodb_kds_mv_staging_batch 
	(
		batch_timestamp timestamp,  
		process_flag char,
		process_timestamp timestamp,
		refresh_time timestamp,
		approximate_arrival_timestamp timestamp,
		partition_key varchar,
		shard_id varchar,
		sequence_number varchar,
		payload super, 
		kinesis_data super,
		batch_id  bigint identity (1,1)
	);
    insert into dynamodb_kds_mv_staging_batch
	values( current_timestamp,null,current_timestamp, 
	current_timestamp,null,null,null,null,null,null);
	
	
	--4
	create table if not exists --drop table\
	dynamodb_kds_staging_cdc (
	    
	    refresh_time timestamp,
		approximate_arrival_timestamp timestamp,
		table_name varchar,
		distribution_key varchar,
		approximatecreationdatetime varchar,
		event_id varchar,
		event_name char(10),
		payload super,
		kinesis_data super
	);
	
	create table if not exists --drop table\
	dynamodb_kds_staging_cdc_unique (
	    record_sequence_number int,
	    refresh_time timestamp,
		approximate_arrival_timestamp timestamp,
		table_name varchar,
		distribution_key varchar,
		approximatecreationdatetime varchar,
		event_id varchar,
		event_name char(10),
		payload super,
		kinesis_data super
	
	);
	
	--5
 
	create table if not exists metadata_dd_table_columns(
		table_name varchar(200),
		column_name varchar(200),
		column_data_type varchar(50),
		column_is_key varchar(10),
		last_update timestamp, 
		current_flag char(1),
		row_id  bigint identity (1,1)
	);
	

	CREATE TABLE if not exists public.metadata_dd_table_keys (
		table_name character varying(256) ENCODE lzo,
		column_name character varying(200) ENCODE lzo,
		column_data_type character varying(50) ENCODE lzo,
		column_is_key character varying(10) ENCODE lzo,
		last_update timestamp without time zone ENCODE az64,
		current_flag character(1) ENCODE lzo
		) DISTSTYLE AUTO;
	--6
	create table if not exists metadata_dd_table_columns_hist(
		table_name varchar(200),
		column_name varchar(200),
		column_data_type varchar(50),
		last_update timestamp
	);
	
	--7
	create table if not exists metadata_dd_table_key(
		table_name nvarchar(256),
		column_name varchar(200),
		column_data_type varchar(50),
		column_is_key varchar(10),
		last_update timestamp, 
		current_flag char(1),
		row_id  bigint identity (1,1)
	);
	
	--8
	create table if not exists   public.temp_table_pivot_data(
		table_name varchar(max) encode lzo,
		distribution_key varchar(max) encode lzo,
		column_name varchar(max) encode lzo,
		column_data varchar(max) encode lzo
	)
	diststyle auto
	;
	

END;
$$



CREATE OR REPLACE PROCEDURE public.sp_ddb_to_redshift_incremental_refresh_cdc()
 LANGUAGE plpgsql
AS $$
	
BEGIN
	
	set enable_case_sensitive_identifier to true;
	
	
	insert into MetaData_ETL values
	('SP_DDB_to_Redshift_refresh_cdc',current_timestamp,null,'Running');
	
	refresh materialized view dynamodb_kds_rs_mv;

	insert
		into
		dynamodb_kds_mv_staging_batch
	select 
	    current_timestamp as batch_timestamp,
	    'N' as process_flag,
	     TO_TIMESTAMP('2000-01-01 00:00:00', 'YYYY-MM-DD HH24:MI:SS') as process_timestamp,
	    refresh_time ,
		approximate_arrival_timestamp ,
		partition_key ,
		shard_id ,
		sequence_number ,
		payload,
		json_parse(kinesis_data)  
	from
		dynamodb_kds_rs_mv
	where
		refresh_time > (
		select
			Max(refresh_time) - 1
		from
			dynamodb_kds_mv_staging_batch
	);
	
    
    -->select * from dynamodb_kds_mv_staging_batch;-->
	raise info '*************MV refresh complete and data is in Batch table****************';
	/* Prepare staging tables */
	delete from dynamodb_kds_staging_cdc_unique;
	delete from dynamodb_kds_staging_cdc;
	
	
	/* Load staging tables */
	insert into dynamodb_kds_staging_cdc
	select
		 stg1.refresh_time
		,stg1.approximate_arrival_timestamp
	 	--,trim('"' from json_serialize(payload."tableName")) as table_name
	 	,lower(trim('"' from json_serialize(payload."tableName"))) as table_name
	    ,json_serialize(stg1.kinesis_data."dynamodb"."Keys") as Distribution_Key
	    ,json_serialize(stg1.kinesis_data."dynamodb"."ApproximateCreationDateTime") as ApproximateCreationDateTime
	    ,json_serialize(stg1.kinesis_data."eventID") as event_id
	 	,json_serialize(payload."eventName") as event_name
	 	,payload
	 	,kinesis_data
	from dynamodb_kds_mv_staging_batch stg1
	where process_flag = 'N';
	
	raise info '********************Load staging tables complete********************';
	
	insert into dynamodb_kds_staging_cdc_unique
	select 
	    row_number() over (partition by table_name, distribution_key order by ApproximateCreationDateTime desc) as record_sequence_number,*
	from dynamodb_kds_staging_cdc
	;
	
	/* Remove duplicate entries */
	delete from dynamodb_kds_staging_cdc_unique where record_sequence_number > 1;
	--select * from dynamodb_kds_staging_cdc_unique order by ApproximateCreationDateTime desc;
	--select count(1) from dynamodb_kds_staging_cdc_unique;
	
--delete from dynamodb_kds_staging_cdc_unique where table_name = 'DDB4RS';
--drop table testrs;
	
	/* Update parsing tables */
	insert into  MetaData_DD_Table_Columns                         
	select distinct
	     lower(trim('"' from json_serialize(payload."tableName"))) as table_name
	    ,key as column_name
	    --,value
	   -- ,substring(json_serialize(value),3,1) as xzx
	    ,case when substring(json_serialize(value),3,1) = 'N' then 'Number'
	          when substring(json_serialize(value),3,1) = 'S' then 'String'
	          when substring(json_serialize(value),3,1) = 'L' then 'List'
	          when substring(json_serialize(value),3,1) = 'B' then 'Boolean'
	          end  as  column_data_type
	    ,'N' as column_is_key 
	    ,current_timestamp as last_update
	    ,'Y' as current_flag
	from
		dynamodb_kds_staging_cdc_unique ed,
		unpivot ed.kinesis_data."dynamodb"."NewImage" as value at key
	order by 1,2
	;
	
	/* Update parsing tables and keys */
	insert into MetaData_DD_Table_Keys
	select distinct
	     trim('"' from json_serialize(payload."tableName")) as table_name
	    ,key as column_name
	    --,value
	    --,substring(json_serialize(value),3,1) as xzx
	    ,case when substring(json_serialize(value),3,1) = 'N' then 'Number'
	          when substring(json_serialize(value),3,1) = 'S' then 'String'
	          when substring(json_serialize(value),3,1) = 'L' then 'List'
	          when substring(json_serialize(value),3,1) = 'B' then 'Boolean'
	          end  as  column_data_type
	    ,'Y' as column_is_key 
	    ,current_timestamp as last_update
	    ,'Y' as current_flag
	from
		--dynamodb_kds_mv_staging 
		dynamodb_kds_staging_cdc_unique ed,
		unpivot ed.kinesis_data."dynamodb"."Keys" as value at key
	order by 1,2
	;
	
	/* Update parsing tables and keys contd */
	update MetaData_DD_Table_Columns
	set column_is_key = 'Y' 
	from 
	    MetaData_DD_Table_Keys k ,MetaData_DD_Table_Columns c
	where k.table_name = c.table_name and 
	k.column_name = c.column_name
	;
	
	
	raise info '******************** Calling sp_cursor_loop_create_tables() ********************';
	
	/* create tables for new data if target tables does not exist */
    --drop table ddb4rs;
	call sp_cursor_loop_create_tables();
	
	raise info '******************** Calling sp_cursor_loop_alter_tables() ********************';
	/* alter tables for new data has new attributes */
	call sp_cursor_loop_alter_tables();
	
	/*                     */
	--delete public.table1_tmp1;
	delete from public.temp_table_pivot_data;
	
	raise info '******************** Calling sp_cursor_loop_process_merge_tables() ********************';
	/* Merge data */
	call sp_cursor_loop_process_merge_tables();
	
	raise info '******************** Merge complete - House Keeping next() ********************';
	
	
	
	update MetaData_ETL
	set status = 'Complete',
	enddate = current_timestamp
	where JobName = 'SP_DDB_to_Redshift_refresh_cdc'
	and startdate = (select max(startdate) from MetaData_ETL)
	;

    update dynamodb_kds_mv_staging_batch set process_flag = 'Y';

END;
$$



CREATE OR REPLACE PROCEDURE public.sp_create_table_varchar_max(table_name character varying(256))
 LANGUAGE plpgsql
AS $_$
	
	declare 
	input_message varchar(100);
	table_name1 varchar(100);
	alias_message alias for $1;
	listagg_sql varchar(300);
	listagg_sqle varchar(333);
	listagg_sqle1 varchar(max);
	final_sql varchar(max);
	col_list varchar(max);
	delete_hist varchar(1300);
	insert_sql varchar(1300);
	s_public varchar(1300);
	s_basetable varchar(1300);
	select_sql varchar(1300);
	table_exists int;

begin
	table_name1 := ' '''+ $1+ '''' ;
    table_name1 := ' '''+ $1+ '''' ;
     
	input_message := $1; 
    s_public := ' '''+'public'+ '''' ;
    s_basetable := ' '''+'BASE TABLE'+ '''' ;
	--raise info 'Creating a table if it does not exist %',$1;

    select_sql = 'SELECT COUNT(table_name) FROM information_schema.tables WHERE '+
    	'table_schema LIKE '+s_public+ ' AND '+
    	'table_type LIKE ' + s_basetable +' AND '+
		'table_name = LOWER(' + table_name1+')';
    execute select_sql into table_exists;

    raise info 'select_sql %',select_sql;
    raise info 'select_sql %',table_exists;
    
 
    IF $1 IS NOT NULL THEN
	listagg_sql = ' Select listagg(distinct column_name, ' + 
	               ' '' varchar(max), ''  '   +
                   ' )within group (order by column_name) ' +
                   ' as createString from MetaData_DD_Table_Columns where table_name = LOWER(' + table_name1+')';
	END IF;
	listagg_sqle := ''||listagg_sql|| '';
	EXECUTE listagg_sqle into listagg_sqle1;

    final_sql = 'create table if not exists '+input_message+' (Dist_key varchar, '+listagg_sqle1+' varchar(max))';
    if table_exists = 0 then 
       EXECUTE final_sql;
       raise notice 'Table created - new*  %',final_sql;
    end if;

	delete_hist = 'DELETE FROM MetaData_DD_Table_Columns_hist WHERE table_name = LOWER(' + table_name1+')';
    if table_exists = 0 then
		EXECUTE delete_hist;
	end if;
    insert_sql = 'INSERT INTO MetaData_DD_Table_Columns_hist  select  
			distinct TABLE_NAME,column_name,column_data_type,current_timestamp
				from MetaData_DD_Table_Columns where table_name = LOWER(' + table_name1+')';
    if table_exists = 0 then
    	EXECUTE insert_sql;
    end if;
    raise info 'public.sp_create_table_varchar() complete %',table_name1 ;  
end;
$_$


CREATE OR REPLACE PROCEDURE public.sp_cursor_loop_alter_tables()
 LANGUAGE plpgsql
AS $$
DECLARE
    row record;
    alter_sql varchar(300); 
    curs1 cursor for 
    select  
	distinct TABLE_NAME,column_name  
	from MetaData_DD_Table_Columns  
	minus 
	select TABLE_NAME,column_name  
	from MetaData_DD_Table_Columns_hist;

BEGIN
    OPEN curs1;
    LOOP
        fetch curs1 into row;
        exit when not found;
        --call sp_create_table_varchar_new(row.table_name, row.column_name);
        alter_sql = 'alter table ' + row.table_name + ' add column ' + row.column_name + ' varchar(max) default null ' ;
        execute alter_sql;
        INSERT INTO MetaData_DD_Table_Columns_hist  
        values (row.table_name,row.column_name,'altered',current_timestamp);
 
        RAISE INFO 'a %', alter_sql;
    END LOOP;
    RAISE INFO 'sp_cursor_loop_alter_tables() complete.';
    CLOSE curs1;
END;
$$


CREATE OR REPLACE PROCEDURE public.sp_cursor_loop_alter_tables()
 LANGUAGE plpgsql
AS $$
DECLARE
    row record;
    alter_sql varchar(300); 
    curs1 cursor for 
    select  
	distinct TABLE_NAME,column_name  
	from MetaData_DD_Table_Columns  
	minus 
	select TABLE_NAME,column_name  
	from MetaData_DD_Table_Columns_hist;

BEGIN
    OPEN curs1;
    LOOP
        fetch curs1 into row;
        exit when not found;
        --call sp_create_table_varchar_new(row.table_name, row.column_name);
        alter_sql = 'alter table ' + row.table_name + ' add column ' + row.column_name + ' varchar(max) default null ' ;
        execute alter_sql;
        INSERT INTO MetaData_DD_Table_Columns_hist  
        values (row.table_name,row.column_name,'altered',current_timestamp);
 
        RAISE INFO 'a %', alter_sql;
    END LOOP;
    RAISE INFO 'sp_cursor_loop_alter_tables() complete.';
    CLOSE curs1;
END;
$$


CREATE OR REPLACE PROCEDURE public.sp_cursor_loop_process_merge_tables()
 LANGUAGE plpgsql
AS $$
DECLARE
    tbl varchar;
    tbl_key varchar;
    row record;
    curs1 cursor for 
    select table_name,distribution_key from dynamodb_kds_staging_cdc_unique where Event_name <> '"REMOVE"';
    curs2 cursor for 
    select table_name,distribution_key from dynamodb_kds_staging_cdc_unique where Event_name = '"REMOVE"';
BEGIN
    OPEN curs1;
    LOOP
        fetch curs1 into row;
        exit when not found;
        call sp_merge_table_key_data(row.table_name,row.distribution_key);
        RAISE INFO 'Merge %', tbl_key;
    END LOOP;
    CLOSE curs1;
   
    OPEN curs2;
    LOOP
        fetch curs2 into row;
        exit when not found;
        call sp_delete_table_key_data(row.table_name,row.distribution_key);
        RAISE INFO 'Remove %', tbl_key;
    END LOOP;
    CLOSE curs2;
   
END;
$$


CREATE OR REPLACE PROCEDURE public.sp_delete_table_key_data(table_name character varying(100), distribution_key character varying(256))
 LANGUAGE plpgsql
AS $_$
declare 
	distribution_key1 varchar(500);
	table_name1 varchar(100);
    delete_sql varchar(500);
	
begin
	delete_sql = 'delete from '+ table_name + ' where dist_key = '+ '''' + $2 +'''';
	execute delete_sql;
    raise notice '  delete_sql -    %',delete_sql;
    
   
end;
$_$




CREATE OR REPLACE PROCEDURE public.sp_merge_table_key_data(table_name character varying(100), distribution_key character varying(256))
 LANGUAGE plpgsql
AS $_$
declare 
	distribution_key1 varchar(500);
	table_name1 varchar(500);
    sql_line_1 varchar(max);
    delete_sql varchar(max);
	listagg_sql varchar(max);
	word1 varchar(500);
    word2 varchar(500);
    word3 varchar(500);
    word4 varchar(500);
    word5 varchar(500);
    word9 varchar(500);
    word10 varchar(5);
	listagg_sqle1 varchar(max);
	final_sql varchar(max);
	final_sql2 varchar(max);
	col_list varchar(max);
	sql_listagg_1 varchar(max);
    sql_listagg_1_result varchar(max);
    sql_listagg_2 varchar(max);
    sql_final_insert varchar(max);
    sql_listagg_2_result varchar(max);
    sql_listagg_2_result9 varchar(max);
	SQl_list_agg_2 varchar(max);
	word6 varchar(max);
BEGIN
	
	delete_sql = 'delete from '+ table_name + ' where dist_key = '+ '''' + $2 +'''';
	execute delete_sql;

    table_name1 := ' '''+ $1+ '''' ;
    distribution_key1 = '''' + $2 +'''';

    word1 = '''"}''';
    word2 = '"'+'dynamodb'+'"'+'.'+'"'+'NewImage'+'"';
    word3 = ' trim(''"''';
    word4 = '"'+'tableName'+'"';
    word5 = '"'+'dynamodb'+'"'+'.'+'"'+'Keys'+'"';
    word9 = '''''||column_name||'''''   ;
    word10 = ',';
    sql_line_1 = 'insert  into public.temp_table_pivot_data with ctx as (select'+word3+' from json_serialize(payload.'+word4+')) as table_name,'+'json_serialize(ed.kinesis_data.'+word5+
                  ') as Distribution_Key,'+
                 'key as column_name,rtrim(substring(json_serialize(value),7,1000),' + word1 +
                 ') as column_data from dynamodb_kds_staging_cdc_unique ed,unpivot ed.kinesis_data.'+ word2 +
                 ' as value at key where table_name = ' + table_name1 +
                 ' and distribution_key =' + distribution_key1 +
                 ')  select * from ctx;';
	EXECUTE sql_line_1;
    sql_listagg_1 = 'SELECT listagg(distinct column_name,'+ ''','''+
                    ') FROM MetaData_DD_Table_Columns where table_name ='+table_name1 + ' order by 1';
    EXECUTE sql_listagg_1 into sql_listagg_1_result;
    
    sql_listagg_2 = 'select listagg(' + word9 + word10 + ''',''' +
    ') within group (order by column_name) from 
     (select distinct quote_literal(column_name) as column_name from MetaData_DD_Table_Columns 
      where table_name = '+table_name1 + ');';
    EXECUTE sql_listagg_2 into sql_listagg_2_result;
    
    
    sql_final_insert = 'insert into '+$1+' (dist_key,' + sql_listagg_1_result + ')with cty as (select ' + table_name1 + ' as table_name,'+
              distribution_key1 + 'as dist_key,* from (select column_name,column_data from	public.temp_table_pivot_data where          distribution_key = '+distribution_key1+' ) pivot( min(column_data) for column_name in (' + 
              sql_listagg_2_result+'))) select'+distribution_key1 + 'as dist_key,'+ sql_listagg_1_result + ' from cty;';
    
    raise notice ' The insert statement   %',sql_final_insert;
    EXECUTE sql_final_insert;
    raise notice ' sp_merge_table_key_data() completed for: %',table_name1;
END;
$_$










