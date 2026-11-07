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

## 3. setup.sh を少しずつ組み立てる

そもそも：`setup.sh` は「実行すると、2 でやったことが
全部もう一度おきる"レシピ"」です（記録ではなく、動く台本）。
ここでは完成形を一気に書きません。
**一番小さい形を動かして、1つずつ足します**。

進め方のクセ（大事）：
- まず `echo`（文字を出すだけ）で「形」を練習する
  → Mac ですぐ動かせる
- 形に慣れたら、中身を本物のコマンド（apt-get など）に替える
- 本物の入れかえは、ラズパイで動かす（Mac に apt-get は無い）

練習用のファイルを1つ作ります（本番とは別。あとで消す）。

```bash
code ~/development/raspi/practice.sh
```

### 3-1. まず「1行だけ」動かす

中身をこれだけ書いて保存：

```bash
#!/bin/bash
echo "こんにちは"
```

- `#!/bin/bash`（シェバン）＝このファイルは bash で動かす、の印
- `echo "..."`＝文字を画面に出す

Mac のターミナルで動かす：

```bash
bash ~/development/raspi/practice.sh
```

→ `こんにちは` と出れば成功。これが「.sh を動かす」最小形です。

### 3-2. その1行を「関数（箱）」に入れる

関数＝名前をつけた箱。中のコマンドをまとめて、名前で呼べます。

書きかえて保存：

```bash
#!/bin/bash

say_hello() {
  echo "こんにちは"
}

say_hello
```

形の見方：

```
say_hello()   箱の名前 ＋ ()
{             中身のはじまり
  echo ...    やること
}             中身のおわり

say_hello     箱を呼ぶ（名前だけ）
```

- `()` は中身が空でも必ず付ける
- 一番下の `say_hello` を書かないと、箱を作っただけで
  誰も呼ばない＝何も起きない

動かす：`bash ~/development/raspi/practice.sh`
→ さっきと同じ `こんにちは`。
**箱に入れても結果は同じ**。これが関数の正体です。

### 3-3. 箱を2つにして、main（まとめ役）に呼ばせる

箱が増えたら、「どの順で呼ぶか」をまとめる箱＝`main` を作る。

```bash
#!/bin/bash

say_hello() {
  echo "こんにちは"
}

say_bye() {
  echo "さようなら"
}

main() {
  say_hello
  say_bye
}

main
```

- `main`＝指揮者。どの箱を・どの順で呼ぶかを書くだけ
- 一番下は `main` を1回呼べばいい（main の中が順に動く）

動かす → `こんにちは` → `さようなら`。
**これで setup.sh の骨組み（関数 ＋ main）が手に入りました。**
ここまで Mac だけで練習できます。

### 3-4. 中身を本物にする（同じ形のくり返し）

骨組みは同じで、箱の中の `echo` を、2 で打った本物の
コマンドに入れかえるだけ。
ここからは本物の `~/development/raspi/setup.sh` に書きます。

まず1つめ。2-1（`sudo apt update`）を箱にして、main から呼ぶ：

```bash
#!/bin/bash

update_package_list() {
  sudo apt-get update
}

main() {
  update_package_list
}

main
```

- 手で打つときは `apt`、スクリプトでは `apt-get`
  （表示が変わりにくく、台本向き）

2つめ。`install_apache` を足して、main からも呼ぶ：

```bash
install_apache() {
  sudo apt-get install -y apache2
}
```

main に1行足す：

```bash
main() {
  update_package_list
  install_apache
}
```

- `-y`（yes）＝「続けますか?」に自動で「はい」。
  台本は人が見ていないので

**あとは同じ形のくり返し**。箱を足して main に1行足す：

| 足す箱 | 中のコマンド |
|---|---|
| `install_php` | `sudo apt-get install -y php libapache2-mod-php php-mysql php-mbstring` |
| `install_mariadb` | `sudo apt-get install -y mariadb-server` |

- php の行は長いので `\`（行の続き）で2行に分けてよい

### 3-5. 安全装置と、名前の箱を足す

ファイルの上の方（シェバンの下）に2つ足す。

```bash
set -euo pipefail

