#!/bin/bash

# セッション監査用の設定
echo "pgaudit.log = 'all'" >> "${PGDATA}/postgresql.conf"
echo "pgaudit.log_relation = 'on'" >> "${PGDATA}/postgresql.conf"

# オブジェクト監査用
echo "pgaudit.role = 'auditor'" >> "${PGDATA}/postgresql.conf"
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
  -- 監査用のロールを作成
  CREATE ROLE auditor WITH NOLOGIN;

  -- ロール設定変更
  ALTER ROLE auditor SET pgaudit.log = 'all';

  -- 権限付与
  GRANT ALL ON ALL TABLES IN SCHEMA public TO auditor;
  ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO auditor;


  -- 拡張機能のインストール
  CREATE EXTENSION IF NOT EXISTS pgaudit;
EOSQL
