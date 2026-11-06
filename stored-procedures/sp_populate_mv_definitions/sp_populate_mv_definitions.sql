/**********************************************************************************************
Purpose: Populate the mv_definitions table with each materialized view's definition text and a
         blocker_hint naming the SQL constructs that block incremental refresh (DISTINCT,
         OUTER JOIN, window functions, subqueries, mutable functions, statistical and
         bitwise aggregates, and so on).

Notes:   Creates mv_definitions in the current schema (first schema in the search_path)
         if it doesn't exist. Each run replaces its contents in a single
         transaction, so the table always reflects the MVs at the time of the run.
         blocker_hint is only derived for MVs with state 0 (full recompute). Every other MV
         reports 'none'. A blocked MV with no known construct reports 'unidentified' (for
         example an external Hudi or Delta Lake MV, blocked by table format).
         NONATOMIC, so one unreadable MV is recorded as 'UNREADABLE: ...' and the run
         continues. It walks a staged list of MVs with a WHILE loop because a cursor does
         not survive NONATOMIC commits.
         Uses session temporary tables tmp_mv_oids and tmp_mv_definitions.
         definition_text starts at CREATE MATERIALIZED VIEW (leading comments, such as the
         Query Editor v2 tag, are dropped). Comments are ignored when deriving blocker_hint.

Parameters:
        None

Usage:
    CALL sp_populate_mv_definitions();
    SELECT mv_schema, mv_name, blocker_hint FROM mv_definitions WHERE blocker_hint <> 'none';

    -- Combined with the admin.v_mv_health view from amazon-redshift-utils (src/AdminViews):
    SELECT v.*, d.blocker_hint
    FROM admin.v_mv_health v
    LEFT JOIN mv_definitions d
        ON v.mv_schema = d.mv_schema
       AND v.mv_name   = d.mv_name;

History:
2026-11-06 nickbarc Created
**********************************************************************************************/

-- DROP PROCEDURE sp_populate_mv_definitions();
CREATE OR REPLACE PROCEDURE sp_populate_mv_definitions()
NONATOMIC AS $$
DECLARE
    v_oid INT;
    v_schema VARCHAR(128);
    v_name VARCHAR(128);
    v_def VARCHAR(MAX);
    v_scan VARCHAR(MAX);
    v_pos INT;
    v_hint VARCHAR(512);
    v_count INT;
    v_i INT;
    v_state INT;
