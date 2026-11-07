sudo apt update
sudo apt install apache2
sudo apt install php libapache2-mod-php \
  php-mysql php-mbstring
  echo '<?php echo "PHP " . PHP_VERSION;' \
  | sudo tee /var/www/html/hello.php