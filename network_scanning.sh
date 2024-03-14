#!/bin/bash

#clear

varrer_rede(){
    local is_range=$(echo "$1" | awk -F- '{ print $2 }')
    is_range=$(echo "$is_range" | awk '{gsub(" ",""); print }')
    if [[ -z $is_range ]];
    then
        host_discover "$1" "$2" "$3"
    else
        local inicio=$(echo "$1" | awk -F. '{ gsub("-","."); print $4 }' )
        local fim=$(echo "$1" | awk -F. '{ gsub("-","."); print $5 }' ) #awk -F- '{ print $2 }'
        for ip in $(seq $inicio $fim) 
        do 
            local endereco_ip=$(echo $1 | awk -F. '{ print $1"."$2"."$3"." }')
            host_discover "$endereco_ip$ip" "$2" "$3"
        done
    fi
}

host_discover(){
    host_up=$(ping -c1 $1 -w1 | grep -i ^64 | awk -F" " '{ print $1 }')
    if [[ $host_up == "64" ]];
        then
        host_up=" "
        echo "O endereço $1 está ativo."
        echo "Iniciando a varredura de portas . . . . ." 
        scan_portas "$1" "$2" "$3"
    fi
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
            verifica_status_porta "$porta" "$ip_ativo" "$3"
        done
    else
        for porta in "${portas[@]}"
        do
            verifica_status_porta "$porta" "$ip_ativo" "$3"
        done
    fi
}

verifica_status_porta(){
    local porta=$1
    local ip_ativo=$2
    if [[ ! -z $3 ]];
    then 
        verboso=$(echo "-v")
    fi
    resposta_hping3=$(sudo hping3 -c 1 --syn -8 $porta $ip_ativo -V 2>&1 | grep "\.\.\." )
    servico=$(echo "$resposta_hping3" | awk '{gsub(/\./, ":"); gsub(/[0-9]/, ":"); gsub(":", ""); gsub("RA", ""); gsub("SA", ""); gsub(" ", ""); print }')
    if [[ -z $servico ]];
    then
        servico="?" 
    fi

    verifica_flag  "$porta" "$ip_ativo" "$verboso" "$resposta_hping3" "$servico"
}

verifica_flag(){
    local porta=$1
    local ip_ativo=$2
    local verboso=$3
    local resposta_hping3=$4
    local servico=$5
    pega_flag_resposta=$(echo "$resposta_hping3" | awk -F":" '{gsub(" ", ""); print  $2}' ) 
    if [[ -n "$pega_flag_resposta" ]];
    then
        flag_hping3=$(echo $pega_flag_resposta | awk -F":" '{sub(/[0-9]/, ":"); print $1}' )
        if [[ -n $verboso ]]
        then
        flag_hping3="${flag_hping3//$'\n'/}"
            if [[ "$flag_hping3" =~ ".R.A..." ]];
            then
                echo "$ip_ativo -> Porta $porta/tcp ($servico)  [   Fechada   ]"
            else
                echo "$ip_ativo -> Porta $porta/tcp ($servico)  [   Aberta   ]"
            fi 
        else
            if [[ "$flag_hping3" =~ ".S..A..." ]];
            then
                echo "$ip_ativo -> Porta $porta/tcp ($servico) [   Aberta   ]"
            fi
        fi       
    else 
        echo "$ip_ativo -> Porta $porta/tcp ($servico) [   Filtrada  ]"
    fi
}

netscan_install(){
    local existe_dir=$1
    if [[ ! -d $existe_dir ]];
    then
        sudo mkdir $existe_dir    
    fi
    sudo cp network_scanning.sh $existe_dir/network_scanning.sh
    sudo echo "alias netscan='bash /usr/share/netscan/network_scanning.sh'" >> ~/.bashrc 
    echo "Ao final utilize o comando source ~/.bashrc ou abra uma nova aba do terminal"
}

netscan_install_dependencias(){
    local release='/etc/os-release'
    if [[ -f $release ]];
    then
        local id=$(cat $release | grep -ie "id=" )
        case $id in
        "ubuntu")
            apt-get install gawk hping3
            break;;
        "kali")
            apt install gawk hping3
            break;;
        "debian")
            apt-get install gawk hping3
            break;;
        "redhat")
            yum install gawk hping3
            break;;
        "fedora")
            yum install gawk hping3
            break;;
        "centos")
            yum install gawk hping3
            break;;
        "arch")
            pacman -S gawk hping3  
            break;;
        *)
            echo "OS não suportado, instale as pendencias manualmente."
        esac
    fi
}

verifica_install(){
    local existe_dir=$1
    if [[ ! -d $existe_dir ]] || [[ ! -f "$existe_dir/network_scanning.sh" ]];
    then
        netscan_install_dependencias
        netscan_install "$existe_dir"
    fi
}

verifica_args(){
    local s1=$1
    local s2=$2
    local argumento_v=$3

    if [[ -n $s2 ]];
    then
        porta_alvo=$s2
    else
        porta_alvo=1-100
    fi
    
    formato_ip="\b([0-9]{1,3}\.){3}[0-9]{1,3}\b"
    
    if [[ $s1 =~ $formato_ip ]];
    then
        varrer_rede "$s1" "$porta_alvo" "$argumento_v"
    else  
        echo "Formato de ip inválido"
        echo "Requisitando ip do host atual . . . "
        local ip_host_atual=$(ip addr | grep -i "scope global" | awk -F" " '{ gsub("/", " "); print $2 }' )

        if [[ $ip_host_atual =~ $formato_ip ]];
        then
            echo "Requisição concluida com susesso!"
            echo "Iniciando a varredura da rede . . . "
            echo $ip_host_atual $porta_alvo $argumento_v
            varrer_rede "$ip_host_atual" "$porta_alvo $argumento_v"
        else
            echo "Não foi possível concluir a requisição do ip com sucesso."
            echo "Verifique a situação da sua placa de rede . . ." 
        fi
    fi
}

existe_dir='/usr/share/netscan'

verifica_install "$existe_dir"
verifica_args "$1" "$2" "$3"
