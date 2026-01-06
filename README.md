# 概要

Ansible実行テスト用の仮想環境(Ubuntu24)です。サーバー接続の設定の確認、および基本的なAnsibleプレイブックの実行ができます。

## 実行前の主な注意点

- 環境構築する対象サーバのOSは最新にアップデートしておく
- 秘密鍵ファイルのパーミッションが適切に設定されていること（600などの制限付き権限）

## 準備

1. 接続先の対象サーバの接続ユーザの`~/.ssh/authorized_keys`に公開鍵ファイル(.pub)を格納します。(VPS初期構築時の設定)
2. 対象サーバの接続ユーザの秘密鍵ファイル(.key)を`ssh_keys`ディレクトリに格納します。
3. 接続情報を`hostlist`ファイルに設定します。以下の点に注意してください：
   - 接続ユーザ名が正しいこと
   - 秘密鍵ファイルのパスが正しいこと
   - 使用しないサーバーの行はコメントアウトすること

## 実行方法

1. VagrantでAnsible実行環境(Ubuntu 24.04)を構築します。

```
> vagrant up
```

2. 仮想環境にログインし、シェルを実行して目的のサーバに対しAnsibleを実行します。

```
> vagrant ssh

$ cd /vagrant
$ ./provision.sh
```

## プロジェクト構成

- `hostlist`: Ansibleの対象サーバーリスト（インベントリファイル）
- `provision.sh`: Ansibleプレイブックを実行するためのシェルスクリプト
- `Vagrantfile`: Ubuntu 24.04の仮想環境構成ファイル
- `playbooks/`: 
  - `main.yml`: メインのAnsibleプレイブック
  - `requirements.yml`: 必要なAnsibleロールの依存関係定義
- `ssh_keys/`: サーバー接続用の秘密鍵ファイル

## カスタマイズ方法

1. プレイブックのカスタマイズは`playbooks/main.yml`を編集してください
2. 新しいサーバーを追加する場合は`hostlist`ファイルに設定を追加してください
3. 必要に応じてタスクやロールを追加して機能を拡張できます

## hostlistの仕様

Ansibleのインベントリファイルです。このファイルには接続対象サーバーの情報を記述します。

### ファイル形式

- INI形式で記述します（セミコロン`;`または`#`でコメント行を示します）
- サーバーグループを`[グループ名]`で定義します
- グループ内の各サーバーを1行で定義します
- グループ変数は`[グループ名:vars]`セクションで定義します

### 必須パラメータ

各サーバー行に以下のパラメータを指定する必要があります：

- `ansible_host`: サーバーのIPアドレスまたはホスト名
- `ansible_ssh_user`: SSH接続に使用するユーザー名
- `ansible_ssh_private_key_file`: 認証に使用する秘密鍵ファイルのパス（Vagrant環境内からの相対パス）

### オプションパラメータ

必要に応じて以下のパラメータも指定できます：

- `ansible_become_password`: suまたはsudo時のパスワード（グループ変数として定義可能）
- `ansible_port`: 標準以外のSSHポートを使用する場合に指定

### 例

```ini
[example_vps]
server1 ansible_host=192.168.1.100 ansible_ssh_user=ubuntu ansible_ssh_private_key_file=/vagrant/ssh_keys/server1.key

[example_vps:vars]
default_domain_name='example.com'
certbot_email='admin@example.com'
ansible_become_password=secure_password_here
```

## ssh_keysディレクトリの仕様

このディレクトリには、リモートサーバーへの接続に必要な秘密鍵ファイルを格納します。

### 重要な注意点

- すべての秘密鍵ファイルはこのディレクトリに配置してください
- ファイル名は任意ですが、`.key`や`.pem`などの拡張子を使用することを推奨します
- 秘密鍵ファイルのパーミッションは適切に設定してください（600など）
- このディレクトリ内のファイルはバージョン管理システムにコミットしないでください
- `.gitignore`ファイルでこのディレクトリ内の鍵ファイルを除外することを推奨します

### 秘密鍵ファイルの作成方法

必要に応じて以下のコマンドで鍵ペアを作成できます：

```bash
ssh-keygen -t ed25519 -f ssh_keys/server_name.key -C "サーバー名や用途のコメント"
```

公開鍵（`.pub`ファイル）をリモートサーバーの`~/.ssh/authorized_keys`に追加し、秘密鍵（`.key`ファイル）をこのディレクトリに保管します。
