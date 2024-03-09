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
            scan_portas $ip_completo $2 $3
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
            verifica_status_porta $porta $ip_ativo $3
        done
    else
        for porta in "${portas[@]}"
        do
            verifica_status_porta $porta $ip_ativo $3
        done
    fi
}

verifica_status_porta(){
    local porta=$1
    local ip_ativo=$2
    local verboso=$3
    resposta_hping3=$(sudo hping3 -c 1 --syn -8 "$porta" $ip_ativo -V 2>&1 | grep "\.\.\." )
    servico=$(echo "$resposta_hping3" | awk '{gsub(/\./, ":"); gsub(/[0-9]/, ":"); gsub(":", ""); gsub("RA", ""); gsub("SA", ""); gsub(" ", ""); print }')
    if [[ -z "$servico" ]];
    then
        servico=$(echo "?")
    fi
    pega_flag_resposta=$(echo "$resposta_hping3" | awk -F":" '{gsub(" ", ""); print  $2}' ) 
    if [[ -n "$pega_flag_resposta" ]];
    then
        flag_hping3=$(echo $pega_flag_resposta | awk -F":" '{sub(/[0-9]/, ":"); print $1}' )
        if [[ -n "$3" ]]
        then
        flag_hping3="${flag_hping3//$'\n'/}"
            if [[ "$flag_hping3" =~ ".R.A..." ]];
            then
                enderecos_up+=( "$ip_ativo -> Porta $porta/tcp ($servico)  [   Fechada   ]")
                echo "${enderecos_up[-1]}"
            else
                enderecos_up+=( "$ip_ativo -> Porta $porta/tcp ($servico)  [   Aberta   ]")
                echo "${enderecos_up[-1]}"
            fi 
        else
            if [[ "$flag_hping3" =~ ".S..A..." ]];
            then
                enderecos_up+=( "$ip_ativo -> Porta $porta/tcp ($servico) [   Aberta   ]")
                echo "${enderecos_up[-1]}"
            fi
        fi       
    else 
        enderecos_up+=( "$ip_ativo -> Porta $porta/tcp ($servico) [   Filtrada  ]")
        echo "${enderecos_up[-1]}"
    fi
}

if [[ $3 == -v ]];
then
    argumento_v=$3
else
    argumento_v=""
fi

if [[ -n $2 ]];
then
    porta_alvo=$2
else
    porta_alvo=1-100
fi

endereco="\b([0-9]{1,3}\.){3}[0-9]{1,3}\b"

if [[ $1 =~ $endereco ]];
then
    varrer_rede $1 $porta_alvo $argumento_v
else  
    echo "Insira um formato de ip válido"
fi
