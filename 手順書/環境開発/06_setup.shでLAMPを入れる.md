# 手順書 06：Apache・PHP・MariaDB を入れて、setup.sh にまとめる

ゴール：
1. **1つずつ手で打って**、家計簿アプリを動かす土台（LAMP）を作る
2. 打ったコマンドを **`setup.sh` にまとめて**、壊れても1回で作り直せるようにする

---

## 0. 全体の流れ（たとえ話）

ラズパイを「お店」にたとえると、今は**建物と裏口の鍵**まではできています。
今回は、お店で働く3人を雇います。

| 層 | 係 | たとえ | 仕事 |
|---|---|---|---|
| L | Linux（済み） | 建物 | 全部の土台 |
| A | Apache | 受付係 | ブラウザの「このページちょうだい」を受ける |
| M | MariaDB | 倉庫係 | 家計簿のデータをしまう |
| P | PHP | 料理人 | 倉庫からデータを出して、ページを作る |

```
 スマホのブラウザ
   │「家計簿を見せて」
   ↓
 Apache（受付係）
   │「PHP さん、お願い」
   ↓
 PHP（料理人）
   │「MariaDB さん、データちょうだい」
   ↓
 MariaDB（倉庫係）
```

| 段階 | やること | どこで |
|---|---|---|
| 1 | なぜ「手で打つ → まとめる」の順なのか | 読むだけ |
| 2 | 1つずつ手で打って、3人を雇う | ラズパイ |
| 3 | 打ったコマンドを `setup.sh` にまとめる | Mac → ラズパイ |
| 4 | 気をつけること | 読むだけ |

---

## 1. なぜ「手で打つ → まとめる」の順なの？

```
 2. 手で打つ
    → 1つ入れるたびに、動くか確かめる
    → 何が起きたか、自分の目で見る
       ↓
 3. setup.sh にまとめる
    → 打ったコマンドを、レシピとして残す
    → 壊れたら、1回の実行で作り直せる
```

| | 手で打つ | `setup.sh` にまとめる |
|---|---|---|
| よいところ | 1つずつ何が起きたか分かる | 何度でも同じものが作れる |
| 弱いところ | やり直すとき、思い出すのが大変 | 中で何が起きたか見えにくい |

たとえると、料理を**一度自分で作ってみてから、レシピに書き残す**感じです。
両方やると、「理解している」と「作り直せる」の両方が手に入ります。

| やり方 | よく使う人 |
|---|---|
| 手で `apt install` | 入門記事・初めての人 |
| スクリプト（`setup.sh`） | 個人や小さいサーバー（DAM の `service_reg.sh` もこれ） |
| Ansible・Docker | 仕事の現場（何十台も同じにする） |

---

## 2. 1つずつ手で打つ

ここからは、**ラズパイの中**（`ssh homepi` で入った画面）で打ちます。
`[sudo] password for kimuhiro:` と出たら、ラズパイのパスワードを打ちます（**英数** キーを押してから）。

### 2-1. 道具の一覧を新しくする

```bash
sudo apt update
```

| 部分 | 意味 |
|---|---|
| `apt` | ラズパイのアプリストア（パッケージマネージャー）。Mac の brew と同じ役目 |
| `update` | 「今買える道具の一覧」を新しくする。**まだ何も入れない** |

たとえると、買い物の前に、お店の最新のチラシをもらってくる感じです。

→ 最後に `All packages are up to date.` か `〇 packages can be upgraded.` と出れば OK

### 2-2. 受付係（Apache）を雇う

```bash
sudo apt install apache2
```

| 部分 | 意味 |
|---|---|
| `install` | 道具を入れる |
| `apache2` | Apache（Web サーバー）の名前 |

→ `Do you want to continue? [Y/n]` と聞かれたら `y` で Enter

**確かめる：Mac のブラウザ**で開く

```
http://homepi/
```