BEGIN
    -- Create output table if first run
    CREATE TABLE IF NOT EXISTS mv_definitions (
        mv_schema VARCHAR(128),
        mv_name VARCHAR(128),
        definition_text VARCHAR(MAX),
        blocker_hint VARCHAR(512)
    );

    -- Results are collected in a session-local staging table and published to
    -- mv_definitions in one transaction at the end (see Phase 3).
    DROP TABLE IF EXISTS tmp_mv_definitions;
    CREATE TEMP TABLE tmp_mv_definitions (LIKE mv_definitions);

    -- Phase 1: Identify materialized views by cross-referencing pg_class with
    -- SVV_MV_INFO, staging them with a ROW_NUMBER() surrogate key for the loop.
    DROP TABLE IF EXISTS tmp_mv_oids;
    CREATE TEMP TABLE tmp_mv_oids AS
    SELECT ROW_NUMBER() OVER (ORDER BY n.nspname, c.relname)::INT AS rn,
           c.oid::INT               AS oid_val,
           n.nspname::VARCHAR(128)  AS schema_name,
           c.relname::VARCHAR(128)  AS mv_name,
           mvi.state::INT           AS mv_state
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    JOIN SVV_MV_INFO mvi
        ON TRIM(mvi.name) = TRIM(c.relname)
       AND TRIM(mvi.schema_name) = TRIM(n.nspname)
    WHERE c.relkind = 'v';

    SELECT COUNT(*) INTO v_count FROM tmp_mv_oids;

    -- Phase 2: Walk the staging table by row number (no server-side cursor; a
    -- cursor does not survive NONATOMIC's per-statement commits).
    v_i := 1;
    WHILE v_i <= v_count LOOP
        SELECT oid_val, schema_name, mv_name, mv_state
          INTO v_oid, v_schema, v_name, v_state
        FROM tmp_mv_oids WHERE rn = v_i;

        -- Per-MV work is wrapped in a nested block so one unreadable MV does not
        -- abort the whole run. In a NONATOMIC procedure the EXCEPTION handler
        -- acts as a continue handler: the failing iteration is caught and logged,
        -- and the loop proceeds to the next row. (A default ATOMIC procedure
        -- would instead roll back and exit here; Redshift has no subtransactions.)
        BEGIN
            -- Get definition (leader-node scalar call via SELECT INTO)
            SELECT pg_catalog.pg_get_viewdef(v_oid, true) INTO v_def;

            -- For an MV, pg_get_viewdef returns the CREATE statement as it was submitted,
            -- including any leading comments (Query Editor v2 prefixes a /* RQEV2-... */
            -- tag). Keep the text from CREATE MATERIALIZED VIEW onward.
            v_pos := REGEXP_INSTR(v_def, 'create[[:space:]]+materialized[[:space:]]+view', 1, 1, 0, 'i');
            IF v_pos > 1 THEN
                v_def := SUBSTRING(v_def, v_pos);
            END IF;

            IF v_state <> 0 THEN
                v_hint := 'none';
            ELSE
                v_hint := '';
                -- Scan a copy with comments removed, so keywords in comments don't match.
                v_scan := REGEXP_REPLACE(v_def, '/[*]([^*]|[*]+[^*/])*[*]+/', ' ');
                v_scan := REGEXP_REPLACE(v_scan, '--[^\n]*', ' ');
                IF v_scan ~* '[[:<:]]distinct[[:>:]]' THEN v_hint := v_hint || ', DISTINCT'; END IF;
                IF v_scan ~* '[[:<:]](left|right|full)([[:space:]]+outer)?[[:space:]]+join[[:>:]]' THEN v_hint := v_hint || ', OUTER JOIN'; END IF;
                IF v_scan ~* '[[:<:]](union|intersect|except|minus)[[:>:]]' THEN v_hint := v_hint || ', SET OPERATOR'; END IF;
                IF v_scan ~* '[[:<:]]over[[:>:]][[:space:]]*[(]'
                   OR v_scan ~* '[[:<:]](row_number|rank|dense_rank|lag|lead|ntile|first_value|last_value)[[:>:]][[:space:]]*[(]'
                   THEN v_hint := v_hint || ', WINDOW FUNCTION'; END IF;
                IF v_scan ~* '[[:<:]](median|percentile_cont|percentile_disc|listagg)[[:>:]]'
                   OR v_scan ~* '[[:<:]]approximate[[:>:]]'
                   THEN v_hint := v_hint || ', ORDERED/HOLISTIC AGGREGATE'; END IF;
                IF v_scan ~* '[[:<:]](stddev|stddev_samp|stddev_pop|variance|var_samp|var_pop|bit_and|bit_or|bool_and|bool_or)[[:>:]][[:space:]]*[(]'
                   THEN v_hint := v_hint || ', STATISTICAL/BITWISE AGGREGATE'; END IF;
                -- Subqueries in WHERE or the SELECT list block incremental refresh. Derived
                -- tables (FROM/JOIN (SELECT ...)) and CTE bodies (AS (SELECT ...)) do not, so
                -- they are subtracted from the count of parenthesised SELECTs.
                IF REGEXP_COUNT(v_scan, '[(][[:space:]]*select[[:>:]]', 1, 'i')
                   > REGEXP_COUNT(v_scan, '[[:<:]](as|from|join)[[:space:]]*[(][[:space:]]*select[[:>:]]', 1, 'i')
                   THEN v_hint := v_hint || ', SUBQUERY'; END IF;
                IF v_scan ~* '[[:<:]](getdate|sysdate|random)[[:>:]]' OR v_scan ~* '[[:<:]]current_(date|timestamp|time)[[:>:]]' THEN v_hint := v_hint || ', MUTABLE FUNCTION'; END IF;

                IF v_hint = '' THEN
                    v_hint := 'unidentified (check the incremental refresh limitations)';
                ELSE
                    v_hint := LTRIM(v_hint, ', ');
                END IF;
            END IF;

            INSERT INTO tmp_mv_definitions (mv_schema, mv_name, definition_text, blocker_hint)
            VALUES (v_schema, v_name, v_def, v_hint);

        EXCEPTION WHEN OTHERS THEN
            -- Log-and-continue: record the unreadable MV instead of dropping it,
            -- so the diagnostic surfaces the problem rather than silently omitting it.
            INSERT INTO tmp_mv_definitions (mv_schema, mv_name, definition_text, blocker_hint)
            VALUES (v_schema, v_name, NULL, LEFT('UNREADABLE: ' || SQLERRM, 512));
        END;

        v_i := v_i + 1;
    END LOOP;

    -- Phase 3: Replace the contents of mv_definitions in a single transaction.
    -- DELETE (not TRUNCATE, which commits immediately) keeps the swap atomic:
    -- readers and concurrent runs see either the previous result or the new
    -- one, never a partly populated table.
    START TRANSACTION;
    DELETE FROM mv_definitions;
    INSERT INTO mv_definitions SELECT * FROM tmp_mv_definitions;
    COMMIT;
END;
$$ LANGUAGE plpgsql;
