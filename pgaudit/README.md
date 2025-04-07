# pgaudit
pgAuditで監査ログを取得する。

## How to prepare

## check prepared results

```
$ docker compose exec db psql -U postgres

postgres=# SHOW shared_preload_libraries;
 shared_preload_libraries
--------------------------
 pgaudit
(1 row)

postgres=# SELECT * FROM pg_extension;
  oid  | extname | extowner | extnamespace | extrelocatable | extversion | extconfig | extcondition
-------+---------+----------+--------------+----------------+------------+-----------+--------------
 13564 | plpgsql |       10 |           11 | f              | 1.0        |           |
 16385 | pgaudit |       10 |         2200 | t              | 16.1       |           |
(2 rows)

postgres=# SHOW pgaudit.log;
 pgaudit.log 
-------------
 all
(1 row)

postgres=# SHOW pgaudit.role;
 pgaudit.role 
--------------
 auditor
(1 row)

postgres=# SHOW pgaudit.log_relation;
 pgaudit.log_relation 
----------------------
 on
(1 row)

postgres=# SELECT rolname, rolsuper, rolinherit, rolcreaterole,
       rolcreatedb, rolcanlogin, rolreplication, rolconnlimit,
       rolvaliduntil, rolbypassrls, rolconfig
FROM pg_roles
WHERE rolname = 'auditor';
 rolname | rolsuper | rolinherit | rolcreaterole | rolcreatedb | rolcanlogin | rolreplication | rolconnlimit | rolvaliduntil | rolbypassrls |     rolconfig
---------+----------+------------+---------------+-------------+-------------+----------------+--------------+---------------+--------------+-------------------
 auditor | f        | t          | f             | f           | f           | f              |           -1 |               | f            | {pgaudit.log=all}
(1 row)

postgres=# \ddp
              Default access privileges
  Owner   | Schema | Type  |    Access privileges
----------+--------+-------+--------------------------
 postgres | public | table | auditor=arwdDxt/postgres
(1 row)
```

## check audit logs
### example query

```
$ docker compose exec db psql -U postgres
postgres=# create table sample (id int, name text);
CREATE TABLE
postgres=# insert into sample (id, name) values (1, 'test'), (2, 'sample'), (3, 'hello');
INSERT 0 3
postgres=# select * from sample;
 id |  name
----+--------
  1 | test
  2 | sample
  3 | hello
(3 rows)

postgres=# update sample set name = 'hi' where id = 3;
UPDATE 1
postgres=# delete from sample where id = 2;
DELETE 1
postgres=# select * from sample;
 id | name
----+------
  1 | test
  3 | hi
(2 rows)

postgres=# drop table sample;
DROP TABLE
```

### check logs

```
$ docker compose logs  | grep AUDIT
db-1  | 2025-04-07 23:04:38.503 UTC [76] LOG:  AUDIT: SESSION,1,1,ROLE,GRANT,,,GRANT ALL ON ALL TABLES IN SCHEMA public TO auditor;,<not logged>
db-1  | 2025-04-07 23:04:38.506 UTC [76] LOG:  AUDIT: SESSION,2,1,ROLE,ALTER DEFAULT PRIVILEGES,,,ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO auditor;,<not logged>
db-1  | 2025-04-07 23:04:38.507 UTC [76] LOG:  AUDIT: SESSION,3,1,DDL,CREATE EXTENSION,,,CREATE EXTENSION IF NOT EXISTS pgaudit;,<not logged>
db-1  | 2025-04-07 23:05:07.350 UTC [76] LOG:  AUDIT: SESSION,4,1,DDL,CREATE TABLE,TABLE,public.sample,"create table sample (id int, name text);",<not logged>
db-1  | 2025-04-07 23:06:02.350 UTC [76] LOG:  AUDIT: OBJECT,5,1,WRITE,INSERT,TABLE,public.sample,"insert into sample (id, name) values (1, 'test'), (2, 'sample'), (3, 'hello');",<not logged>
db-1  | 2025-04-07 23:06:18.419 UTC [76] LOG:  AUDIT: OBJECT,6,1,READ,SELECT,TABLE,public.sample,"select * from sample;",<not logged>
db-1  | 2025-04-07 23:09:24.908 UTC [76] LOG:  AUDIT: OBJECT,7,1,WRITE,UPDATE,TABLE,public.sample,update sample set name = 'hi' where id = 3;,<not logged>
db-1  | 2025-04-07 23:09:42.738 UTC [76] LOG:  AUDIT: OBJECT,8,1,WRITE,DELETE,TABLE,public.sample,delete from sample where id = 2;,<not logged>
db-1  | 2025-04-07 23:09:48.727 UTC [76] LOG:  AUDIT: OBJECT,9,1,READ,SELECT,TABLE,public.sample,select * from sample;,<not logged>
db-1  | 2025-04-07 23:10:03.627 UTC [76] LOG:  AUDIT: SESSION,10,1,DDL,DROP TABLE,TABLE,public.sample,drop table sample;,<not logged>
```
