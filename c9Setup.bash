#!/bin/bash


# Usage:
# source c9Setup.bash          # run setup in default directory
# source c9Setup.bash dirName  # run setup in dirName directory

defaultDir="$HOME/workspace"

function setDir(){
    # check if there is a first parameter
    if [ "$#" -gt 0 ]; then
        # check for absolute path
        if [[ "$1" = /* ]]; then
            dir="$1"
        else
            dir="$PWD/$1"
        fi
    else
        # no parameter, use default
        dir="$defaultDir"
    fi
}

# logs results to file
function initLogs(){
    mkdir -p "$dir/logs"
    logFile="$dir/logs/c9Setup.log.txt"
    serveLogFile="$dir/logs/serve.log.txt"
    
    # add timestamp to logs
    timestamp() {
      date +"%Y-%m-%d %H:%M:%S"
    }
    echo "<-> Running c9Setup.bash in $dir: $(timestamp)" >> $logFile >> $serveLogFile
    echo "<-> Running c9Setup.bash in $dir: $(timestamp)" >> $logFile >> $logFile
}

# updates any linux repo that contains $1 in the .list filename
# param $1 (string) search term to look for repos
# post condition: repos matching $1 will be updated
update_linux_repo() {
    # find repos containing the parameter (string)
    repos=$(grep -rl "$1" /etc/apt/sources.list.d)
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
    
    # switch apache to using php7.1 instead of php5
    sudo a2dismod php5
    sudo a2enmod php7.1
} 

# sets configs to serve from the appropriate directory
function setSiteConf(){
    newConfName="002-laravel.conf"
    copyFromConf="001-cloud9.conf"
    apacheSitesDir="/etc/apache2/sites-available"
    oldHost="/home/ubuntu/workspace"
    newHost="$dir/public"
    #copy site .conf file
    sudo cp "$apacheSitesDir/$copyFromConf" "$apacheSitesDir/$newConfName"
    #change the site to be hosted from the "public" folder
    sudo sed -i "s|$oldHost|$newHost|g" "$apacheSitesDir/$newConfName"
    #set the correct site to enabled, disable others
    p=$PWD
    cd /etc/apache2/sites-enabled
    sudo a2dissite -q *; sudo a2ensite -q $newConfName
    cd $p
}

# gets laravel installer
function installLaravelDependencies(){
    composer global require "laravel/installer"  
    PATH=~/.composer/vendor/bin:$PATH
    export PATH
}

# Start calling functions

setDir
initLogs

echo "<-> Installing php dependencies"
installPHPdependencies &>> $logFile

echo "<-> Configuring Site"
setSiteConf &>> $logFile 

echo "<-> Serve at https://$C9_PROJECT-$C9_USER.c9users.io"
run-apache2 &>> $serveLogFile &

echo "<-> Installing Laravel dependencies"
installLaravelDependencies &>> $logFile