→ **Apache2 Debian Default Page**（赤と白のページ）が出れば OK。
Tailscale のトンネルを通って、ラズパイの受付係が返事をしてくれています。

### 2-3. 料理人（PHP）を雇う

```bash
sudo apt install php libapache2-mod-php \
  php-mysql php-mbstring
```

| 道具 | 係 | 何のため？ |
|---|---|---|
| `php` | 料理人 | PHP 本体 |
| `libapache2-mod-php` | 受付係と料理人の連絡係 | Apache が PHP を呼べるようにする |
| `php-mysql` | 料理人と倉庫係の連絡係 | PHP から MariaDB につなぐ |
| `php-mbstring` | 料理人の日本語の辞書 | 日本語の文字を正しく数えたり切ったりする |

- 行の最後の `\` は「次の行に続くよ」という印です。2行まとめて貼って OK
- 写真を小さくする道具（`php-gd`）や、Claude API とお話しする道具（`php-curl`）は、使うときに足します（使わない機能は入れない）

**確かめる：試しのページを作る**

```bash
echo '<?php echo "PHP " . PHP_VERSION;' \
  | sudo tee /var/www/html/hello.php
```

| 部分 | 意味 |
|---|---|
| `echo '...'` | 1行の PHP を作る。「PHP のバージョンを表示して」という意味 |
| `\| sudo tee ...` | 作った1行を、管理者の権限でファイルに書く |
| `/var/www/html/` | 受付係がお客さんに見せるページの置き場所 |

**Mac のブラウザ**で開く

```
http://homepi/hello.php
```

→ `PHP 8.x.x` と出れば OK。受付係が料理人を呼べています。

### 2-4. 倉庫係（MariaDB）を雇う

```bash
sudo apt install mariadb-server
```

| 部分 | 意味 |
|---|---|
| `mariadb-server` | データベース本体。MySQL とほぼ同じもの |

**確かめる**

```bash
sudo mariadb -e "SELECT VERSION();"
```

| 部分 | 意味 |
|---|---|
| `sudo mariadb` | 倉庫係に、管理者として話しかける |
| `-e "..."` | 「これを聞いたら、すぐ帰るね」 |
| `SELECT VERSION();` | 「あなたのバージョンは？」 |

→ `11.x.x-MariaDB` のように出れば OK

### 2-5. 倉庫の棚と、係の人を作る

家計簿アプリ用の**棚（データベース）**と、その棚だけをさわれる**係の人（ユーザー）**を作ります。

| 作るもの | 名前 | たとえ |
|---|---|---|
| データベース | `vuln_kakeibo` | 家計簿専用の棚 |
| ユーザー | `vuln_kakeibo_app` | 家計簿アプリが倉庫に入るときの名前 |

**倉庫の合言葉を決める**

あとで家計簿アプリ（PHP）が倉庫に入るときに使う合言葉です。

| こと | 答え |
|---|---|
| どこにメモする？ | パスワード管理アプリなど。**手順書や Git には書かない**。Claude にも貼らない |
| 使える文字 | 英数字だけにする（`'` や `\` が入ると、SQL が壊れるため） |

**1行目：合言葉を箱に入れる**（手順書 02 の Wi-Fi のときと同じやり方）

```bash
read -r -s -p "DB password: " DB_PW; echo
```

| 部分 | 意味 |
|---|---|
| `read` | キーボードから文字を受け取る |
| `-r` | `\` をそのまま受け取る |
| `-s` | 打った文字を画面に出さない |
| `-p "..."` | 先に出す案内の文字 |
| `DB_PW` | 受け取った合言葉を入れる箱 |
| `; echo` | 改行だけ出す（次の表示がくっつかないように） |

→ `DB password:` と出たら、決めた合言葉を打って Enter（何も表示されないのが正常）

**2回目：棚と係の人を作る**（8行をまとめてコピーして、1回で貼る）

```bash
sudo mariadb <<SQL
CREATE DATABASE IF NOT EXISTS vuln_kakeibo
  CHARACTER SET utf8mb4;
