#!/bin/bash

clear

varrer_rede(){
    local endereco_ip=$(echo $1 | awk -F. '{ print $1"."$2"."$3"." }')
    for ip in $(seq 170 172)
    do 
        host_up=$(ping -c1 $endereco_ip$ip -w1 | grep -i ^64 | awk -F" " '{ print $1 }')
        if [ ! -z $host_up ];
        then
            local ip_completo=$endereco_ip$ip
            scan_portas $ip_completo $2
        fi
    done

}

scan_portas(){
    local ip_ativo=$1
    read -r -a portas <<< "$(echo $2 | awk '{gsub(",", " "); print}')"
    
        for porta in "${portas[@]}"
        do
            local flag_response=$(sudo hping3 -c 1 --syn -p "$porta" $ip_ativo 2>&1 | grep -ie "flags" -ie "icmp")
            if [[ -z $flag_response ]];
            then 
                enderecos_up+=( "$ip_ativo -> Porta $porta/tcp [ Filtrada ]")
                echo "${enderecos_up[-1]}"
            else
                flag=$(echo $flag_response | awk -F" "  '{ print $7 }' | awk -F= '{ print $2}')
                flag="${flag//$'\n'/}"
                if [[ "$flag" == "SA" ]];
                then
                    enderecos_up+=( "$ip_ativo -> Porta $porta/tcp [ Aberta ]")
                    echo "${enderecos_up[-1]}"
                elif [[ "$flag" == "RA" ]]
                then
                    enderecos_up+=( "$ip_ativo -> Porta $porta/tcp [ Fechada ]")
                    echo "${enderecos_up[-1]}"
                else
                    enderecos_up+=( "$ip_ativo -> Porta $porta/tcp [ Inacessivel ]")
                    echo "${enderecos_up[-1]}"
                fi
            fi
        done
}

varrer_rede $1 $2
