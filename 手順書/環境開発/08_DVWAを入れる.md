# 手順書 08：DVWA を入れる

ゴール：**わざと穴だらけの練習アプリ「DVWA」をラズパイに置いて、
Mac のブラウザからログインできる**こと。

> ⚠️ **先に手順書 07（入口を Tailscale だけにする）を終えてから**やること。
> DVWA は穴だらけなので、マンション LAN から見える状態で置くと危険です。

---

## 0. DVWA って？（おさらい）

**D**amn **V**ulnerable **W**eb **A**pplication
＝「とんでもなく穴だらけのウェブアプリ」。
わざと脆弱に作られた、ハッキングの練習台です。

```
 左メニュー（攻撃の種類）
  ├ Brute Force   総当たり
  ├ SQL Injection DB を操る
  ├ XSS           悪い JS を仕込む
  └ File Upload   変なファイルを置く

 下の方に「DVWA Security」
  難易度 Low / Medium / High / Impossible
  （1個の中のスイッチ。上げると穴が塞がる）
```

今ある土台（Apache・PHP・MariaDB）の上に、PHP アプリとして置きます。

| 段階 | やること | どこで |
|---|---|---|
| 1 | DVWA を取ってくる | ラズパイ |
| 2 | Apache の見える場所に置く | ラズパイ |
| 3 | DVWA 用の DB と係の人を作る | ラズパイ |
| 4 | DVWA に「DB はこれ」と教える | ラズパイ |
| 5 | 書き込みの許可を直す | ラズパイ |
| 6 | ブラウザで初期設定して入る | Mac |

---

## 1. DVWA を取ってくる

**ラズパイの中**（`ssh homepi`）で打ちます。

### 1-1. git を使えるようにする（入っていなければ）

```bash
sudo apt install -y git
```

| 部分 | 意味 |
|---|---|
| `git` | インターネットから、まとまったファイルを取る道具 |

### 1-2. 取ってくる場所が本家か、自分で確かめる

そもそも何のため：DVWA という名前の置き場所は、1つではありません。
知らない人の写しを取ってこないように、**本家を自分で見分けます**。
ここは **Mac のブラウザ**で見るだけです（何も入れません）。

| 種類 | 正体 |
|---|---|
| `digininja/DVWA` | 本家。今の管理人の GitHub |
| fork | 本家を誰かが丸ごと写したもの。何千個もある |
| Docker 用（`vulnerables/web-dvwa` など） | 他人が箱詰めしたもの。古いものが多い |
| Kali Linux の `dvwa` パッケージ | Kali が本家を包み直したもの |

- fork（フォーク）＝分かれ道。食器のフォークと同じ言葉
- Kali Linux＝攻撃の練習用の道具がまとめて入った Linux

**探し方：2つの方向から確かめる**

```
 方向1：GitHub で「DVWA」を検索
   ↓
 候補がたくさん出る
   ↓
 3つの目印でふるいにかける
   ↓
 方向2：信用できる第三者が
        そこを指しているか見る
   ↓
 2つが同じ場所 → 本家
```

方向1の、3つの目印

| 目印 | 本家 | 写し |
|---|---|---|
| 名前の下の `forked from ○○` | 出ない | 出る（○○が元） |
| Star（星）の数 | とても多い | 0〜数個 |
| 最後に更新された日 | わりと最近 | 何年も前 |

- いちばん強い目印は `forked from`。
  写しには必ず元の名前が出るので、たどると本家に着く
- 名前の横の `Public` は「誰でも見られる」の意味。
  **公式の印ではない**（写しにも `Public` と出る。反対は `Private`）

方向2の、第三者の例

- Kali Linux の道具紹介ページ `kali.org/tools/dvwa`
- TryHackMe などの教材が、どこから取るよう書いているか
- パッケージがあれば `apt show dvwa` の `Homepage:` の欄
  （無いこともあるので、先に `apt search dvwa` で見る）

落とし穴：作った人と、今の管理人がちがう

- 最初に作ったのは Ryan Dewhurst さん（`ethicalhack3r`）
- あとから Robin Wood さん（`digininja`）が引き継いだ
- 古い記事の `ethicalhack3r/DVWA` を開くと、
  今は `digininja/DVWA` に自動で転送される
- 「古い記事と場所がちがう＝偽物」とは限らない。方向2で確かめる

確かめた記録（2026-11-11、`github.com/digininja/DVWA`）

| 目印 | 見えたもの |
|---|---|
| `forked from` | 出ていない |
| Star | 14.0k（約1万4千） |
| Fork | 5.3k（写しが約5千3百個ある＝写される側） |
| 最後の更新 | 3 weeks ago（3週間前） |

