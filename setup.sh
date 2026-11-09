#!/bin/bash

#set -eでerror時停止、-uで変数にunset時停止、
#-oでoptionフラグのpipefailで途中で１つでも上手くいってないと失敗扱いとなる
set -euo pipefail

readonly DB_NAME="vuln_kakeibo"
readonly DB_USER="vuln_kakeibo_app"

update_package_list() {
  sudo apt-get update
}
install_apache(){
  sudo apt-get install -y apache2
}
install_php(){
  sudo apt-get install -y php libapache2-mod-php php-mysql php-mbstring
}
install_mariadb(){
  sudo apt-get install -y mariadb-server
}
ask_db_password(){
  local db_password
  read -r -s -p "DB password for ${DB_USER}: " db_password
  echo >&2
  echo "$db_password"
}
create_database() {
  sudo mariadb <<SQL
CREATE DATABASE IF NOT EXISTS ${DB_NAME}
  CHARACTER SET utf8mb4;
SQL
}
#local db_password="$1"`＝main から渡された1つめの値を受け取る
# わざと穴：`ON *.*`（家計簿以外の棚も全部さわれる）。
#塞ぐときは `ON ${DB_NAME}.*` に戻し、使う4つだけにする
create_db_user() {
  local db_password="$1"
  sudo mariadb <<SQL
CREATE USER IF NOT EXISTS '${DB_USER}'@'localhost'
  IDENTIFIED BY '${db_password}';
GRANT ALL PRIVILEGES ON *.*
  TO '${DB_USER}'@'localhost';
SQL
}
# わざと穴：PHP の設定を丸見えにしてる
# 塞ぐときは `sudo rm /var/www/html/info.php`
create_info_page() {
  echo '<?php phpinfo();' | sudo tee /var/www/html/info.php
}
show_versions() {
  apache2 -v | head -n 1
  php -v | head -n 1
  mariadb --version
}

main(){
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