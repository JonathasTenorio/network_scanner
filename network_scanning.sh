#!/bin/bash

endereco_ip=$(echo $1 | awk -F. '{ print $1"."$2"."$3"." }')

for ip in $(seq 1 35)
do 
    resposta=$(ping -c1 $endereco_ip$ip -w1 | grep -i ^64 | awk -F" " '{ print $1 }')
    if [ ! -z $resposta ]
    then
        echo $endereco_ip$ip" is up"
    fi

done
