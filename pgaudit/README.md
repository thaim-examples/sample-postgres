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
postgres=# create table sample (id int, name text);
CREATE TABLE
postgres=# insert into sample (id, name) values (1, 'test');
INSERT 0 1
postgres=# select * from sample;
 id | name
----+------
  1 | test
(1 row)
```

### check logs

```
docker compose logs  | grep LOG | grep AUDIT
db-1  | 2025-04-06 14:37:16.867 UTC [54] LOG:  AUDIT: SESSION,1,1,MISC,SET,,,set pgaudit.log = 'all';,<not logged>
db-1  | 2025-04-06 14:37:30.170 UTC [54] LOG:  AUDIT: SESSION,2,1,MISC,SET,,,set pgaudit.log_relation = 'on';,<not logged>
db-1  | 2025-04-06 14:38:17.671 UTC [54] LOG:  AUDIT: SESSION,3,1,DDL,CREATE TABLE,TABLE,public.sample,"create table sample (id int, name text);",<not logged>
db-1  | 2025-04-06 14:38:36.237 UTC [54] LOG:  AUDIT: SESSION,4,1,WRITE,INSERT,TABLE,public.sample,"insert into sample (id, name) values (1, 'test');",<not logged>
db-1  | 2025-04-06 14:38:46.031 UTC [54] LOG:  AUDIT: SESSION,5,1,READ,SELECT,TABLE,public.sample,select * from sample;,<not logged>
db-1  | 2025-04-06 14:58:50.530 UTC [154] LOG:  AUDIT: OBJECT,1,1,WRITE,INSERT,TABLE,public.sample,"insert into sample (id, name) values (2, 'objsession');",<not logged>
db-1  | 2025-04-06 14:58:53.313 UTC [154] LOG:  AUDIT: OBJECT,2,1,READ,SELECT,TABLE,public.sample,select * from sample;,<not logged>
```