→ 本家でまちがいなし

### 1-3. DVWA を取ってくる

```bash
cd ~
git clone https://github.com/digininja/DVWA.git
```

| 部分 | 意味 |
|---|---|
| `cd ~` | 自分の家（`/home/kimuhiro`）に移動 |
| `git clone ...` | DVWA のファイル一式を丸ごと持ってくる |
| `digininja/DVWA` | DVWA 公式の置き場所（GitHub） |

→ `~/DVWA` というフォルダができれば OK

#### なぜ HTTPS の URL で取るのか

GitHub の緑の「Code」ボタンには、取ってくる道が3つ並んでいます。
中身は同じで、道がちがうだけです。

| 道 | 長所 | 短所 |
|---|---|---|
| HTTPS | 取るだけなら準備が要らない | push には合言葉（トークン）が要る |
| SSH | 鍵を登録すれば何も聞かれない | 鍵を作って GitHub に登録する手間 |
| GitHub CLI（`gh`） | issue なども扱える | `gh` を入れる必要がある |

- HTTPS＝ブラウザでページを見るときと同じ、鍵つきの通信
- GitHub CLI＝`gh` というコマンドの商品名
  （CLI＝Command Line Interface＝コマンドで操作するやり方）

今回 HTTPS にする理由は2つです。

1. DVWA は他人の公開リポジトリで、取ってくるだけ（push しない）。
   本人確認がそもそも要らない
2. **穴だらけの機械には、大事な鍵を置かない**

```
 SSH や gh を使うと
   ↓
 ラズパイに「自分の GitHub に入れる鍵」が残る
   ↓
 もし DVWA の穴から入られたら
   ↓
 鍵ごと持っていかれる
   ↓
 自分の GitHub まで危なくなる
```

入口は手順書 07 で Tailscale だけに絞ってあります。
それでも鍵を置かないのは、守りを1枚だけに頼らないためです
（多層防御＝defense in depth。defense＝守り、depth＝奥行き）。

| 1枚目（Tailscale）が破れる例 |
|---|
| Tailscale そのものに穴が見つかる |
| Tailscale のアカウントを、だまされて乗っ取られる |
| 仲間の機械（Mac・iPhone）が先に入られる |
| 自分で設定を戻してしまう（`Listen 80` に戻すなど） |

たとえ：玄関に鍵をかけても、通帳を玄関に置きっぱなしにはしない。
入られたときに、取られるものが無いようにしておく

---

## 2. Apache の見える場所に置く

### 2-1. 今ある中身をどかす

Apache は `/var/www/html` の中を見せます。
手順書 06 の `hello.php` を消したあとなら、ほぼ空のはずです。

```bash
ls /var/www/html
```

→ 次の2つだけならそのまま進む

| ファイル | 正体 |
|---|---|
| `index.html` | Apache の It works! ページ |
| `info.php` | 手順書 06 でわざと置いた穴（`phpinfo()` のページ） |

### 2-2. DVWA を置く

```bash
sudo mv ~/DVWA /var/www/html/dvwa
```

| 部分 | 意味 |
|---|---|
| `sudo` | 管理者として実行。`/var/www/html` は管理者の場所なので要る |
| `mv` | move＝動かす。フォルダを丸ごと移す（home からは無くなる） |
| `/var/www/html/dvwa` | 置き先。ブラウザでは `/dvwa/` で開く |

→ これで `http://homepi/dvwa/` が DVWA になります

- 練習で DVWA を壊したら、1-3 の `git clone` からやり直す
  （home に原本を残す `cp -r` ではなく `mv` にした。
  取り直すのも練習になるため。2026-11-11 に決めた）

---

## 3. DVWA 用の DB と係の人を作る

家計簿（`vuln_kakeibo`）とは別に、DVWA 専用の棚を作ります。
練習でぐちゃぐちゃにしても、家計簿に影響しないためです。

### 3-1. 合言葉を箱に入れる

```bash
read -r -s -p "DVWA DB password: " DV_PW; echo
```

→ DVWA 用に、新しく決めた合言葉を打って Enter（表示されない）

### 3-2. 棚と係の人を作る（6行まとめて貼る）

```bash
sudo mariadb <<SQL
CREATE DATABASE IF NOT EXISTS dvwa;
CREATE USER IF NOT EXISTS 'dvwa'@'localhost'
  IDENTIFIED BY '${DV_PW}';
GRANT ALL PRIVILEGES ON dvwa.*
  TO 'dvwa'@'localhost';
SQL
```

