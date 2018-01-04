<?php

function showServer($id){
    $command = 'vultr server show ' . $id;
    return run($command);
}

function getIP($id){
    $command = 'vultr server show ' . $id . ' | grep ^IP: | awk \'{print $2}\'';
    return run($command);
}

function getName($id){
    $command = 'vultr server show ' . $id . ' | grep ^Name: | awk \'{print $2}\'';
    return run($command);
}

//create new server
function createServer($name){
    $settings = '-n '. $name .' -p 201 -r 2 -o 215 --script=238967';
    $command = 'vultr server create ' . $settings;
    return run($command);
}

function deleteServer($id){
    $confirm = 'echo yes | ';
    $command = 'vultr server delete ' . $id;
    return run($confirm . $command);
}

function getIDList(){
    $command = 'vultr servers | awk \'{if (NR!=1) print $1}\'';
    $string = run($command);
    $list = explode(PHP_EOL, $string);
    return $list;
}

function e2($string){
    echo "<pre>". $string."</pre>";
}

function run($command){
    $command = $command . $GLOBALS['debugStdErr'];
    if($GLOBALS['debugCommands']){
        echo 'running: ' . $command . '<br>';
    }
    $result = shell_exec($command);
    if($GLOBALS['debugReturns']){
        echo 'returned: ' . $result . '<br>';
    }
    return $result;
}

function getAndSetDebug(){
    $level = shell_exec('head -1 debug.txt');
    if($level>0) $GLOBALS['debugCommands'] =true;
    else $GLOBALS['debugCommands'] = false;
    if($level>1) $GLOBALS['debugReturns'] =true;
    else $GLOBALS['debugReturns'] = false;
    if($level>2) $GLOBALS['debugStdErr'] =' 2>&1';
    else $GLOBALS['debugStdErr'] = '';
    return $level;
}

putenv('VULTR_API_KEY=');

?>

<html>
    <head>
        <script>
            function clearResults()
            {
                document.getElementById('results').innerHTML = "";
            }
        </script>
    </head>
    <body>
        <form method="get" name="debug" action="">
            <?php
                $debug = getAndSetDebug();
                $next_debug = $debug+1;
                echo '<button type="submit" name="debug" value="' . $next_debug . '">';
                echo 'Debugging level: ' . $debug;
            ?>
            </button>
        </form>
        <form method="get" name="servers" action="">
            <?php
                $IDs = getIDlist();
                $i=0;
                foreach ($IDs as $id) {
                    if (strlen($id)<1) continue;
                    $name = getName($id);
                    if (strlen($name)<2) $name = "No Name";
                    $i++;
                    echo '<button type="submit" name="show" value="'.$id.'" onclick="clearResults()">';
                    echo $name . '</button>';
                }
            ?>
        </form>
        <form method="get" name="create" action="">
            <input type="submit" name="create" value="Create Server">
            <input type="text" name="name">
        </form>
        <?php
            $showID = $_GET['show'];
            $create = $_GET['create'];
            $name = $_GET['name'];
            $deleteID = $_GET['delete'];
            $debug = $_GET['debug'];
            
            if(isset($create)) {
                createServer($name);
                header('Location: manage.php');  
            }
            if(isset($deleteID)) {
                deleteServer($deleteID);
                header('Location: manage.php');
            }
            if(isset($debug)) {
                if ($debug>3) $debug = 0;
                shell_exec("echo $debug > debug.txt");
                header('Location: manage.php');
            }
        ?>
        <div id="results">
            <?php
                if(isset($showID)) {
                    e2(showServer($showID));
                    echo '<form method="get" name="server" action="">';
                    echo '<br><br><br><br><br><br><br><br><br><br><br><br><br><br><br>';
                    echo '<button type="submit" name="delete" value="' . $showID . '">';
                    echo 'Delete Server </button>';
                    echo '</form>';
                }
            ?>
        </div>
    </body>
</html>

