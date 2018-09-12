#!/bin/bash

# ######################################################################################################################### #
#
# Script para fazer dmp dos bancos de dados do PGSQL Linux
#
# autor: welitonjunior@live.com
# data da criacao: 2015-05-11
# (Script alterado do guto@gutocarvalho.net)
#
# pre-requisitos de pacotes:
# psql
# vacuumdb
# pg_dump
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
# 2 - Adicionar a linha: 0 21 * * * /LOCAL_DO_SCRIPT/bkp_postgres_ubuntu.sh
# Caso tenha dúvidas em como configurar o crontab, https://pt.wikipedia.org/wiki/Crontab
#
# ######################################################################################################################### #

# 0 21 * * * /home/administrador/psqlbkp32

server=$(uname -a|awk '{ print $2 }')				# nome do servidor
host="IP_DO_SERVIDOR"								# host DB
user="USUARIO_DB"									# username DB
pass="SENHA_DB"										# password DB
porta="PORTA_DB"									# porta DB
localBKP="CAMINHO_PARA_ARMAZENAR_BKP"				# diretório onde ficará o BKP
bsb="template0|template1|postgres|md|:"				# bancos sem bkp
dt="$(date +%Y%m%d.%H)h"							# data e hora para serem adicionandos no nome do arquivo
nb="1"												# numero maximo de arquivos de backup a serem mantidos
sftpBKP="USUARIO_BKP@IP_BKP:CAMINHO_BKP"			# acesso ao servidor de bkp

echo "\nIniciando backup de bancos pgsql... $(date +%H:%M:%S" - "%d/%m/%Y)" | tee -a $ln
echo "Nome do servidor: $server"|tee -a $ln
echo "O script esta configurado para armazenar os ultimos ( $nb ) dmps..."|tee -a $ln
echo "O script esta ignorando os seguintes bancos: [ $bsb ]"|tee -a $ln
echo "Os bancos estao sendo salvos em: [ $localBKP ]"|tee -a $ln

export PGPASSWORD=$pass
for db in $(psql --username=$user -h $host -p $porta -l -t -A | cut -d\| -f1 | egrep -v $bsb); do

	nomeM=$db

	echo "\nEfetuando backup do banco: [ $db ]" | tee -a $ln

	# Fazer o vacuumdb dos bancos
	vacuumdb -z -h $host -p $porta -U $user -d $db

	# fazendo o dump dos bancos encontrados

	pg_dump -i -h $host -p $porta -U $user -d $db | bzip2 -c > $localBKP/$nomeM.$dt.dmp.bz2 	# Com compactação
	#pg_dump -i -h $host -p $porta -U $user -d $db -F c -b -v -f $localBKP/$nomeM.$dt.backup 	#sem compactação
	echo "Arquivo com dmp do banco [ $db ] gerado! [ $(date +%H:%M:%S" - "%d/%m/%Y) ]" | tee -a $ln

	# Enviando arquivo para o servidor de Backup
	echo "Enviando o arquivo para o servidor de backup..." | tee -a $ln
	scp $localBKP/$nomeM.$dt.dmp.bz2 $sftpBKP

	# Excluindo arquivos antigos
	if [ $(ls -1 $localBKP/$nomeM.*|wc -l) -gt $nb ];then
		oldfile=$(ls -1 $localBKP/$nomeM.* -r --sort=time|head -1)
		echo "o arquivo antigo [ $oldfile ] esta sendo apagado..." | tee -a $ln
		rm $oldfile
	fi

done

echo "\nBackup finalizado.. $(date +%H:%M:%S" - "%d/%m/%Y)" | tee -a $ln
