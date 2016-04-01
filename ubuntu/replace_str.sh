#!/bin/bash

# Changes the old name to the new name in the current directory
echo -n "The directory to search iteratively > "
read directory
echo -n "The old name to be replaced > "
read name1
echo -n "The new name after replacement > "
read name2
echo "Changing $name1 to $name2 ..."

grep -Elr --binary-files=without-match "$name1" "$directory" | xargs sed -i "s/$name1/$name2/g"
echo "Done."