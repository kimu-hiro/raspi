ラズパイ接続コマンド :

よく使うコマンド
どこで打つかが大事。Mac で打つものと、ラズパイの中（kimuhiro@homepi:~ $ と出ている画面）で打つものがある。

入る・出る（Mac で打つ）
やりたいこと	コマンド	メモ
ラズパイに入る	ssh homepi	合鍵で入る。パスワードは聞かれない。Mac の Tailscale が Connected のとき。家でも外でも同じ
名前で入れないとき	ssh -i ~/.ssh/homepi kimuhiro@100.101.64.85	トンネルの中のラズパイの番号。合鍵を指定する
ラズパイが生きているか見る	Tailscale のアプリで homepi に緑の●	offline なら電源を入れ直す
Mac からラズパイにファイルを送る	scp ファイル名 homepi:~/	ラズパイの自分の家（/home/kimuhiro/）に届く
止める・再起動（ラズパイの中で打つ）
やりたいこと	コマンド	メモ
安全に電源を切る	sudo shutdown -h now	緑ランプが止まってから USB-C を抜く。いきなり抜くと microSD が壊れることがある
再起動	sudo reboot	SSH は切れる。1〜3分待ってから入り直す
ラズパイから出る	exit	ラズパイは動いたまま。SSH の電話を切るだけ
様子を見る（ラズパイの中で打つ）
やりたいこと	コマンド	OK の目安
電気が足りているか	vcgencmd get_throttled	throttled=0x0
メモリ	free -h	available が多ければ OK
microSD の空き	df -h /	Use% が 80% 未満
有線でつながっているか	nmcli device status	eth0 が connected
どの道で外に出ているか	ip route | grep default	一番上の行が dev eth0（有線）
トンネルの様子	tailscale status	homepi と Mac が並ぶ
起動の記録が残っているか	journalctl --list-boots --no-pager	起動ごとに1行。0 が今回、-1 が1回前
困ったとき
場面	コマンド・やること
外から入れない	家に帰って、ラズパイの電源を入れ直す（3分待つ）
ラズパイが落ちた理由を知りたい	電源を入れ直して入り、手順書 03 の 3 のコマンドの結果を Claude に貼る（日記は消えない設定にしてある）
ssh homepi で「Enter passphrase」と聞かれた	合鍵の合言葉を打つ（ラズパイのパスワードではない）
sudo でパスワードを聞かれた	ラズパイのパスワードを打つ（合鍵にしても sudo はパスワードのまま）。英数キーを押してから
有線が使えない	ラズパイは予備としてマンションの Wi-Fi に自動でつなぐ（夕方は混んでつながりにくい）
Wi-Fi も使えない	iPhone のテザリングをオン（互換性を優先もオン）→ ラズパイが予備として自動でつなぐ
テザリング中にラズパイの番号を探す（Mac で）	for i in $(seq 2 14); do ping -c 1 -t 1 172.20.10.$i > /dev/null && echo "172.20.10.$i いる"; done

パスワードと合言葉（4つ。全部別物）
名前	使う場面
Mac のログイン	Mac を開くとき
ラズパイ（homepi）のパスワード	ラズパイの中で sudo を使うとき（入るときは、もう使わない）
合鍵の合言葉（passphrase）	ssh homepi で Enter passphrase と聞かれたとき。Mac のキーチェーンが覚えているので、ふだんは聞かれない
倉庫（MariaDB）の合言葉	家計簿アプリが倉庫に入るとき（手順書 06 で決める）

くわしいやり方と理由は、プロジェクト内の 手順書/ にある
