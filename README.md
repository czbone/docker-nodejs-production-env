# Docker Node.js Production Environment

本番VPS環境に**Docker + Node.js完全スタック**を自動構築するAnsible構成管理ツールです。

## 概要

このプロジェクトは、ローカルのVagrant環境を踏み台として、リモートVPSサーバーに本番環境を完全自動で構築します。

### 構築されるスタック

- **Node.js v24** - pnpmコマンドでビルドや実行できるNode.jsアプリケーション
- **Nginx** - リバースプロキシ / Webサーバー
- **MariaDB** - データベース
- **Redis** - キャッシュサーバー
- **Certbot** - Let's Encrypt SSL証明書の自動取得・更新

### 主要機能

- GitHubリポジトリからのアプリケーション自動デプロイ
- Let's Encrypt SSL証明書の自動取得・更新（週次cron）
- Dockerコンテナベースの分離された環境
- ログローテーション設定
- Nginx設定ファイルの自動監視・リロード
- タイムゾーン設定（Asia/Tokyo）

## 前提条件

### VPSサーバー要件

- **OS**: Ubuntu 24.04（推奨）
- **ポート開放**: 80（HTTP）、443（HTTPS）
- **DNS設定**: ドメインがVPSのIPアドレスに向いていること（SSL証明書取得に必須）
- **接続**: SSH公開鍵認証が設定済みであること

### ローカル環境

- **Vagrant**: 踏み台環境の構築に使用
- **VirtualBox**: Vagrantのプロバイダー

## 準備

### 1. SSH鍵の配置

VPSサーバーへの接続用秘密鍵ファイルを `ssh_keys/` ディレクトリに配置します。

```bash
# 鍵ペアを作成する場合
ssh-keygen -t ed25519 -f ssh_keys/vps_server.key -C "VPS接続用"

# 公開鍵をVPSサーバーの ~/.ssh/authorized_keys に追加
# 秘密鍵（.keyファイル）をssh_keys/ディレクトリに配置
```

**重要**: 秘密鍵ファイルのパーミッションを適切に設定してください（600推奨）。

### 2. hostlistファイルの設定

`hostlist.sample` を参考に `hostlist` ファイルを作成します。

```ini
[production_vps]
myserver ansible_host=203.0.113.10 ansible_ssh_user=ubuntu ansible_ssh_private_key_file=/vagrant/ssh_keys/vps_server.key

[production_vps:vars]
default_domain_name='example.com'
certbot_email='admin@example.com'
certbot_enabled=true
certbot_test_cert=0
ansible_become_password=your_sudo_password
```

#### hostlist 設定項目

##### サーバー定義（必須）

- `ansible_host`: VPSのIPアドレス
- `ansible_ssh_user`: SSH接続ユーザー名
- `ansible_ssh_private_key_file`: 秘密鍵ファイルのパス（Vagrant環境内からの相対パス: `/vagrant/ssh_keys/xxx.key`）

##### グループ変数（[グループ名:vars]セクション）

- `default_domain_name`: サービスのドメイン名またはサブドメイン名（**必須**）
- `certbot_email`: Let's Encrypt証明書用の連絡先メールアドレス（**SSL有効時は必須**）
- `certbot_enabled`: SSL証明書機能の有効化（`true` / `false`、デフォルト: `true`）
- `certbot_test_cert`: テストモード（`1`=テスト証明書、`0`=本番証明書）
- `ansible_become_password`: sudo実行時のパスワード（**必須**）
- `ansible_port`: 標準以外のSSHポートを使用する場合に指定（オプション）

### 3. 変数ファイルのカスタマイズ

`playbooks/vars/main.yml` を編集して、環境に合わせた設定を行います。

```yaml
# Node.jsバージョン
docker_container_node_version: 24

# データベース設定
db_root_password: 'your_secure_root_password'
main_db_name: 'sample-db'
main_db_user: 'sample_user'
main_db_password: 'your_secure_db_password'

# デプロイするアプリケーション
app_repo_owner: 'czbone'
app_repo_name: 'astro-nodejs-mariadb-starter'
app_repo_branch: 'main'
```

**重要**: 本番環境では、必ずデフォルトのパスワードを変更してください。

## デプロイ手順

### 1. Vagrant環境の起動

ローカルマシンでVagrant環境を起動します（初回は数分かかります）。

```bash
vagrant up
```

### 2. Vagrant環境へのログイン

```bash
vagrant ssh
```

### 3. Ansibleの実行

Vagrant環境内で以下のコマンドを実行します。

```bash
cd /vagrant
./provision.sh
```

プロビジョニングが完了すると、指定したドメインでNode.jsアプリケーションにアクセスできます。

## 構築される環境

### Dockerコンテナ一覧

