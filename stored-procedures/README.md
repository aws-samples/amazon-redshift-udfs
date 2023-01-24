# Redshift Stored Procedures
Sample and Usefull Stored Procedures

| Procedure                                                | Description                                                                           |
| ---------------------------------------------------------| --------------------------------------------------------------------------------------|
| [`sp_analyze_minimal.sql`](./sp_analyze_minimal)           | Analyze **one** column of a table. To be used on a staging table right after loading  |
| [`sp_check_primary_key.sql`](./sp_check_primary_key)       | Check the integrity of the PRIMARY KEY declared on a table                            |
| [`sp_connect_by_prior.sql`](./sp_connect_by_prior)         | Calculate levels in a nested hierarchy tree                                           |
| [`sp_controlled_access.sql`](./sp_controlled_access)       | Provide controlled access to data without granting permission on the table/view       |
| [`sp_pivot_for.sql`](./sp_pivot_for)                       | Transpose row values into columns                                                     |
| [`sp_split_table_by_range.sql`](./sp_split_table_by_range) | Split a large table into parts using a numeric column                                 |
| [`sp_sync_get_new_rows.sql`](./sp_sync_get_new_rows)       | Sync new rows from a source table and insert them into a target table                 |
| [`sp_sync_merge_changes.sql`](./sp_sync_merge_changes)     | Sync new and changed rows from a source table and merge them into a target table      |
| [`sp_update_permissions.sql`](./sp_update_permissions)     | Reads user, group and role permission matrix from S3 and updates authorization in Redshift|
