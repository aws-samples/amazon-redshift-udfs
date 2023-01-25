CREATE OR REPLACE PROCEDURE update_permissions(external_schema_name IN VARCHAR(100), external_db_name IN varchar(100), external_table_name IN VARCHAR(100), iam_role_arn IN VARCHAR(250), s3_path IN VARCHAR(1000))
AS $$
DECLARE
    drop_schema_query VARCHAR(2000);
    create_external_schema_query VARCHAR(2000);
    get_authorization_rows_query VARCHAR(2000);
    create_external_table_query VARCHAR(2000);
    authorization_query VARCHAR(2000);
    rows RECORD;

BEGIN
    -- First, drop the external schema if it exists
    drop_schema_query = 'DROP SCHEMA IF EXISTS ' || external_schema_name || ';';
    EXECUTE drop_schema_query;

    -- Create external schema
    create_external_schema_query = 'create external schema ' || external_schema_name || ' from data catalog database ' || external_db_name || ' iam_role \'' || iam_role_arn || '\' create external database if not exists;';
    EXECUTE create_external_schema_query;

    -- Create external table
    create_external_table_query = 'create external table '|| external_schema_name || '.' || external_table_name || '(id integer, operation varchar(50), principal varchar(50), principal_type varchar(50), object_type varchar(50), object_name varchar(50), access_option varchar(50)) row format delimited fields terminated by \'\|' || '\' stored as textfile location \'' || 's3_path' || '\';';
    EXECUTE create_external_table_query;

    -- Get authorisations query. This is the Spectrum table reading data from the latest file stored in S3
    get_authorization_rows_query = 'SELECT * FROM ' || external_schema_name || '.' || external_table_name || ';';

    -- Loop through rows in the file
    FOR rows IN EXECUTE get_authorization_rows_query LOOP

        -- Users
        IF lower(rows.principal_type) = 'user' THEN
            IF lower(rows.operation) = 'grant' THEN
                IF lower(rows.object_name) LIKE 'all tables in schema%' THEN
                    authorization_query = rows.operation || ' ' || rows.access_option || ' ON ' || rows.object_name || ' TO ' || rows.principal || ';';
                    RAISE INFO '%', authorization_query;
                    EXECUTE authorization_query;
                ELSE
                    authorization_query = rows.operation || ' ' || rows.access_option || ' ON ' || rows.object_type || ' ' || rows.object_name || ' TO ' || rows.principal || ';';
                    RAISE INFO '%', authorization_query;
                    EXECUTE authorization_query;
                END IF;
            
            ELSIF lower(rows.operation) = 'revoke' THEN
                IF lower(rows.object_name) LIKE 'all tables in schema%' THEN
                    authorization_query = rows.operation || ' ' || rows.access_option || ' ON ' || rows.object_name || ' FROM ' || rows.principal || ';';
                    RAISE INFO '%', authorization_query;
                    EXECUTE authorization_query;

                ELSE
                    authorization_query = rows.operation || ' ' || rows.access_option || ' ON ' || rows.object_type || ' ' || rows.object_name || ' FROM ' || rows.principal || ';';
                    RAISE INFO '%', authorization_query;
                    EXECUTE authorization_query;
                END IF;

            ELSIF lower(rows.operation) = 'attach' THEN
                authorization_query = rows.operation || ' RLS POLICY ' || rows.access_option || ' ON ' || rows.object_name || ' TO ' || rows.principal || ';';
                RAISE INFO '%', authorization_query;
                EXECUTE authorization_query;

            ELSIF lower(rows.operation) = 'detach' THEN
                authorization_query = rows.operation || ' RLS POLICY ' || rows.access_option || ' ON ' || rows.object_name || ' FROM ' || rows.principal || ';';
                RAISE INFO '%', authorization_query;
                EXECUTE authorization_query;
            END IF;
        -- Groups
        ELSIF lower(rows.principal_type) = 'group' THEN
            IF lower(rows.operation) = 'grant' THEN
                IF lower(rows.object_name) LIKE 'all tables in schema%' THEN
                    authorization_query = rows.operation || ' ' || rows.access_option || ' ON ' || rows.object_name || ' TO GROUP ' || rows.principal || ';';
                    RAISE INFO '%', authorization_query;
                    EXECUTE authorization_query;
                ELSE
                    authorization_query = rows.operation || ' ' || rows.access_option || ' ON ' || rows.object_type || ' ' || rows.object_name || ' TO GROUP ' || rows.principal || ';';
                    RAISE INFO '%', authorization_query;
                    EXECUTE authorization_query;
                END IF;
            ELSIF lower(rows.operation) = 'revoke' THEN
                IF lower(rows.object_name) LIKE 'all tables in schema%' THEN
                    authorization_query = rows.operation || ' ' || rows.access_option || ' ON ' || rows.object_name || ' FROM GROUP ' || rows.principal || ';';
                    RAISE INFO '%', authorization_query;
                    EXECUTE authorization_query;
                ELSE
                    authorization_query = rows.operation || ' ' || rows.access_option || ' ON ' || rows.object_type || ' ' || rows.object_name || ' FROM GROUP ' || rows.principal || ';';
                    RAISE INFO '%', authorization_query;
                    EXECUTE authorization_query;
                END IF;
            END IF;

            ELSIF lower(rows.principal_type) = 'role' THEN
            IF lower(rows.operation) = 'grant' THEN
                IF lower(rows.object_name) LIKE 'all tables in schema%' THEN
                    authorization_query = rows.operation || ' ' || rows.access_option || ' ON ' || rows.object_name || ' TO ROLE ' || rows.principal || ';';
                    RAISE INFO '%', authorization_query;
                    EXECUTE authorization_query;
                ELSE
                    authorization_query = rows.operation || ' ' || rows.access_option || ' ON ' || rows.object_type || ' ' || rows.object_name || ' TO ROLE ' || rows.principal || ';';
                    RAISE INFO '%', authorization_query;
                    EXECUTE authorization_query;
                END IF;
            ELSIF lower(rows.operation) = 'revoke' THEN
                IF lower(rows.object_name) LIKE 'all tables in schema%' THEN
                    authorization_query = rows.operation || ' ' || rows.access_option || ' ON ' || rows.object_name || ' FROM ROLE ' || rows.principal || ';';
                    --authorization_query = rows.operation || ' ' || rows.access_option || ' ON ' || rows.object_name || ' TO ' || rows.principal || ';';
                    RAISE INFO '%', authorization_query;
                    EXECUTE authorization_query;
                ELSE
                    authorization_query = rows.operation || ' ' || rows.access_option || ' ON ' || rows.object_type || ' ' || rows.object_name || ' FROM ROLE ' || rows.principal || ';';
                    RAISE INFO '%', authorization_query;
                    EXECUTE authorization_query;
                END IF;
            ELSIF lower(rows.operation) = 'attach' THEN
                authorization_query = rows.operation || ' RLS POLICY ' || rows.access_option || ' ON ' || rows.object_name || ' TO ROLE ' || rows.principal || ';';
                RAISE INFO '%', authorization_query;
                EXECUTE authorization_query;
            
            ELSIF lower(rows.operation) = 'detach' THEN
                authorization_query = rows.operation || ' RLS POLICY ' || rows.access_option || ' ON ' || rows.object_name || ' FROM ROLE ' || rows.principal || ';';
                RAISE INFO '%', authorization_query;
                EXECUTE authorization_query;

            END IF;

        END IF;
 
    END LOOP;
END;
$$ LANGUAGE plpgsql;
