#!/bin/bash

# project name cannot contain spaces
PROJECT_NAME="test"
MYSQL_DATABASE="laravel"
MYSQL_PASS="secret58bh"
ADMIN_EMAIL=""
DOMAIN_NAME=""

DIRBASE="/home/"
DIR="$DIRBASE$PROJECT_NAME"

#----------------------------
# Helper functions:

# updates any linux repo that contains $1 in the .list filename
# param $1 (string) search term to look for repos
# post condition: repos matching $1 will be updated
# (much faster than a full "apt-get update")
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

# sets apache configs to serve from the appropriate directory
function setApacheConf(){
    newConfName="$PROJECT_NAME.conf"
    apacheSitesDir="/etc/apache2/sites-available"
    conf="$apacheSitesDir/$newConfName"
    newRoot="$DIR/public"
    
    apt install -y apache2
    
    echo '<VirtualHost *:80>'                 > $conf
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
    
    sudo a2enmod rewrite
    
    sudo service apache2 restart
}

# gets laravel installer
function laravelInstaller(){
    composer global require "laravel/installer"  
    PATH=~/.composer/vendor/bin:$PATH
    export PATH
}

# fix database bug (default string length)
# needs laravel 5.5 project present
function defaultStringLengthMod(){
    sed -i "N;N;/boot()\\n    {/a\\\t\\tSchema::defaultStringLength(191);" $DIR/app/Providers/AppServiceProvider.php  
    sed -i "/use Illuminate\\\Support\\\ServiceProvider;/ause Illuminate\\\Support\\\Facades\\\Schema;" $DIR/app/Providers/AppServiceProvider.php
}

# edit environment config
# needs .env present in $DIR
function envConfig(){
    sed -i "/DB_DATABASE=/c\DB_DATABASE=$MYSQL_DATABASE" $DIR/.env
    sed -i "/DB_USERNAME=/c\DB_USERNAME=root" $DIR/.env
    sed -i "/DB_PASSWORD=/c\DB_PASSWORD=$MYSQL_PASS" $DIR/.env
    sed -i "/APP_NAME=/c\APP_NAME=$PROJECT_NAME" $DIR/.env
    sed -i "/APP_URL=/c\APP_URL=http://$DOMAIN_NAME" $DIR/.env
}

function newLaravel(){
    mkdir -p $DIRBASE
    cd $DIRBASE
    laravel new $PROJECT_NAME
}

function installMysql(){
    # from https://gist.github.com/sheikhwaqas/9088872
    # Install MySQL Server in a Non-Interactive mode. Default root password will be $MYSQL_PASS
    echo "mysql-server mysql-server/root_password password $MYSQL_PASS" | sudo debconf-set-selections
    echo "mysql-server mysql-server/root_password_again password $MYSQL_PASS" | sudo debconf-set-selections
        
    sudo apt-get -y install mysql-server
    
    mysql --user="root" --password="$MYSQL_PASS" --execute="create database $MYSQL_DATABASE"
}

function getComposer(){
    curl -sS https://getcomposer.org/installer | sudo php -- --install-dir=/usr/local/bin --filename=composer
}

function addAuth(){
  cd $DIR
  
  php artisan make:auth

  php artisan migrate:refresh --seed
}

#----------------------------
# Start executing 

sudo apt-get update

installMysql

service mysql stop # reduce memory consumption

setApacheConf

installPHPdependencies

getComposer

laravelInstaller

service mysql start # restart after done laravelInstaller

newLaravel

# Give apache2 permission to storage directory
chown -R www-data $DIR/storage

envConfig

defaultStringLengthMod

addAuth

