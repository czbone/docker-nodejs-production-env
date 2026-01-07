#!/bin/bash
set -e

echo "Starting application initialization..."

# 依存サービスが利用可能になるまで待機
echo "Waiting for database to be ready..."
MAX_TRIES=10
RETRY_INTERVAL=5
count=0

# MariaDBの待機
while ! nc -z mariadb 3306; do
  if [ $count -eq $MAX_TRIES ]; then
    echo "Error: Timed out waiting for MariaDB to become available."
    exit 1
  fi
  echo "Waiting for MariaDB... ($(( count + 1 ))/$MAX_TRIES)"
  sleep $RETRY_INTERVAL
  count=$(( count + 1 ))
done
echo "MariaDB is available."

# パッケージのインストール
echo "Installing packages..."
cd /app
pnpm install

# Prisma クライアントの生成
echo "Generating Prisma client..."
pnpm db:generate

# データベース初期化
# 環境変数が設定されているか確認
if [ -f /app/.env ]; then
  echo "Running database schema management without shadow database..."
  
  # データベースを更新
  pnpm dlx prisma migrate deploy
  echo "Database schema has been applied."

  # 初期データインストール
  echo "Running data seeding..."
  pnpm db:seed
else
  echo "Warning: .env file not found, skipping database migrations"
fi

# アプリケーションのビルド
echo "Building application..."
pnpm build

# アプリケーション起動
echo "Starting application..."
exec pnpm start
