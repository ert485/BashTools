#!/bin/bash

PROJECT_NAME="test"
MYSQL_DATABASE="laravel"
MYSQL_PASS="secret58bh"
ADMIN_EMAIL=""
DOMAIN_NAME=""

DIR="/home/$PROJECT_NAME"

#----------------------------
# Helper functions:

# updates any linux repo that contains $1 in the .list filename
# param $1 (string) search term to look for repos
# post condition: repos matching $1 will be updated
update_linux_repo() {
  # find repos containing the parameter (string)
    repos=$(grep -rl "$1" /etc/apt/sources.list.d)
  # update each repo
    for repo in $repos;
    do
        sudo apt-get update -o Dir::Etc::sourcelist="$repo" -o Dir::Etc::sourceparts="-"
    done
}

# gets php dependencies that are required for Laravel
function installPHPdependencies(){
  # add repo
    sudo add-apt-repository -y ppa:ondrej/php 
  # update repo
    update_linux_repo php
  # install php packages
    sudo apt-get install -y libapache2-mod-php7.1
    sudo apt-get install -y php7.1-dom
    sudo apt-get install -y php7.1-mbstring
    sudo apt-get install -y php7.1-zip
    sudo apt-get install -y php7.1-mysql 
} 

# sets configs to serve from the appropriate directory
function setApacheConf(){
    newConfName="$PROJECT_NAME.conf"
    apacheSitesDir="/etc/apache2/sites-available"
    conf="$apacheSitesDir/$newConfName"
    
    newRoot="$DIR/public"
    
    echo '<VirtualHost *:80>'                 > $conf
    echo -e "\tServerName $DOMAIN_NAME"       >> $conf
    echo -e "\tServerAdmin $ADMIN_EMAIL"      >> $conf
    echo -e "\tDocumentRoot" $newRoot         >> $conf
    echo -e "\tLogLevel info"                 >> $conf
    echo -e "\tErrorLog ${APACHE_LOG_DIR}/error.log" >> $conf
    echo -e "\tCustomLog ${APACHE_LOG_DIR}/access.log combined" >> $conf
    echo -e "\t" '<Directory' " $newRoot" '>' >> $conf
    echo -e "\t\tOptions Indexes FollowSymLinks" >> $conf
    echo -e "\t\tAllowOverride All\n\t\tRequire all granted" >> $conf
    echo -e "\t" '</Directory>'               >> $conf
    echo -e '</VirtualHost>'                  >> $conf
    
  #enable the site, disable default
    sudo a2dissite 000-default; sudo a2ensite $newConfName
    sudo service apache2 restart
}

#----------------------------
# Start executing 

sudo apt update

# from https://gist.github.com/sheikhwaqas/9088872
# Install MySQL Server in a Non-Interactive mode. Default root password will be $MYSQL_PASS
echo "mysql-server mysql-server/root_password password $MYSQL_PASS" | sudo debconf-set-selections
echo "mysql-server mysql-server/root_password_again password $MYSQL_PASS" | sudo debconf-set-selections
sudo apt-get -y install mysql-server

mysql --user="root" --password="$MYSQL_PASS" --execute="create database $MYSQL_DATABASE"

apt install apache2

sudo a2enmod rewrite

installPHPdependencies
