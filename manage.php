<?php

$debugCommands=false;
$debugReturns=false;
// $debugStdErr=' 2>&1';

function showServer($id){
    $command = 'vultr server show ' . $id;
    return run($command);
}

function getIP($id){
    $command = 'vultr server show ' . $id . ' | grep ^IP: | awk \'{print $2}\'';
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
    return run($command);
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

putenv('VULTR_API_KEY=');

?>

<html>
    <body>
        <form method="get" name="servers" action="">
            <?php
                $IDs = explode(PHP_EOL, getIDlist());
                $i=0;
                foreach ($IDs as $id) {
                    if (strlen($id)<1) continue;
                    $i++;
                    echo '<button type="submit" name="show" value="'.$id.'">';
                    echo 'Project' . $i . '</button>';
                }
            ?>
            <input type="submit" name="list" value="list">
        </form>
        <form method="get" name="create" action="">
            <input type="submit" name="create" value="create">
            <input type="text" name="name">
        </form>
        <?php
            $showID = $_GET['show'];
            $list = $_GET['list'];
            $create = $_GET['create'];
            $name = $_GET['name'];
            $deleteID = $_GET['delete'];

            
            if(isset($showID)) {
                e2(showServer($showID));
                echo '<form method="get" name="server" action="">';
                echo '<br><br><br><br><br><br><br><br><br><br><br><br><br><br><br>';
                echo '<button type="submit" name="delete" value="' . $showID . '">';
                echo 'delete </button>';
                echo '</form>';
            }
            if(isset($list)) {
                e2(getIDlist());
            }
            if(isset($create)) {
                createServer($name);
                header('Location: index.php');  
            }
            if(isset($deleteID)) {
                deleteServer($deleteID);
                header('Location: index.php');
            }
        ?>
        
    </body>
</html>

