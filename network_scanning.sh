#!/bin/bash

endereco_ip=$(echo $1 | awk -F. '{ print $1"."$2"."$3"." }')

for ip in $(seq 170 172)
do 
    host_up=$(ping -c1 $endereco_ip$ip -w1 | grep -i ^64 | awk -F" " '{ print $1 }')
    if [ ! -z $host_up ];
    then
        ip_up=($endereco_ip$ip)
        portas=(1 22 23 80 443)
        for porta in "${portas[@]}"
        do
            flag_response=$(sudo hping3 -c 1 --syn -p "$porta" $ip_up 2>&1 | grep -i flags)
            if [[ -z $flag_response ]];
            then 
                enderecos_up+=( "$ip_up -> Porta $porta/tcp [ Filtrada ]")
            else
                flag=$(echo $flag_response | awk -F" "  '{ print $7 }' | awk -F= '{ print $2}')
                flag="${flag//$'\n'/}"
                if [[ "$flag" == "SA" ]];
                then
                    enderecos_up+=( "$ip_up -> Porta $porta/tcp [ Aberta ]")
                elif [[ "$flag" == "RA" ]]
                then
                enderecos_up+=( "$ip_up -> Porta $porta/tcp [ Fechada ]")
                else
                    enderecos_up+=( "$ip_up -> Porta $porta [ Inacessivel ]")
                fi
            fi
        done
    fi

done




for up in "${enderecos_up[@]}"
do
    echo "$up"
done