CREATE USER IF NOT EXISTS 'vuln_kakeibo_app'@'localhost'
  IDENTIFIED BY '${DB_PW}';
GRANT ALL PRIVILEGES ON *.*
  TO 'vuln_kakeibo_app'@'localhost';
SQL
```

> 🕳️ **わざと穴：係の人が倉庫番と同じ力を持つ**（種類：②設定ミス）
> `ON *.*` は「全部の棚・全部の表」。ふつうは `ON vuln_kakeibo.*`（家計簿の棚だけ）に絞る。
> ここではわざと `*.*` にして、まず「どこからでも好き放題できる塊」にする（SQL インジェクションで入ったあと、`mysql` の棚＝係の名簿を読む・新しい係を作る・ファイルを書くなど）。
> あとで `ON vuln_kakeibo.*` に絞ると、そこで初めて「DB の中での権限昇格」のはしごが生まれる（絞られた所から、どう広げるか）。
> 塞ぐときは `ON vuln_kakeibo.*` に戻し、使う4つ（`SELECT, INSERT, UPDATE, DELETE`）だけにする。


| 部分 | 意味 |
|---|---|
| `<<SQL` 〜 `SQL` | ここから `SQL` までの行を倉庫係に渡す（手順書 03 の `EOF` と同じ仕組み） |
| `CREATE DATABASE IF NOT EXISTS vuln_kakeibo` | vuln_kakeibo の棚がなければ作る |
| `CHARACTER SET utf8mb4` | 文字の種類。日本語も絵文字も入る |
| `CREATE USER IF NOT EXISTS` | 係の人がいなければ登録する |
| `'vuln_kakeibo_app'@'localhost'` | 「ラズパイの中からだけ入れる vuln_kakeibo_app さん」 |
| `IDENTIFIED BY '${DB_PW}'` | 合言葉は、さっきの箱の中身 |
| `GRANT ALL PRIVILEGES ON *.*` | **全部の棚**を全部さわっていい（🕳️ わざと穴。ふつうは `vuln_kakeibo.*` に絞る） |

- 手順書 03 では `<<'EOF'` と `'` で囲みました。今回の `<<SQL` は囲みません。囲まないと、中の `${DB_PW}` が箱の中身に置きかわるからです
- 何も出なければ OK

**3回目：箱を片付ける**

```bash
unset DB_PW
```

→ 合言葉を箱から消す。使い終わったので片付ける

**確かめる：係の人として入れる？**

```bash
mariadb -u vuln_kakeibo_app -p -e "SHOW DATABASES;"
```

| 部分 | 意味 |
|---|---|
| `-u vuln_kakeibo_app` | vuln_kakeibo_app さんとして倉庫に入る |
| `-p` | 合言葉を聞いてね |
| `-e "SHOW DATABASES;"` | 「棚の一覧を見せて」と言って、すぐ出る |

→ `Enter password:` に倉庫の合言葉を打つ。一覧に `vuln_kakeibo` があれば OK

```
+--------------------+
| Database           |
+--------------------+
| information_schema |
| mysql              |
| performance_schema |
| sys                |
| vuln_kakeibo       |
+--------------------+
```

- `vuln_kakeibo` が一覧にあれば、棚と係の人は作れています
- **ほかの棚（`mysql` など）まで全部見えるのは、わざと `ON *.*` にした穴のせい**です（🕳️ わざと穴）。もし `ON vuln_kakeibo.*` に絞っていたら、`vuln_kakeibo` と `information_schema` の2つだけになります
- `mysql` は倉庫番の台帳（係の名簿・合言葉）。本来この係の人には見えてはいけない棚です

### 2-6. 片付け（→ わざと偵察の穴に変える）

試しの `hello.php` は役目を終えたので消します。
そのかわり、**わざと `phpinfo()` のページを置いて、偵察の穴にします**（2026-11-07 決定。C 案）。

