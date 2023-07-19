This stored procedure is designed to check the integrity of the FOREIGN KEY declared on a table and a column. If the foreign key doesn't have a primary key, it will raise an info.

## Prerequisites

The log table passed to this procedure must follow the below structure:


```
CREATE TABLE $(log_table) (
    batch_time   TIMESTAMP,
    check_table  VARCHAR,
    check_column VARCHAR,
    check_time   TIMESTAMP,
    check_status VARCHAR,
    error_count  INT);
```

## Parameters

The stored procedure takes the following parameters:

- `batch_time`: Timestamp for this batch. Can be used to group multiple fixes.
- `check_table`: Schema qualified name of table to be queried.
- `check_column`: Name of the column we want to check the integrity, must be a column in check_table.
- `log_table`: Schema qualified table where actions are to be logged.

## Example usage

First, ensure your log table is set up with the correct structure:

```
DROP TABLE IF EXISTS tmp_fk_log;
CREATE TABLE tmp_fk_log(
      batch_time   TIMESTAMP
    , check_table  VARCHAR
    , check_column VARCHAR
    , check_time   TIMESTAMP
    , check_status VARCHAR
    , error_count  INT);
```

Create the data tables. In this example, we create a customers table and an orders table:

```
DROP TABLE IF EXISTS customers CASCADE;
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
```

Populate the tables:

```
INSERT INTO customers (customer_name)
VALUES ('Alice'), ('Bob'), ('Charlie');
INSERT INTO orders (customer_id, order_date)
VALUES (1, '2023-01-01'),
       (2, '2023-01-02'),
       (3, '2023-01-03'),
       (4, '2023-01-04'); -- Inconsistency: customer_id 4 does not exist
```

Call the procedure:

```
CALL sp_check_foreign_key(SYSDATE,'orders', 'customer_id', 'tmp_fk_log');
```

In the above example, an inconsistency is deliberately introduced (customer_id 4 does not exist in customers table), so the procedure will log the error count and status in the tmp_fk_log table.
