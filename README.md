# Netscan

### O script recebe como argumento o ip da rede alvo e as portas de serviço que serão verificadas. 
script desenvolvido para fins didáticos. 

---

Requisitos:

 * gawk 
 * grep
 * hping3
---
### Sinopse


O Netscan (network_scanning) é uma ferramenta de código aberto para varredura de redes internas. Esta ferramenta foi desenvolvida para escanear redes internas em busca de hosts e serviços ativos, utilizando o protocolo tcp para detectar as portas e serviços.

---
### Modo de uso:

#### Primeiro uso:

Ao utilizar o netscan pela primeira vez, é necessário passar os argumentos quedeseja como ip(s) e porta(s) de destino pois na primeira utilização ele iratentar baixar as dependências para ser executado e se configurar na pasta `usr/share/netscan`
    
Após o primeiro uso ele pode ser invocado através do comando `netscan`
Caso apresente erros ao utilizar, verifique se as ferramentas grep, hping3 e gawk
estão devidamente instaladas no OS, para um bom funcionamento do script é   necessário ser utilizado com permissão de super usuário (sudo).


1) Passando ip como argumento:

   * `netscan 10.0.0.100`

    Realiza a varredura  do host atual e das portas 1 até 100 por padrão.

---

2) Passando sequência ip's como argumento:

   * `netscan 10.0.0.100,102,115,200`

    Realiza a varredura  dos hosts na ordem indicada e para cada host, a varredura  das 100 primeiras portas por padrão.

---

3) Passando intervalo ip's como argumento:

   * `netscan 10.0.0.100-200`

   Realiza a varredura  no intervalo do último octeto até o indicado, apenas intervalo de ordem crescente não resultará em erro.

---

4) Passando portas como argumento:

   * `netscan 10.0.0.100 22,23,24,25,26`

    Realiza a varredura  da sequência de portas.

---
5) Passando intervalo de portas como argumento:

    * `netscan 10.0.0.100 22-26`

        Realiza a varredura  do intervalo das portas.

---
6) Opção detalhada:

    * `netscan 10.0.0.100 22 -v`

        Durante a varredura das portas exibe também as portas fechadas.

---
6) Sem argumentos:

    * `netscan`

        Por padrão o script ira utilizar o ip atual do host para varrer a rede no intervalo de 1 até 255 e para cada host marcado como ativo, realizara varredura das 100 primeiras portas.
---

### Remoção do Netscan

Para remover o netscan basta executar o comando `sudo rm -rf /usr/sharenetscan`, que é o local onde o script se configura.

Para remoção do comando netscan, edite o arquivo `~/.bash_aliases` e remova alinha na qual consta o netscan.

---