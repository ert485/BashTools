#!/bin/bash

# Preps a laravel project on a blank cloud 9 workspace
# Installs dependencies for laravel 5.5

# Usage:
    # -run "source c9Setup.bash" in terminal
    # -follow prompts
    
# Gets input from user (info about the laravel project)
function getInput(){
    echo "In which directory should the laravel project live?"
    read dir
    echo "Are you starting from a git repo or new project? (enter 'git' or 'new')"
    read gitOrNew
    if [ "$gitOrNew" = "new" ]; then
        echo "What is the project name?"
        read $projectName
        echo "Do you want to generate user login? (enter 'yes' or 'no')"
        read auth
    else
        echo "Enter the git url (https://github.com/ will be prepended if no 'http' is included)"
        read gitURL
    fi
}

# Modifies script input
function processInput(){
  # store path
    wasIn=$PWD
  # get absolute path (makes temp file to parse the input properly)
    echo "mkdir -p $dir" > tmp
    echo "cd $dir" >> tmp
    . tmp
    rm -f tmp
    dir=$PWD
    cd $wasIn
    echo "Using directory: $dir"
  # check git url for http
    if [ ! "$gitURL" = http* ]; then
        gitURL="https://github.com/$gitURL"
    fi
}

# starts results log file
function initLogs(){
    mkdir -p "$dir/logs"
    logFile="$dir/logs/c9Setup.log.txt"
    serveLogFile="$dir/logs/serve.log.txt"
  # get year-month-day Hour:Minute:Second timestamp
    timestamp() {
      date +"%Y-%m-%d %H:%M:%S"
    }
  # add timestamp to each log
    echo "<-> Running c9Setup.bash in $dir: $(timestamp)" >> $logFile >> $serveLogFile
    echo "<-> Running c9Setup.bash in $dir: $(timestamp)" >> $logFile >> $logFile
}

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

# fix database bug (default string length)
function defaultStringLengthMod(){
    sed -i "N;N;/boot()\\n    {/a\\\t\\tSchema::defaultStringLength(191);" $dir/app/Providers/AppServiceProvider.php  
    sed -i "/use Illuminate\\\Support\\\ServiceProvider;/ause Illuminate\\\Support\\\Facades\\\Schema;" $dir/app/Providers/AppServiceProvider.php
}

# edit database config
function databaseConfig(){
    sed -i "/DB_DATABASE=/c\DB_DATABASE=c9" $dir/.env
    sed -i "/DB_USERNAME=/c\DB_USERNAME=$C9_USER" $dir/.env
    sed -i "/DB_PASSWORD=/c\DB_PASSWORD=" $dir/.env
}

function newLaravel(){
    cd $dir
    laravel new $projectName
    mv $projectName/* .
    mv $projectName/.* .
    rm -rf $projectName
}

function serveLaravel(){
    run-apache2 &>> $serveLogFile &                         # runs in background
  # make executable that says where the site is hosted
    echo "echo hosting at http://\$C9_PROJECT-\$C9_USER.c9users.io" > site
    chmod +x site
  # Display site location
    ./site
}

function gitClone(){
    cd $dir
    git clone $gitURL tempLaravelSetup
    mv tempLaravelSetup/* .
    mv tempLaravelSetup/.* .
    rm -rf tempLaravelSetup
}

# Start calling functions

getInput

processInput

initLogs

echo "<-> Installing php dependencies" | tee -a $LogFile
installPHPdependencies &>> $logFile

echo "<-> Configuring Site" | tee -a $LogFile
setSiteConf &>> $logFile 

echo "<-> Installing Laravel dependencies" | tee -a $LogFile
installLaravelDependencies &>> $logFile

if [ "$gitOrNew" = "new" ]; then
    
    echo "<-> Making new Laravel project" | tee -a $LogFile
    newLaravel &>> $logFile
    
    echo "<-> Configuring database" | tee -a $LogFile
    databaseConfig &>> $logFile
    
    echo "<-> Default string length bug fix" | tee -a $LogFile
    defaultStringLengthMod &>> $logFile
    
    if [ "$auth" = "yes" ]; then
        echo "<-> Making Auth" | tee -a $LogFile
        php artisan make:auth &>> $logFile
        php artisan migrate &>> $logFile
    fi
    
else 

    echo "<-> Cloning git repo" | tee -a $logFile
    gitClone &>> $logFile
    
    echo "<-> Configuring database" | tee -a $logFile
    databaseConfig &>> $logFile
    
    php artisan migrate:refresh --seed
    
fi

echo "<-> Serve the site" | tee -a $logFile
serveLaravel
