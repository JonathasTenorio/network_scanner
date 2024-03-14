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


O Netscan (network_scanning) é uma ferramenta de código aberto para exploração de rede. Esta ferramenta foi desenvolvida para escanear redes internas em busca de hosts ativos e os serviços que estão ativos.

---
### Modo de uso:

1) Passando ip como argumento:

   * `netscan 10.0.0.100`

(print de exemplo)

---

2) Passando sequência ip's como argumento:

   * `netscan 10.0.0.100`

(print de exemplo)

---

3) Passando portas como argumento:

   * `netscan 10.0.0.100 22,23,24,25,26`

(print de exemplo)

---
4) Passando sequência de portas como argumento:

    * `netscan 10.0.0.100 22-26`

(print de exemplo)

---
5) Opção detalhada:

    * `netscan 10.0.0.100 22 -v`

(print de exemplo)

---
6) Sem argumentos:

    * `netscan`
###### O script irá buscar o ip da máquina atual e realizara a varredura a da rede em que o host esta inserido.
---