readonly DB_NAME="vuln_kakeibo"
readonly DB_USER="vuln_kakeibo_app"
```

`set -euo pipefail`＝失敗したら勝手に止まる安全装置：

| 文字 | 意味 |
|---|---|
| `-e` | コマンドが失敗したら、そこで止まる |
| `-u` | 書いてない変数を使ったら止まる（打ち間違い対策） |
| `-o pipefail` | `\|` の途中が失敗しても止まる |

`readonly`＝あとで書きかえない箱。
棚の名前・係の名前を1か所に決めておくと、下で
`${DB_NAME}` と呼び出せる（名前を1か所で管理）。

### 3-6. 新しい形の箱を5つ（ここだけ少し新しい）

2-5・2-6 で新しく出た形なので、1つずつ。

(1) パスワードを聞く箱：

```bash
ask_db_password() {
  local db_password
  read -r -s -p "DB password for ${DB_USER}: " db_password
  echo >&2
  echo "$db_password"
}
```

- `local`＝この箱の中だけで使う変数（外に漏らさない）
- `read ... db_password`＝打った文字を `db_password` の箱に入れる。
  **`read` の後ろの言葉は"箱の名前"**。パスワードそのものではない
- `-r`＝`\` を特別扱いしない、`-s`＝画面に出さない、
  `-p "..."`＝聞くときの文
- `echo >&2`＝改行を1つ出す（`-s` で消えた改行の代わり）
- `echo "$db_password"`＝箱の中身を"外に渡す"（下の main が受け取る）

(2) 棚を作る箱（`<<SQL` が新しい）：

```bash
create_database() {
  sudo mariadb <<SQL
CREATE DATABASE IF NOT EXISTS ${DB_NAME}
  CHARACTER SET utf8mb4;
SQL
}
```

- `<<SQL` 〜 `SQL`＝この間の行を、まとめて倉庫番（mariadb）に
  渡す（手紙）。手順書 03 の EOF と同じ仕組み
- 閉じの `SQL` は**行の左はしに**書く（前に空白を入れない）

(3) 係の人を作る箱（手紙＋受け取ったパスワード）：

```bash
create_db_user() {
  local db_password="$1"
  sudo mariadb <<SQL
CREATE USER IF NOT EXISTS '${DB_USER}'@'localhost'
  IDENTIFIED BY '${db_password}';
GRANT ALL PRIVILEGES ON *.*
  TO '${DB_USER}'@'localhost';
SQL
}
```

- `local db_password="$1"`＝main から渡された1つめの値を受け取る
- 🕳️ わざと穴：`ON *.*`（家計簿以外の棚も全部さわれる）。
  塞ぐときは `ON ${DB_NAME}.*` に戻し、使う4つだけにする

(4) phpinfo の穴を置く箱：

```bash
create_info_page() {
  echo '<?php phpinfo();' | sudo tee /var/www/html/info.php
}
```

- 🕳️ わざと穴：PHP の設定が丸見え。
  塞ぐときは `sudo rm /var/www/html/info.php`

(5) 最後に版を表示する箱（確認）：

```bash
show_versions() {
  apache2 -v | head -n 1
  php -v | head -n 1
  mariadb --version
}
```

### 3-7. main に全部つなぐ

指揮者の main に、呼ぶ順を書く。
パスワードだけ「受け取って次に渡す」のが少し特別。

```bash
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

- `db_password=$(ask_db_password)`＝箱が"外に渡した"文字を
  受け取る（`$( )`＝中のコマンドの結果を取り込む）
- `create_db_user "$db_password"`＝その合言葉を、係を作る箱に
  渡す（箱の中で `$1` になる）

### 3-8. ラズパイで1回だけ動かす

setup.sh はラズパイ用（Mac に apt-get は無い）。送って動かす。

```bash
scp ~/development/raspi/setup.sh homepi:~/
```

- `scp`（secure copy＝安全なコピー）＝SSH の鍵でファイルを送る。
  `homepi:~/`＝ラズパイの自分の部屋に置く

ラズパイで動かす：

```bash
ssh homepi
bash ~/setup.sh
```

- `DB password for ...` と聞かれたら、2-5 と同じ合言葉を打つ
- もう 2 で手作業で作ってあるので、多くは「もう最新」「もう在る」
  と出る（それで正常。何度流しても同じ結果＝レシピの良さ）
- 最後にこう出れば成功（数字は少し違ってもいい）：

```
Server version: Apache/2.4.x (Debian)
PHP 8.x.x (cli) ...
mariadb from 11.x.x-MariaDB ...
setup.sh: done
```

練習用の `practice.sh` は、もう消して OK：

```bash
rm ~/development/raspi/practice.sh
```

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
