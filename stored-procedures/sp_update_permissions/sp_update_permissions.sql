CREATE OR REPLACE PROCEDURE public.sp_update_permissions(external_schema_name varchar, external_table_name varchar)
AS $$
DECLARE
    get_authorization_rows_query VARCHAR(2000);
    authorization_query VARCHAR(2000);
    rows RECORD;

BEGIN
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