> 🕳️ **わざと穴：phpinfo() で設定が丸見え**（種類：②設定ミス）
> `info.php` を開くと、PHP の版・設定・ファイルの置き場所・入っている拡張機能が全部見える。
> 攻撃者が偵察（recon）で一番うれしい情報源。OWASP でも定番の設定ミス。
> 突き方：ブラウザで `http://homepi/info.php` を開くだけ。置き場所を次の攻撃の手がかりにする。
> 塞ぎ方：`sudo rm /var/www/html/info.php` で消す。

```bash
echo '<?php phpinfo();' | sudo tee /var/www/html/info.php
sudo rm /var/www/html/hello.php
```

| 部分 | 意味 |
|---|---|
| `echo '...'` | 中の1行 PHP をそのまま出す |
| `\| sudo tee /var/www/html/info.php` | 管理者の力でファイルに書く（`tee`＝書く係。`-a` なしなので上書きで新規作成） |
| `sudo rm /var/www/html/hello.php` | 役目を終えた試しページを消す（`rm`＝remove＝消す） |

→ ブラウザで `http://homepi/info.php` を開き、設定がずらっと並んだ青い表が出れば OK（これがわざとの穴）

**ここで3人とも雇えました** 🎉 次は、今打ったものをレシピに書き残します。

---

## 3. 打ったコマンドを setup.sh にまとめる

### 3-1. 2 で打ったものと、setup.sh の対応

`setup.sh` の中身は、**2 で打ったコマンドとほぼ同じ**です。
それぞれを「関数」という名前付きの箱に入れて、`main` が順番に呼びます。

| 2 で打ったもの | `setup.sh` の関数 |
|---|---|
| 2-1 `sudo apt update` | `update_package_list` |
| 2-2 `sudo apt install apache2` | `install_apache` |
| 2-3 `sudo apt install php ...` | `install_php` |
| 2-4 `sudo apt install mariadb-server` | `install_mariadb` |
| 2-5 `read -r -s -p ...` | `ask_db_password` |
| 2-5 `CREATE DATABASE ...` | `create_database` |
| 2-5 `CREATE USER ...`・`GRANT ... ON *.*`（🕳️ 穴） | `create_db_user` |
| 2-6 `tee info.php`（🕳️ phpinfo の穴） | `create_info_page` |

確かめ（PHP が動くか試す `hello.php`）は、レシピには入れません。一度確かめれば十分だからです。
ただし `info.php`（phpinfo の穴）は「確かめ」ではなく**わざとの穴**なので、`setup.sh` に入れます。作り直しても同じ遊び台が建つように、です。
（方針：`setup.sh` は実物と一致させる。穴を塞ぐときは `setup.sh` も一緒に直す＝それ自体が塞ぐ練習）

### 3-2. 手で打つときとの違い

| 違い | 手で打つとき | `setup.sh` |
|---|---|---|
| `apt` と `apt-get` | `apt` | `apt-get`（スクリプトでは、表示が変わりにくい `apt-get` を使うのが決まり） |
| 「続けますか？」 | 自分で `y` | `-y` を付けて、自動で「はい」 |
| 途中で失敗したら | 自分で気づいて止まる | `set -euo pipefail` で自動で止まる |

### 3-3. どこに置く？

Mac のプロジェクトの中に置きます。

```
 ~/development/raspi/
  ├ 手順書/
  └ setup.sh   ← ここに作る
```

| なぜ Mac に置くの？ | |
|---|---|
| 手順書と同じ場所 | 探しやすい |
| あとで Git で管理できる | 変えた歴史が残る |
| ラズパイが壊れても残る | microSD を書き直しても、Mac から送り直せる |

### 3-4. 書く

**Mac のターミナル**で打つと、VS Code で空のファイルが開きます。

```bash
code ~/development/raspi/setup.sh
```

