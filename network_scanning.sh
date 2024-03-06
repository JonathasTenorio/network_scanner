#!/bin/bash

endereco_ip=$(echo $1 | awk -F. '{ print $1"."$2"."$3"." }')

for ip in $(seq 100 103)
do 
    resposta=$(ping -c1 $endereco_ip$ip -w1 | grep -i ^64 | awk -F" " '{ print $1 }')
    if [ ! -z $resposta ]
    then
        ip_up=($endereco_ip$ip)
        portas=(22 23 80 443)
        for porta in "${portas[@]}"
        do
            flag=$(sudo hping3 -c 1 --syn -p "$porta" $ip_up 2>&1 | awk -F" "  '{ print $7 }' | awk -F= '{ print $2}')
            if [[ $flag -eq "RA" ]]
            then
                enderecos_up+=( "$ip_up -> Porta $porta")
            fi
        done
    fi

done

#echo "${enderecos_up[@]}"
for up in "${enderecos_up[@]}"
do
    echo "$up"
done