| 部分 | 意味 |
|---|---|
| `CREATE DATABASE ... dvwa` | DVWA 専用の棚 |
| `CREATE USER 'dvwa'@'localhost'` | ラズパイの中からだけ入れる係の人 |
| `GRANT ... ON dvwa.*` | dvwa の棚だけさわれる |

### 3-3. 箱を片付ける

```bash
unset DV_PW
```

---

## 4. DVWA に「DB はこれ」と教える

### 4-1. 設定ファイルを用意する

DVWA には設定の見本があるので、それをコピーして使います。

```bash
cd /var/www/html/dvwa/config
sudo cp config.inc.php.dist config.inc.php
```

| 部分 | 意味 |
|---|---|
| `config.inc.php.dist` | 設定の見本ファイル |
| `config.inc.php` | 本番の設定ファイル（これを DVWA が読む） |

### 4-2. DB の合言葉を書く

```bash
sudo nano config.inc.php
```

次の2行を探して、`db_user` と `db_password` を直します。

**変更前（見本の値）**
```
$_DVWA[ 'db_user' ] = 'dvwa';
$_DVWA[ 'db_password' ] = 'p@ssw0rd';
```

**変更後**
```
$_DVWA[ 'db_user' ] = 'dvwa';
$_DVWA[ 'db_password' ] = '3-1で決めた合言葉';
```

| 行 | 意味 |
|---|---|
| `db_user` | 3-2 で作った係の人の名前（`dvwa` のまま） |
| `db_password` | 3-1 で決めた合言葉に書きかえる |

- 保存：`Ctrl + O` → `Enter`、閉じる：`Ctrl + X`

---

## 5. 書き込みの許可を直す

DVWA は、設定や練習用のファイルを**自分で書き込みます**。
受付係（`www-data`）が書けるように、許可を渡します。

```bash
sudo chown -R www-data:www-data /var/www/html/dvwa
```

| 部分 | 意味 |
|---|---|
| `chown` | ファイルの持ち主を変える（change owner） |
| `-R` | 中のファイルも全部 |
| `www-data:www-data` | 持ち主を「受付係」にする |

- `www-data` は、ラズパイで Apache を動かしている係の名前です
  （手順書 06 で出てきた、力の弱い係）

---

## 6. ブラウザで初期設定して入る

### 6-1. セットアップ画面を開く（Mac）

**Mac のブラウザ**で開きます。

```
http://homepi/dvwa/setup.php
```

→ 下の方の **Create / Reset Database** ボタンを押す。
DVWA が、練習用のデータを DB に作ります。

- 画面に赤い文字（足りないもの）が出たら、スクショを Claude に貼る

### 6-2. ログインする

自動でログイン画面に移ります（移らなければ
`http://homepi/dvwa/login.php`）。

| 欄 | 入れるもの |
|---|---|
| Username | `admin` |
| Password | `password` |

→ 入れたら、左メニューがずらっと並ぶ画面になれば **成功！** 🎉

### 6-3. まず難易度を Low にする

左メニューの下の方の **DVWA Security** を開く。

```
Security Level: [ Low ▼ ]  → Submit
```

→ Low にして Submit。これで穴が全開の、遊べる状態です。

---

## 7. 遊び方（流れ）

```
 左メニューで攻撃を1つ選ぶ（例：SQL Injection）
   ↓
 TryHackMe で習った技を試す
   ↓
 破れた！
   ↓
 難易度を上げて、もう一度試す
   ↓
 Low と Impossible のコードを見比べて、
 「どう塞ぐか」を学ぶ
```

- DVWA の各ページに「View Source」ボタンがあり、
  その穴のコードを見られます
- 困ったり、英語が分からなければ、画面のスクショを Claude に貼る

---

## 困ったとき

| 症状 | よくある原因 | やること |
|---|---|---|
| `http://homepi/dvwa/` が Not Found | 2-2 の置き場所ちがい | `ls /var/www/html/dvwa` で中身があるか見る |
| setup.php が真っ白 | PHP の部品が足りない | 画面か、`sudo tail /var/log/apache2/error.log` を Claude に貼る |
| Create Database で赤いエラー | 4-2 の合言葉ちがい | 3-1 の合言葉と、config.inc.php を見直す |
| 6-2 でログインできない | admin / password を半角で打てていない | 英数キーを押して打ち直す |
| 設定が保存できない系 | 5 の許可忘れ | 5 をもう一度やる |

---

## 次の手順（予定）

- 自分の家計簿アプリを、わざと穴だらけで作り始める
- バックアップの仕組み（本物のデータを入れる前に）
