/**********************************************************************************************
Purpose: Check the integrity of the FOREIGN KEY declared on a table and a column

Notes:  If the foreign key dosen't have a primary key, it will raise a info. 

Parameters:
        batch_time  : Timestamp for this batch. Can be used to group multiple fixes
        check_table : Schema qualified name of table to be queried
        check_column : Name of the column we want to check the integrity, must be a column in check_table
        log_table   : Schema qualified table where actions are to be logged
                      DDL structure must be as follows:
                        CREATE TABLE $(log_table) (
                            batch_time   TIMESTAMP,
                            check_table  VARCHAR,
                            check_column VARCHAR,
                            check_time   TIMESTAMP,
                            check_status VARCHAR,
                            error_count  INT);
History:
2023-04-20 - bgmello - Created
**********************************************************************************************/

CREATE PROCEDURE sp_check_foreign_key(batch_time timestamp without time zone, check_table character varying,
                                      check_column character varying, log_table character varying)
    LANGUAGE plpgsql
AS
$$
DECLARE
    sql                 VARCHAR(MAX) := '';
    record              RECORD;
    pk_table            VARCHAR(256);
    pk_column           VARCHAR(256);
    inconsistency_count INTEGER      := 0;
    dot_position        INTEGER;
BEGIN
    IF check_table = '' OR log_table = '' OR check_column = '' THEN
        RAISE EXCEPTION 'Parameters `check_table`, `log_table`, `check_column` cannot be empty.';
    END IF;

    -- Retrieve the primary key column and table for that foreign key for the table
    sql := 'SELECT rel_kcu.table_schema || ''.'' || rel_kcu.table_name AS pk_table, ' ||
           '       rel_kcu.column_name AS pk_column ' ||
           'FROM information_schema.table_constraints tco ' ||
           'LEFT JOIN information_schema.key_column_usage kcu ' ||
           '          ON tco.constraint_schema = kcu.constraint_schema ' ||
           '          AND tco.constraint_name = kcu.constraint_name ' ||
           'LEFT JOIN information_schema.referential_constraints rco ' ||
           '          ON tco.constraint_schema = rco.constraint_schema ' ||
           '          AND tco.constraint_name = rco.constraint_name ' ||
           'LEFT JOIN information_schema.key_column_usage rel_kcu ' ||
           '          ON rco.unique_constraint_schema = rel_kcu.constraint_schema ' ||
           '          AND rco.unique_constraint_name = rel_kcu.constraint_name ' ||
           '          AND kcu.ordinal_position = rel_kcu.ordinal_position ' ||
           'WHERE tco.constraint_type = ''FOREIGN KEY''';
    dot_position := POSITION('.' IN check_table);
    IF dot_position > 0 THEN
        sql := sql || ' AND kcu.table_schema = ''' || LOWER(SUBSTRING(check_table FROM 1 FOR dot_position - 1)) || ''''
                   || ' AND kcu.table_name = ''' || LOWER(SUBSTRING(check_table FROM dot_position + 1)) || '''';
    ELSE
        sql := sql || ' AND kcu.table_name = ''' || LOWER(check_table) || '''';
    END IF;

    sql := sql || ' AND kcu.column_name = ''' || LOWER(check_column) || '''';
    EXECUTE sql INTO record;
    pk_table := record.pk_table;
    pk_column := record.pk_column;
    RAISE INFO '%', sql;
    -- Count the number of foreign key inconsistencies
    IF pk_table IS NULL OR pk_column IS NULL THEN
        RAISE INFO 'Primary table or column is null';
    ELSE
        sql := ' SELECT COUNT(*) FROM ' || check_table ||
               ' WHERE ' || check_column || ' NOT IN (SELECT ' ||
               pk_column || ' FROM ' || pk_table || ');';

        EXECUTE sql INTO inconsistency_count;
        IF inconsistency_count = 0 THEN
            EXECUTE 'INSERT INTO ' || log_table ||
                    ' (batch_time, check_table, check_column, check_time, check_status, error_count) VALUES (''' || batch_time ||
                    ''',''' || check_table || ''',''' || check_column || ''', current_timestamp,''OK - No foreign key inconsistencies found'',0);';
            RAISE INFO 'OK - No foreign key inconsistencies found';
        ELSE
            EXECUTE 'INSERT INTO ' || log_table ||
                    ' (batch_time, check_table, check_column, check_time, check_status, error_count) VALUES (''' || batch_time ||
                    ''',''' || check_table || ''',''' || check_column ||
                    ''', current_timestamp,''ERROR - ' || inconsistency_count ||
                    ' Foreign key inconsistencies found'', ' || inconsistency_count ||
                    ');';
            RAISE INFO 'ERROR - % Foreign key inconsistencies found', inconsistency_count;
        END IF;
    END IF;
END
$$;

/* Usage Example:

    DROP TABLE IF EXISTS tmp_fk_log;
    CREATE TABLE tmp_fk_log(
          batch_time   TIMESTAMP
        , check_table  VARCHAR
        , check_column VARCHAR
        , check_time   TIMESTAMP
        , check_status VARCHAR
        , error_count  INT);
    DROP TABLE IF EXISTS customers;
    CREATE TABLE customers (
    customer_id INTEGER IDENTITY(1,1) PRIMARY KEY,
    customer_name VARCHAR(50) NOT NULL
    );
    DROP TABLE IF EXISTS orders;
    CREATE TABLE orders (
        order_id INTEGER IDENTITY(1,1) PRIMARY KEY,
        customer_id INTEGER NOT NULL REFERENCES customers(customer_id),
        order_date DATE NOT NULL
    );
    INSERT INTO customers (customer_name)
    VALUES ('Alice'), ('Bob'), ('Charlie');
    INSERT INTO orders (customer_id, order_date)
    VALUES (1, '2023-01-01'),
           (2, '2023-01-02'),
           (3, '2023-01-03'),
           (4, '2023-01-04'); -- Inconsistency: customer_id 4 does not exist
    CALL sp_check_foreign_key(SYSDATE,'orders', 'customer_id', 'tmp_fk_log');
*/