| コンテナ名 | 役割 | 外部ポート | ネットワーク | 備考 |
|-----------|------|-----------|-------------|------|
| **nodejs** | Node.js v24アプリケーション | - | local-network | 内部ポート3000 |
| **nginx** | リバースプロキシ / Webサーバー | 80, 443 | local-network | 外部公開 |
| **mariadb** | データベース | - | local-network | 内部ポート3306 |
| **redis** | キャッシュサーバー | - | local-network | 内部ポート6379 |
| **certbot** | SSL証明書管理 | - | - | 週次cron実行 |

### VPS上のディレクトリ構成

```
/docker/
├── app/                    # Node.jsアプリケーションコード
│   ├── .env               # 環境変数ファイル
│   └── ...
├── mariadb/
│   ├── conf/              # MariaDB設定ファイル
│   └── data/              # データベースデータ（永続化）
├── redis/
│   └── data/              # Redisデータ（永続化）
├── nginx/
│   ├── conf/              # Nginx設定ファイル
│   │   └── conf.d/
│   │       └── default.conf
│   └── html/              # 静的ファイル
├── letsencrypt/
│   └── conf/              # SSL証明書
│       ├── live/
│       └── archive/
└── log/                   # ログファイル
    ├── nginx/
    │   ├── access.log
    │   └── error.log
    └── app/
        └── app.log
```

### デフォルトデータベース設定

- **データベース名**: `sample-db`
- **ユーザー名**: `sample_user`
- **パスワード**: `playbooks/vars/main.yml` で設定
- **rootパスワード**: `playbooks/vars/main.yml` で設定

## プロジェクト構成

```
.
├── hostlist                 # Ansible対象サーバーリスト（インベントリ）
├── hostlist.sample          # hostlistのサンプル
├── provision.sh             # Ansible実行スクリプト
├── Vagrantfile              # Vagrant設定（踏み台環境）
├── ssh_keys/                # VPS接続用秘密鍵
└── playbooks/
    ├── main.yml            # メインプレイブック
    ├── requirements.yml    # 外部ロール定義
    ├── vars/
    │   └── main.yml       # 設定変数
    ├── tasks/              # タスク定義
    │   ├── app.yml        # アプリデプロイタスク
    │   ├── nodejs.yml     # Node.jsコンテナ構築
    │   ├── nginx.yml      # Nginxコンテナ構築
    │   ├── mariadb.yml    # MariaDBコンテナ構築
    │   ├── redis.yml      # Redisコンテナ構築
    │   ├── certbot.yml    # SSL証明書取得・更新
    │   └── japanese.yml   # 日本語環境設定
    └── containers/         # Dockerfileテンプレート
        ├── nodejs/
        ├── nginx/
        ├── mariadb/
        ├── redis/
        └── certbot/
```

## 設定変数リファレンス

### playbooks/vars/main.yml

#### Node.js関連

- `docker_container_node_version`: Node.jsバージョン（デフォルト: `24`）

#### データベース関連

- `db_root_password`: MariaDB rootパスワード（**変更必須**）
- `main_db_name`: データベース名（デフォルト: `sample-db`）
- `main_db_user`: データベースユーザー名（デフォルト: `sample_user`）
- `main_db_password`: データベースユーザーパスワード（**変更必須**）

#### アプリケーション関連

- `app_repo_owner`: GitHubリポジトリのオーナー名
- `app_repo_name`: GitHubリポジトリ名
- `app_repo_branch`: デプロイするブランチ（デフォルト: `main`）

#### システム関連

- `timezone`: タイムゾーン（デフォルト: `Asia/Tokyo`）

### hostlist（グループ変数）

- `default_domain_name`: サービスのドメイン名またはサブドメイン名（**必須**）
- `certbot_enabled`: SSL証明書機能の有効化（`true` / `false`）
- `certbot_test_cert`: テスト証明書モード（`1` / `0`）
- `certbot_email`: Let's Encrypt連絡先メール（**SSL有効時は必須**）

## 運用管理

### ログ確認

```bash
# Nginxログ
sudo tail -f /docker/log/nginx/access.log
sudo tail -f /docker/log/nginx/error.log

# アプリケーションログ
sudo tail -f /docker/log/app/app.log

# Dockerコンテナログ
docker logs -f nodejs
docker logs -f nginx
docker logs -f mariadb

# journaldログ（コンテナ別）
journalctl CONTAINER_NAME=nodejs -f
```

### コンテナ管理

```bash
# コンテナ一覧確認
docker ps -a

# コンテナ再起動
docker restart nodejs
docker restart nginx

# 全コンテナ再起動
docker restart nodejs nginx mariadb redis

# コンテナ停止
docker stop nodejs

# コンテナ起動
docker start nodejs

# コンテナ状態確認
docker stats
```

### バックアップ

以下のディレクトリを定期的にバックアップしてください：

