#!/bin/bash

# replaces every line containing $1 with $2 in file $3
function replace1(){
    sed -i "/$1/c$2" $3
}

# appends $2 after every line containing $1 in file $3
function appendAfter1(){
    sed -i "/$1/a$2" $3
}

# appends $3 after every instance of consecutive lines with $1
    # in the first line, $2 in the second line
function twoLineAppendAfter(){
    sed -i "N;/$1\\n$2/a$3" $4
}
    
function test_replace1(){
    cat test
    replace1 '1' 'a\tb' test
    cat test
}

function test_appendAfter1(){
    cat test
    appendAfter1 '1' 'a\tb' test
    cat test
}

function test_twoLineAppendAfter1(){
    cat test
    twoLineAppendAfter '1' '2' 'a\tb' test
    cat test
}
function makeTestFile(){
    echo $'1\n2\n3\n4\nend of test' > test
}

makeTestFile
test_twoLineAppendAfter1
