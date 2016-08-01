#!/bin/bash

target=~/.jupyter/jupyter_notebook_config.py

# get current ip address - we assume it is static
ip=$(echo $(hostname -I))

# set up dictionary of changes for jupyter_config.py
declare -A arr
app='c.NotebookApp' 
arr+=(["$app.open_browser"]="$app.open_browser = False")
arr+=(["$app.ip"]="$app.ip ='$ip'")
arr+=(["$app.port"]="$app.port = 9090")
arr+=(["$app.enable_mathjax"]="$app.enable_mathjax = True")
arr+=(["$app.notebook_dir"]="$app.notebook_dir = '/home/xilinx/jupyter_notebooks'")
arr+=(["$app.password"]="$app.password='sha1:5f92e9750a36:e012b5438b703f13b73cccdbc82d151b1013668a'")
arr+=(["$app.server_extensions.append"]="$app.server_extensions.append('ipyparallel.nbextension')")

# apply changes to jupyter_notebook_config.py

# change or append
for key in ${!arr[@]};do
    if grep -qF $key ${target}; then
        # key found -> replace line
        sed -i "/${key}/c ${arr[${key}]}" $target
    else
        # key not found -> append line
        echo "${arr[${key}]}" >> $target
    fi
done 

#echo 'To connect to Jupyter, launch it first by typing "sudo jupyter notebook"'
#echo 'in this terminal, and then go to "'$ip':9090" on your browser.'
#echo 'The password to access is "xpp".'
#echo 'Notebooks will be saved in the folder "/home/xpp/jupyter_notebooks".'

script_name=`readlink -f "$0"`

echo "${script_name}: Jupyter configuration complete"