- **/docker/mariadb/data/** - データベースデータ
- **/docker/app/** - アプリケーションコード
- **/docker/letsencrypt/conf/** - SSL証明書
- **/docker/redis/data/** - Redisデータ（必要に応じて）

### SSL証明書の手動更新

```bash
# Certbotコンテナを手動実行
docker container start certbot

# 証明書の有効期限確認
docker exec nginx cat /etc/letsencrypt/live/example.com/cert.pem | openssl x509 -noout -dates
```

## トラブルシューティング

### SSL証明書取得に失敗する

**症状**: Certbotが証明書を取得できない

**対処方法**:

1. DNSレコードが正しく設定されているか確認
   ```bash
   nslookup example.com
   dig example.com
   ```

2. ポート80/443が開放されているか確認
   ```bash
   sudo netstat -tuln | grep -E ':80|:443'
   ```

3. テストモードで実行してみる（`hostlist`で`certbot_test_cert=1`に設定）

4. Certbotログを確認
   ```bash
   docker logs certbot
   ```

### Node.jsアプリケーションが起動しない

**症状**: ブラウザでアクセスできない、502 Bad Gateway

**対処方法**:

1. コンテナログを確認
   ```bash
   docker logs nodejs
   ```

2. コンテナが起動しているか確認
   ```bash
   docker ps | grep nodejs
   ```

3. 環境変数ファイルを確認
   ```bash
   cat /docker/app/.env
   ```

4. データベース接続を確認
   ```bash
   docker exec -it mariadb mysql -u sample_user -p -e "SHOW DATABASES;"
   ```

5. アプリケーションを手動で再起動
   ```bash
   docker restart nodejs
   ```

### Nginxがアクセスできない

**症状**: ブラウザで接続できない

**対処方法**:

1. コンテナ状態を確認
   ```bash
   docker ps | grep nginx
   ```

2. Nginx設定ファイルの文法チェック
   ```bash
   docker exec nginx nginx -t
   ```

3. エラーログを確認
   ```bash
   tail -f /docker/log/nginx/error.log
   ```

4. Nginxを再起動
   ```bash
   docker restart nginx
   ```

### データベース接続エラー

**症状**: アプリケーションがデータベースに接続できない

**対処方法**:

1. MariaDBコンテナが起動しているか確認
   ```bash
   docker ps | grep mariadb
   ```

2. データベースログを確認
   ```bash
   docker logs mariadb
   ```

3. データベース接続テスト
   ```bash
   docker exec -it mariadb mysql -u sample_user -p
   ```

4. `/docker/app/.env` ファイルの接続情報を確認

## カスタムアプリケーションのデプロイ

### アプリケーション要件

デプロイ可能なアプリケーションは以下の要件を満たす必要があります：

- **Node.js v24** 対応
- **package.json** が存在すること
- **pnpm** コマンドでビルド・実行が可能
  - ビルド: `pnpm install` → `pnpm build`
  - 実行: `pnpm start`
- **環境変数** でMariaDB、Redis接続情報を設定可能なこと
- **ポート3000** でリッスンすること（または環境変数 `PORT` で変更可能）

### デプロイ手順

#### 1. GitHubリポジトリを準備

アプリケーションコードをGitHubの公開リポジトリにプッシュします。

#### 2. playbooks/vars/main.yml を編集

```yaml
app_repo_owner: 'your-github-username'
app_repo_name: 'your-app-repository'
app_repo_branch: 'main'
```

#### 3. 環境変数テンプレートをカスタマイズ（必要に応じて）

`playbooks/containers/nodejs/templates/app_env.j2` を編集して、アプリケーションに必要な環境変数を追加します。

```env
PORT=3000
NODE_ENV=production

# Database
DB_HOST=mariadb
DB_PORT=3306
DB_NAME={{ main_db_name }}
DB_USER={{ main_db_user }}
DB_PASSWORD={{ main_db_password }}

# Redis
REDIS_HOST=redis
REDIS_PORT=6379

# カスタム環境変数を追加
YOUR_CUSTOM_VAR=value
```

#### 4. Ansibleを再実行

```bash
vagrant ssh
cd /vagrant
./provision.sh
```

アプリケーションが自動的にデプロイされます。

## セキュリティ注意事項

### 秘密鍵の管理

- **`ssh_keys/`** ディレクトリ内の秘密鍵は**絶対にGitにコミットしない**でください
- `.gitignore` で `ssh_keys/*.key` や `ssh_keys/*.pem` を除外してください
- 秘密鍵のパーミッションは **600** に設定してください

### パスワードの管理

- **`hostlist`** ファイルの `ansible_become_password` は平文で記載されます
  - このファイルをGitにコミットする場合は注意が必要です
  - 機密情報を含む場合は `.gitignore` に追加してください

- **`playbooks/vars/main.yml`** のパスワードは本番環境用に**必ず変更**してください
  - `db_root_password`
  - `main_db_password`

### ファイアウォール

- VPSのファイアウォールで、必要なポートのみ開放してください
  - **80 (HTTP)** - Let's Encrypt証明書取得に必要
  - **443 (HTTPS)** - HTTPS通信に必要
  - **22 (SSH)** - 管理用（必要に応じてポート変更を推奨）

### SSL証明書

- 本番環境では必ず **`certbot_test_cert=0`** に設定してください
- テスト証明書（`certbot_test_cert=1`）は、ブラウザで警告が表示されます
