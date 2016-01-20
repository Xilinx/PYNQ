#!/bin/bash

if ! [ $(id -u) = 0 ]; then
   echo "to be run with sudo"
   exit 1
fi

declare -A arr
arr+=(["http_proxy"]='"http://172.20.201.1:8080/"')
arr+=(["https_proxy"]='"https://172.20.201.1:8080/"')

# change or append
for key in ${!arr[@]};do
    if grep -qF $key /etc/environment; then
        sed -i "/${key}/d" /etc/environment
        echo "${key} variable deleted"
    else
        echo "${key}=${arr[${key}]}" >> /etc/environment
        echo "${key} variable added"
    fi
done