下の中身を書いて、保存（`⌘ + S`）します。
コピーしてもいいですが、**一度は全部読んで**、3-1 の表と見比べてください。

```bash
#!/bin/bash
# 家計簿サーバーの土台（Apache・PHP・MariaDB）を入れる。
# 壊れても作り直せるように、何度実行しても
# 同じ結果になるように書いている。

set -euo pipefail

readonly DB_NAME="vuln_kakeibo"
readonly DB_USER="vuln_kakeibo_app"

update_package_list() {
  sudo apt-get update
}

install_apache() {
  sudo apt-get install -y apache2
}

install_php() {
  sudo apt-get install -y \
    php libapache2-mod-php php-mysql php-mbstring
}

install_mariadb() {
  sudo apt-get install -y mariadb-server
}

ask_db_password() {
  local db_password
  read -r -s -p "DB password for ${DB_USER}: " db_password
  # 改行しないと、次の表示が同じ行にくっつくため
  echo >&2
  echo "$db_password"
}

create_database() {
  sudo mariadb <<SQL
CREATE DATABASE IF NOT EXISTS ${DB_NAME}
  CHARACTER SET utf8mb4;
SQL
}

create_db_user() {
  local db_password="$1"
  # コマンドの引数に書くと、ほかの人から
  # 一瞬見えることがあるので、<<SQL で渡す
  # 🕳️ わざと穴：ON *.* で、家計簿以外の棚（mysql など）も全部さわれる
  #    塞ぐときは ON ${DB_NAME}.* に戻し、使う4つ
  #    （SELECT, INSERT, UPDATE, DELETE）だけにする
  sudo mariadb <<SQL
CREATE USER IF NOT EXISTS '${DB_USER}'@'localhost'
  IDENTIFIED BY '${db_password}';
GRANT ALL PRIVILEGES ON *.*
  TO '${DB_USER}'@'localhost';
SQL
}

# 🕳️ わざと穴：phpinfo() のページを置く（PHP の設定が丸見え）
#    塞ぐときは sudo rm /var/www/html/info.php
create_info_page() {
  echo '<?php phpinfo();' | sudo tee /var/www/html/info.php
}

show_versions() {
  apache2 -v | head -n 1
  php -v | head -n 1
  mariadb --version
}

main() {
  update_package_list
  install_apache
  install_php
  install_mariadb

  local db_password
  db_password=$(ask_db_password)
  create_database
  create_db_user "$db_password"
  create_info_page

  show_versions
  echo "setup.sh: done"
}

main
```

### 3-5. 各部分の意味

**最初の部分**

| 部分 | 意味 |
|---|---|
| `#!/bin/bash` | 「このファイルは bash で動かしてね」という印 |
| `set -euo pipefail` | 安全装置（下の表） |
| `readonly DB_NAME="vuln_kakeibo"` | 棚の名前。`readonly` は「あとで書きかえない」という印 |
| `readonly DB_USER="vuln_kakeibo_app"` | 係の人の名前 |

**安全装置 `set -euo pipefail`**

| 文字 | 意味 | たとえ |
|---|---|---|
| `-e` | 途中でエラーが出たら、そこで止まる | 1段目で失敗したら、2段目を積まない |
| `-u` | 書いていない変数を使ったら止まる | 名前のつづり間違いに気づける |
| `-o pipefail` | `\|` でつないだコマンドのどれかが失敗したら止まる | 途中の失敗を見逃さない |

**合言葉を聞く関数 `ask_db_password`**

| 部分 | 意味 |
|---|---|
| `local db_password` | この関数の中だけで使う箱 |
| `read -r -s -p "..."` | 2-5 の1行目と同じ |
| `echo >&2` | 改行だけを画面に出す（`>&2` は「結果ではなく、画面の表示用に出す」） |
| `echo "$db_password"` | 受け取った合言葉を、呼んだ人（`main`）に返す |

