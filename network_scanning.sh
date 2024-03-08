#!/bin/bash

#clear

varrer_rede(){
    local endereco_ip=$(echo $1 | awk -F. '{ print $1"."$2"."$3"." }')
    for ip in $(seq 171 171)
    do 
        host_up=$(ping -c1 $endereco_ip$ip -w1 | grep -i ^64 | awk -F" " '{ print $1 }')
        if [ -n $host_up ];
        then
            local ip_completo=$endereco_ip$ip
            scan_portas $ip_completo $2
        fi
    done
}

scan_portas(){
    local ip_ativo=$1
    read -r -a portas <<< "$(echo $2 | awk '{gsub(",", " "); print}')"
    if [ "$(echo "${portas[@]}" | grep '-')" ];
    then
        local inicio=$(echo "${portas[@]}" | awk -F- '{ print $1 }')
        local fim=$(echo "${portas[@]}" | awk -F- '{ print $2 }')
        for porta in $(seq $inicio $fim)
        do
            verifica_status_porta $porta $ip_ativo
        done
    else
        for porta in "${portas[@]}"
        do
            verifica_status_porta $porta $ip_ativo
        done
    fi
}

verifica_status_porta(){
    local porta=$1
    local ip_ativo=$2
    local flag_response=$(sudo hping3 -c 1 --syn -p "$porta" $ip_ativo 2>&1 | grep -ie "flags" -ie "icmp")
            if [[ -z $flag_response ]];
            then 
                enderecos_up+=( "$ip_ativo -> Porta $porta/tcp [   Filtrada  ]")
                echo "${enderecos_up[-1]}"
            else
                flag=$(echo $flag_response | awk -F" "  '{ print $7 }' | awk -F= '{ print $2}')
                flag="${flag//$'\n'/}"
                if [[ "$flag" == "SA" ]];
                then
                    enderecos_up+=( "$ip_ativo -> Porta $porta/tcp [   Aberta   ]")
                    echo "${enderecos_up[-1]}"
                elif [[ "$flag" == "RA" ]]
                then
                    enderecos_up+=( "$ip_ativo -> Porta $porta/tcp [   Fechada   ]")
                    echo "${enderecos_up[-1]}"
                else
                    enderecos_up+=( "$ip_ativo -> Porta $porta/tcp [ Inacessivel ]")
                    echo "${enderecos_up[-1]}"
                fi
            fi
}


# sudo hping3 -c 1 --syn -8 "$2" "$1" -V | grep -i .s..a 
varrer_rede $1 $2

 #nc -v 192.168.15.171 80
 
 # sudo hping3 -c 1 --syn -8 22-100 192.168.15.171 -V || sudo hping3 -c 1 --syn -8 22-100 192.168.15.171 -V | grep -i .s..a | awk '{ print $2 }'

