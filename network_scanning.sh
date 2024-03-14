#!/bin/bash


#função destinada a varrer a rede 
varrer_rede(){

    #cria variável para verificar se a varredura é em intervalo ou em hosts específicos 
    local is_range=$(echo "$1" | awk -F- '{gsub(" ",""); print $2 }')

    #verifica se não é em intervalo
    if [[ -z $is_range ]];
    then

        #se não, armazena os valores na matriz hosts
        read -r -a hosts <<< "$(echo "$1" | awk -F. '{gsub(",", " "); print $4 }')"
        
        #percorre a matriz realizando ações para cada valor existente
        for host in "${hosts[@]}"
        do
            #recebe o endereço da rede
            endereco_host=$(echo $1 | awk -F. '{ print $1"."$2"."$3"." }')
            
            #chama função host_discover passando o endereço do host (rede + ultimo octeto)e argumentos que tem de ser carregados através da chamada das funções seguintes ($2=>portas e $3=>"-v")
            host_discover "$endereco_host$host" "$2" "$3"
        done
    else
        
        #se sim, cria as variáveis inicio e fim que armazenam onde começa e onde termina o intervalo
        local inicio=$(echo "$1" | awk -F. '{ gsub("-","."); print $4 }' ) 
        local fim=$(echo "$1" | awk -F. '{ gsub("-","."); print $5 }' ) #awk -F- '{ print $2 }'
        
        #realiza ações para cara host no intervalo
        for ip in $(seq $inicio $fim) 
        do 

            #cria variável que recebe o endereço ip da rede
            local endereco_ip=$(echo $1 | awk -F. '{ print $1"."$2"."$3"." }')

            #chama função host_discover passando o endereço do host (rede + ultimo octeto) e argumentos que tem de ser carregados através da chamada das funções seguintes ($2=>portas e $3=>"-v")
            host_discover "$endereco_ip$ip" "$2" "$3"

        done
    fi
}

#função que verifica se o host está ativo na rede 
host_discover(){

    #envia pacote icmp através do ping para verificar se o host responde
    host_up=$(ping -c1 $1 -w1 | grep -i ^64 | awk -F" " '{ print $1 }')

    #verifica se houve resposta
    if [[ $host_up == "64" ]];
        then
        
        #limpa a variável para evitar que carrege valores indesejados 
        host_up=" "

        #exibe mensagem de aviso para o usuário
        echo "O endereço $1 está ativo."
        echo "Iniciando a varredura de portas . . . . ."

        #chama função scan_portas passando como parâmetros o endereço ip do alvo, as portas de destino e a flag "-v" caso haja 
        scan_portas "$1" "$2" "$3"
    fi
}

#função que faz a varredora das portas
scan_portas(){

    #cria variável local para armazenar o endereço ip
    local ip_ativo=$1

    #cria uma matriz que recebe as portas passadas como argumento
    read -r -a portas <<< "$(echo $2 | awk '{gsub(",", " "); print}')"

    #verifica se é um intervalo de portas
    if [ "$(echo "${portas[@]}" | grep '-')" ];
    then

        #se sim, cria variáveis locais para definir o início e fim do intervalo
        local inicio=$(echo "${portas[@]}" | awk -F- '{ print $1 }')   
        local fim=$(echo "${portas[@]}" | awk -F- '{ print $2 }')
        
        #executa ação para cada porta no intervalo
        for porta in $(seq $inicio $fim)
        do

            #chama função que verifica o estado da porta, passa como parâmetro o endereço da porta, o ip do alvo e o argumento "-v" caso exista
            verifica_status_porta "$porta" "$ip_ativo" "$3"

        done
    else

        #se não, percorre a matriz executando ações para cada elemento
        for porta in "${portas[@]}"
        do

           #chama função que verifica o estado da porta, passa como parâmetro o endereço da porta, o ip do alvo e o argumento "-v" caso exista
            verifica_status_porta "$porta" "$ip_ativo" "$3"
    
        done
    fi
}

