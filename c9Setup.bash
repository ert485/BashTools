#!/bin/bash

# Usage:
    # source c9Setup.bash                       # run setup in default directory
    #!/bin/bash

# Usage:
    # source c9Setup.bash                       # run setup in default directory
    
    # for a new project:
    #   laravel new projectName                   # create new laravel project
    #   cp projectName/* .                      # move regular files
    #   cp projectName/.* .                     # move hidden files
    #   rm projectName                          # remove empty directory

# Usage with parameters:
    # source echo $HOME/dir | c9Setup.bash      # run setup in $HOME/dir directory

defaultDir="$HOME/workspace"

# Sets the directory to host from
# parameters are from stdin, timeout of 1 second each
# param: dir (string) the directory to host from
#       -default is $defaultDir
function setDir(){
    # parameters are from stdin, timeout of 1 second each
    echo "Enter the directory to host from"
    read -t 1 dir
    if [ -z "$dir" ]; then
        echo "timeout, using default"
        dir="$defaultDir"
    fi
    # check for absolute path
    if [[ "$dir" = /* ]]; then
        dir="$dir"
    else
        dir="$PWD/$dir"
    fi
    echo "Using directory: $dir"
}

# logs results to file
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
    echo $dir
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
run-apache2 &>> $serveLogFile &                         # runs in background

echo "<-> Installing Laravel dependencies"
installLaravelDependencies &>> $logFile

# Usage with parameters:
    # source echo $HOME/dir | c9Setup.bash      # run setup in $HOME/dir directory

defaultDir="$HOME/workspace"

# Sets the directory to host from
# parameters are from stdin, timeout of 1 second each
# param: dir (string) the directory to host from
#       -default is $defaultDir
function setDir(){
    # parameters are from stdin, timeout of 1 second each
    echo "Enter the directory to host from"
    read -t 1 dir
    if [ -z "$dir" ]; then
        echo "timeout, using default"
        dir="$defaultDir"
    fi
    # check for absolute path
    if [[ "$dir" = /* ]]; then
        dir="$dir"
    else
        dir="$PWD/$dir"
    fi
    echo "Using directory: $dir"
}

# logs results to file
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
    echo $dir
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
run-apache2 &>> $serveLogFile &                         # runs in background

echo "<-> Installing Laravel dependencies"
installLaravelDependencies &>> $logFile

