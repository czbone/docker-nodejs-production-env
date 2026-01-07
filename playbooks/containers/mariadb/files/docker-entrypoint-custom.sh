#!/bin/bash
set -e

echo "MariaDB custom entrypoint: Starting tc.log cleanup..."

# tc.logファイルが存在する場合は削除（起動時に毎回チェック）
TC_LOG_PATH="/var/lib/mysql/tc.log"
if [ -f "$TC_LOG_PATH" ]; then
  echo "Found tc.log file at $TC_LOG_PATH. Removing to prevent startup errors..."
  rm -f "$TC_LOG_PATH"
  echo "tc.log file has been removed."
else
  echo "No tc.log file found at $TC_LOG_PATH."
fi

# その他の関連するMariaDBの一時ファイルもクリーンアップ
ARIA_LOG_CONTROL="/var/lib/mysql/aria_log_control"
if [ -f "$ARIA_LOG_CONTROL" ]; then
  echo "Found aria_log_control file. Removing it as well..."
  rm -f "$ARIA_LOG_CONTROL"
  echo "aria_log_control file has been removed."
fi

echo "tc.log cleanup completed. Starting original MariaDB entrypoint..."

# 元のエントリーポイントを実行
exec /usr/local/bin/docker-entrypoint-original.sh "$@"
