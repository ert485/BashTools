#!/bin/bash
FILES=./*
for f in $FILES
do
        # (command) return line numbers that have more than 80 characters (needs argument for filename after this) 
        CHECK80="sed -n '/\(.\)\{80\}/{=}'"

        # (command) return lines that have more than 80 characters (needs argument for filename after this) 
        # CHECK80="sed -n '/\(.\)\{80\}/{p}'"

        RESULT=$(eval $CHECK80 $f)
        if [ ${#RESULT} -gt 0 ]; then
                NUMLINES=$(echo "$RESULT" | wc -l)
                echo "$f has $NUMLINES lines with more than 80 characters"
                if [ $NUMLINES -lt 3 ]; then
                        echo -e "\t line numbers:"      
                        echo -e "\t\t${RESULT}"
                fi
        fi
done

#RESULT=sed -n '/\(.\)\{80\}/p' PartB.design.txt

#cat filesToCheck.txt | while read i; do
#       echo "file $i has line greater than 80 characters: " ${sed -n '/\(.\)\{80\}/p' $i}
        # TODO: your "mv" command here.  "$i" will be a line from
        # the text file.
#done