#função que verifica o estado das portas e os serviços
verifica_status_porta(){

    #cria variáveis locais de porta e endereço ip
    local porta=$1  
    local ip_ativo=$2
    
    #verifica se o argumento "-v" existe
    if [[ ! -z $3 ]];
    then 
        #se existir, armazena na variável verboso (medida necessária pois a variável estava sofrendo com bug de se tornar vazia após este trecho de código)
        verboso=$(echo "-v")
    fi

    #cria variável que recebe a resposta da porta 
    resposta_hping3=$(sudo hping3 -c 1 --syn -8 $porta $ip_ativo -V 2>&1 | grep "\.\.\." )

    #cria variável que armazena o banner de serviço retornado pela porta
    servico=$(echo "$resposta_hping3" | awk '{gsub(/\./, ":"); gsub(/[0-9]/, ":"); gsub(":", ""); gsub("RA", ""); gsub("SA", ""); gsub(" ", ""); print }')
    
    #verifica se a variável possui banner atribuído
    if [[ -z $servico ]];
    then

        #se não, armazena interrogação na variável de serviço.
        servico="?" 
    fi

    #chama função que verifica a flag que é retornada, passando como argumento a porta, o endereço ip, se é verbosa, a reposta da porta e o serviço identificado
    verifica_flag  "$porta" "$ip_ativo" "$verboso" "$resposta_hping3" "$servico"

}


#função que ira verificar a resposta da porta, o serviço e exibir ao usuário
verifica_flag(){

    #cria as variáveis locais referentes a porta, endereço ip, argumento "-v", resposta da função verifica_status_porta() e o serviço identificado  
    local porta=$1    
    local ip_ativo=$2    
    local verboso=$3    
    local resposta_hping3=$4    
    local servico=$5
    
    #armazena na variável a flag retornada pela porta
    pega_flag_resposta=$(echo "$resposta_hping3" | awk -F":" '{gsub(" ", ""); print  $2}' ) 
    
    #verifica se a variável possui algum valor atribuído
    if [[ -n "$pega_flag_resposta" ]];
    then

        #se sim, utiliza da resposta para identificar o estado da porta
        flag_hping3=$(echo $pega_flag_resposta | awk -F":" '{sub(/[0-9]/, ":"); print $1}' )

        #verifica se o argumento "-v" foi passado
        if [[ -n $verboso ]];
        then

        #se sim, higiêniza a variável de resposta
        flag_hping3="${flag_hping3//$'\n'/}"

        #verifica se a resposta é uma porta fechada
            if [[ "$flag_hping3" =~ ".R.A..." ]];
            then

                #se sim, exibe ao usuário o ip a porta o serviço e o estado (fechada)
                echo "$ip_ativo -> Porta $porta/tcp ($servico)  [   Fechada   ]"
            
            else

                #se sim, exibe ao usuário o ip a porta o serviço e o estado (aberta)
                echo "$ip_ativo -> Porta $porta/tcp ($servico)  [   Aberta   ]"
            fi 
        else

            #se não, verifica se a resposta é uma porta aberta
            if [[ "$flag_hping3" =~ ".S..A..." ]];
            then

                #se sim, exibe ao usuário o ip a porta o serviço e o estado (aberta)
                echo "$ip_ativo -> Porta $porta/tcp ($servico) [   Aberta   ]"
         
            fi
        fi       
    else 

        #se não, exibe ao usuário o ip a porta o serviço e o estado (filtrada)   
        echo "$ip_ativo -> Porta $porta/tcp ($servico) [   Filtrada  ]"

    fi
}

#função que move o script 
netscan_install(){
    
    #recebe a variavel existe_dir como parâmetro
    local existe_dir=$1

    #verifica se o diretório não existe
    if [[ ! -d $existe_dir ]];
    then

        #se não existe, cria o diretório netscan no caminho /usr/share/netscan
        sudo mkdir $existe_dir    

    fi

    #move o script para o diretório que foi criado
    sudo mv network_scanning.sh $existe_dir/network_scanning.sh

    #cria um alias do script no bash_aliases
    sudo echo "alias netscan='bash /usr/share/netscan/network_scanning.sh'" >> ~/.bash_aliases
    
    #recarrega o bash_aliases
    source ~/.bash_aliases

    #solicita para o usuário atualizar o aliases ou abrir nova sessão para que o alias seja efetivamente carregado
    echo "Ao final utilize o comando source ~/.bash_aliases ou abra uma nova aba do terminal"

}