**`main` のこの2行**

```bash
local db_password
db_password=$(ask_db_password)
```

| 部分 | 意味 |
|---|---|
| `$( ... )` | 中の関数を呼んで、返ってきた答えを受け取る |

### 3-6. ラズパイに送る

**Mac のターミナル**で打ちます。

```bash
scp ~/development/raspi/setup.sh homepi:~/
```

| 部分 | 意味 |
|---|---|
| `scp` | SSH の道を使って、ファイルを送る（secure copy） |
| `homepi:~/` | 送り先。ラズパイの、自分の家（`/home/kimuhiro/`） |

→ `setup.sh  100%` のように出れば OK（手順書 05 で鍵にしたので、パスワードは聞かれません）

### 3-7. レシピが正しいか、試しに実行する

**ラズパイの中**で打ちます。

```bash
bash ~/setup.sh
```

もう 2 で全部入れてあるので、**2回目の実行**になります。
何度実行しても壊れないように書いてあるので、大丈夫です。

| 2回目の実行で | どうなる？ |
|---|---|
| もう入っている道具 | `is already the newest version`（もう最新だよ）と言って、何もしない |
| もうある棚 | `IF NOT EXISTS` なので、何もしない |
| もういる係の人 | `IF NOT EXISTS` なので、何もしない（合言葉も変わらない） |

- `DB password for vuln_kakeibo_app:` と聞かれたら、2-5 と同じ合言葉を打つ
- 最後にこう出れば成功です（数字は少し違ってもいい）

```
Server version: Apache/2.4.x (Debian)
PHP 8.x.x (cli) ...
mariadb from 11.x.x-MariaDB ...
setup.sh: done
```

これで、レシピが正しく書けていることが分かりました。
ラズパイを作り直したときは、`bash ~/setup.sh` の1回で 2 の全部ができます。

---

## 4. 気をつけること（次の手順につながる話）

| こと | 今の状態 |
|---|---|
| 倉庫係（MariaDB） | ラズパイの中からしか話しかけられない（最初からそういう設定） ✅ |
| 受付係（Apache） | トンネルだけでなく、**マンションの LAN からも**話しかけられる ⚠️ |

```
 Apache の入口
  ├ Tailscale のトンネル ← 自分と彼女だけ ✅
  └ マンションの LAN     ← 他の住人も？ ⚠️
```

マンションの LAN でも住人どうしが話せない設定（セパレーター）があるかもしれませんが、有線でも同じかは分かっていません。
なので、**本物の家計簿のデータを入れる前に**、入口をトンネルだけに絞ります（手順書 07）。

---

## 困ったとき

| 症状 | よくある原因 | やること |
|---|---|---|
| `Could not resolve` や `Temporary failure` | ラズパイがネットに出られない | `ping -c 3 deb.debian.org` を打って、結果を Claude に貼る |
| `Could not get lock` | ラズパイが裏で自動アップデート中 | 5分待って、もう一度 |
| 2-2 でページが出ない | Mac の Tailscale が止まっている | メニューバーで Connect |
| 2-3 で PHP の文字がそのまま出る | 連絡係（`libapache2-mod-php`）が働いていない | `sudo systemctl restart apache2` を打って、開き直す |
| 2-5 で `ERROR 1064` | SQL の打ち間違い | 8行をもう一度コピーして貼る |
| 2-5 の確かめで `Access denied` | 倉庫の合言葉の打ち間違い | **英数** キーを押してから、もう一度 |
| 3-6 で `No such file or directory` | 3-4 で保存した場所がちがう | `ls ~/development/raspi/` で `setup.sh` があるか見る |
| 3-7 で途中で止まった | `setup.sh` の書き間違い | 止まる前後の文字を Claude に貼る |

---

## 次の手順（予定）

- 07：Apache の入口をトンネル（Tailscale）だけにする
- そのあと：家計簿アプリの最小の画面をラズパイに載せる
