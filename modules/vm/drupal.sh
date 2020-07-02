sudo apt update
sudo apt-get install -y php php-curl php-gd php-sqlite3
mkdir /tmp/drupal/ && cd /tmp/drupal/

echo "Downloading Drupal"
wget https://www.drupal.org/download-latest/tar.gz
tar -zxvf *.gz -C /tmp/drupal --strip-components=1
sudo chown -R www-data:www-data /tmp/drupal/
sudo chmod -R 755 /tmp/drupal/

echo "Installing Apache"
yes | sudo apt install apache2 libapache2-mod-php
sudo systemctl start apache2.service
sudo systemctl enable apache2.service

echo "Install PHP 7.2 and Related Modules"
sudo apt-get install -y software-properties-common
sudo add-apt-repository -y ppa:ondrej/php
sudo add-apt-repository -y ppa:ondrej/apache2
sudo apt update
sudo apt install -y php7.2 libapache2-mod-php7.2 php7.2-common php7.2-mbstring php7.2-xmlrpc php7.2-soap php7.2-gd php7.2-xml php7.2-intl php7.2-mysql php7.2-cli php7.2-zip php7.2-curl
sudo sed -i "s/^max_execution_time.*/max_execution_time=120/"  /etc/php/7.2/apache2/php.ini

echo "Installing MySQL client"
sudo apt-get -y install mysql-client

echo "Create Drupal Database"
mysql -h $1.mysql.database.azure.com -u$2@$1 -p$3 -e "CREATE DATABASE drupaldb;"

echo "Configure Apache2 Drupal Site"
sudo sed -i "/ServerName/d" /etc/apache2/apache2.conf
echo "ServerName drupal.com" | sudo tee -a /etc/apache2/apache2.conf
echo '<VirtualHost *:80>
      ServerAdmin admin@drupal.com
      DocumentRoot /tmp/drupal/
      ServerName drupal.com
      ServerAlias www.drupal.com
      <Directory /tmp/drupal/>
            Options Indexes FollowSymLinks MultiViews
            AllowOverride ALL
            Order allow,deny
            Allow from all
            Require all granted
      </Directory>
      ErrorLog /var/log/apache2/error.log
      ServerSignature Off
      CustomLog /var/log/apache2/access.log combined
</VirtualHost>' > /tmp/drupal.conf
sudo mv /tmp/drupal.conf /etc/apache2/sites-available/drupal.conf
sudo rm -rf /etc/apache2/sites-enabled/*default*
cd /etc/apache2/sites-enabled
sudo rm -f /etc/apache2/sites-enabled/drupal.conf
sudo ln -s ../sites-available/drupal.conf drupal.conf
sudo su -c "echo '$4 drupal.com' >> /etc/hosts"

echo "Enable the Drupal Site"
sudo a2ensite drupal.conf
sudo a2enmod rewrite
sudo a2enmod env
sudo a2enmod dir
sudo a2enmod mime
sudo systemctl restart apache2.service

echo "Generate self sign certificate"
yes | sudo add-apt-repository ppa:certbot/certbot
sudo add-apt-repository universe
sudo apt-get update
yes | sudo apt-get install python3-certbot-apache

echo '<IfModule mod_ssl.c>
<VirtualHost *:443>
      ServerAdmin admin@drupal.com
      DocumentRoot /tmp/drupal/
      ServerName drupal.com
      ServerAlias www.drupal.com
      <Directory /tmp/drupal/>
            Options Indexes FollowSymLinks MultiViews
            AllowOverride ALL
            Order allow,deny
            Allow from all
            Require all granted
      </Directory>
      ErrorLog /var/log/apache2/error.log
      ServerSignature Off
      CustomLog /var/log/apache2/access.log combined
SSLCertificateFile /etc/letsencrypt/live/drupal.com/fullchain.pem
SSLCertificateKeyFile /etc/letsencrypt/live/drupal.com/privkey.pem
Include /etc/letsencrypt/options-ssl-apache.conf
</VirtualHost>
</IfModule>' > /tmp/drupal.com-le-ssl.conf
sudo mv /tmp/drupal.com-le-ssl.conf /etc/apache2/sites-available/drupal.com-le-ssl.conf