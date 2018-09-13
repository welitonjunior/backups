#!/bin/bash

# ######################################################################################################################### #
#
# Script para fazer dmp dos bancos de dados do PGSQL
#
# autor: welitonjunior@live.com
# data da criacao: 2015-09-17
# (Script alterado do guto@gutocarvalho.net)
#
# pre-requisitos de pacotes:
# mysql
# mysqldump
# bzip2
# scp
#
# Importante:
# Caso deseje enviar os dmps criados para um servidor de backup, siga os passos:
# 1 - Gerar uma chave pública RSA, para isso, execute o comando: ssh-keygen -t rsa
# 2 - Copiar a chave criada através do comando: cat ~/.ssh/id_rsa.pub
# 3 - Colar para o arquivo de chaves autorizadas do servidor de backup que fica em: /home/USER/.ssh/authorized_keys
# Se não for criado a chave pública, será necessário informar a senha para cada envio de arquivo
#
# Caso não deseje enviar os dmps, comentar as linhas 71 e 72
# 
# Dica:
# Colocar este script como uma tarefa agendada do crontab, para isso:
# 1 - Editar o crontab: crontab -e
# 2 - Adicionar a linha: 0 21 * * * /LOCAL_DO_SCRIPT/bkp_mysql_ubuntu.sh
# Caso tenha dúvidas em como configurar o crontab, https://pt.wikipedia.org/wiki/Crontab
#
# ######################################################################################################################### #

server=$(uname -a|awk '{ print $2 }')                             # nome do servidor
host="IP_DO_SERVIDOR"                                             # host DB
user="USUARIO_DB"                                                 # username DB
pass="SENHA_DB"                                                   # password DB
localBKP="CAMINHO_PARA_ARMAZENAR_BKP"                             # diretório onde ficará o BKP
bsb="mysql|information_schema|performance_schema"                 # bancos sem bkp
dt="$(date +%Y%m%d.%H)h"                                          # data e hora para serem adicionandos no nome do arquivo
nb="10"                                                           # numero maximo de arquivos de backup a serem mantidos
sftpBKP="USUARIO_BKP@IP_BKP:CAMINHO_BKP"                          # acesso ao servidor de bkp

echo "\nIniciando backup de bancos mysql... $(date +%H:%M:%S" - "%d/%m/%Y)"
echo "Nome do servidor: $server"
echo "O script esta configurado para armazenar os ultimos $nb dmps..."
echo "O script esta ignorando os seguintes bancos: [ $bsb ]"
echo "Os bancos serão salvos em: [ $localBKP ]"

echo "Buscando informacoes no mysql server..."

export MYSQLPASSWORD=$pass
#for db in $(mysql -h $host -u $user -p $pass -B -s -e 'show databases;'| egrep -v $bsb); do
for db in $(mysql -h $host --user=$user --password=$pass -B -s -e 'show databases;'| egrep -v $bsb); do
  #nomeM=`echo $db | tr [a-z] [A-Z]`
  nomeM=$db

  echo -e "\nEfetuando backup do banco: [ $db ]"

  # fazendo o backup dos bancos encontrados
  #mysqldump --all --quick --user=$user --password=$pass $db | bzip2 -c > $localBKP/$nomeM.$dt.dmp.bz2 # Com compactação
  #mysqldump --all --quick -h $host --user=$user --password=$pass $db  > $localBKP/$nomeM.$dt.sql # Sem compactação
  mysqldump -h $host --user=$user --password=$pass $db > $localBKP/$nomeM.$dt.sql
  echo "Arquivo com dmp do banco [ $db ] gerado! [ $(date +%H:%M:%S" - "%d/%m/%Y) ]"
  
  # Enviando arquivo para o servidor de Backup
  #echo "Enviando o arquivo para o servidor de backup..."
  #scp $localBKP/$nomeM.$dt.sql $sftpBKP      # Sem compactação
  #scp $localBKP/$nomeM.$dt.dmp.bz2 $sftpBKP  # Com compactação

  # Excluindo arquivos antigos
  if [ $(ls -1 $localBKP/$nomeM.*|wc -l) -gt $nb ];then
    oldfile=$(ls -1 $localBKP/$nomeM.* -r --sort=time|head -1)
    echo "o arquivo antigo [ $oldfile ] esta sendo apagado..."
    rm $oldfile
  fi

done