#função responsável por instalar as depêndencias necessárias para que o netscan possa ser utilizado
netscan_install_dependencias(){

    #recebe o caminho do arquivo de release do OS
    local release='/etc/os-release'

    #verifica se realmente existe esse arquivo
    if [[ -f $release ]];
    then

        #se existir, recebe o ID que consta no arquivo 
        local id=$(cat $release | grep -iE "^id=" | awk -F= '{ print $2 }')

        #verifica se o id em minúsculo se encaixa em alguns dos casos abaixo para instalaras dependências
        case "{$id,,}" in
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

            #caso não encontre o padrão, exibe aviso ao usuário
            echo "OS não suportado, verifique se as dependências foram instaladas corretamente"
            echo "ou as instale manualmente."

        esac
    fi
}

#função que verifica se o netscan já foi instalado na máquina 
verifica_install(){

    #Recebe a variável existe_dir
    local existe_dir=$1

    #verifica se não existe o diretório netscan ou se o script não foi movido para lá 
    if [[ ! -d $existe_dir ]] || [[ ! -f "$existe_dir/network_scanning.sh" ]];
    then

        #caso não, instala dependências
        netscan_install_dependencias

        #após tentativa de instalar depedências, invoca a função netscan_install
        netscan_install "$existe_dir"

    fi
}

#função para verificar se os agrumentos passados estão no formato correto.
verifica_args(){

    #cria as variáveis locais s1, s2 e argumento_v que respectivamente recebem o ip, porta e argumento -v
    local ip_recebido=$1  
    local porta_alvo=$2   
    local argumento_v=$3

    #verifica se foi passado argumento de portas
    if [[ -z $porta_alvo ]];
    then
        porta_alvo=1-100
    fi
    
    #cria variável com formato ip em regex
    formato_ip="\b([0-9]{1,3}\.){3}[0-9]{1,3}\b"
    
    #verifica se o ip recebido está dentro do padrão
    if [[ $ip_recebido =~ $formato_ip ]];
    then
        #se sim, chama a função varre_rede passando os parâmetros ip_recebido, porta_alvo e argumento_v
        varrer_rede "$ip_recebido" "$porta_alvo" "$argumento_v"
    else  

        #se não, exibe mensagem de erro ao usuário
        echo "Formato de ip inválido"
        echo "Requisitando ip do host atual . . . "

        #tenta pegar o ip da máquina atual
        local ip_host_atual=$(ip addr | grep -E '\binet\b.*\bscope global\b' | awk -F" " '{ gsub("/", " "); print $2 }' )

        #verifica se o resultado é um ip válido
        if [[ $ip_host_atual =~ $formato_ip ]];
        then

            #se sim, notifica o usuário
            echo "Requisição concluida com susesso!"
            echo "Iniciando a varredura da rede . . . "
            echo "+-----------------------+------------+"
            echo "|  ip host atual        |   porta    |"
            echo "+-----------------------+------------+"
            echo "|      $ip_host_atual     | $porta_alvo      |"
            echo "+-----------------------+------------+"

            #substitui o final do ip pelo intervalo de 1 até 255
            ip_host_atual=$(echo "$ip_host_atual" | awk -F. '{ gsub($4,"1-255"); print }' )
            
            #chama a função varre_rede passando os parâmetros ip_host_atual, porta_alvo e argumento_v
            varrer_rede "$ip_host_atual" "$porta_alvo" "$argumento_v"

        else

            #se não, exibe mensagem de erro ao usuário
            echo "Não foi possível concluir a requisição do ip com sucesso."
            echo "Verifique a situação da sua placa de rede . . ." 

        fi
    fi
}

#cria variável existe_dir e passa o caminho completo do diretório netscan
existe_dir='/usr/share/netscan'

#chama a função que verifica se já houve a instação do netscan, passado o caminho completo
verifica_install "$existe_dir"

#verifica os argumentos passados para o netscan
verifica_args "$1" "$2" "$3"
