rem ######################################################################################################################### #
rem
rem Script para fazer dmp dos bancos de dados do PGSQL Linux
rem
rem autor: welitonjunior@live.com
rem data da criacao: 2015-05-11
rem
rem pre-requisitos de pacotes:
rem pg_dump
rem pscp (https://www.chiark.greenend.org.uk/~sgtatham/putty/latest.html)
rem 
rem Dica:
rem Colocar este script como uma tarefa agendada do windows
rem ver site:
rem https://wiki.mandic.com.br/servidores-cloud/servidor-cloud/cloud-windows/sistema-operacional/criando-um-agendamento-de-tarefas
rem
rem ######################################################################################################################### #

rem Define a variável ano como sendo os dois últimos caracteres da data
set ano=%date:~6,4%
rem Define mes como sendo o oitavo e o nono caracteres da data
set mes=%date:~3,2%
rem Define dia como sendo os dois primeiros caracteres após o nome do dia da semana da data
set dia=%date:~0,2%

rem Define a variável hh como os dois primeiros caracteres da hora (hora)
set hh=%time:~0,2%
rem Define a variável mm como o quarto e quinto caracteres da hora (minuto)
set mm=%time:~3,2%

@echo off

rem seta o nome dos arquivos baseado na data-hora atual
SET banco_bkp=BANCO_BKP_%ano%%mes%%dia%-%hh%%mm%.tar

rem Verifica se a tarefa agendada pelo Windows está sendo executada na hora do backup
IF "%hh%"==" 7" GOTO executar
IF "%hh%"=="13" GOTO executar
IF "%hh%"=="22" GOTO executar
ECHO Nao esta no horario de execucao
GOTO saida
:executar

echo "Aguarde, realizando o backup do Banco de Dados"


rem Setando a pasta
D:
CD D:\PostgreSQL\8.3\bin\

rem Executando o comando para backup do postgre
pg_dump.exe -U postgres -F c -b -v -f "%banco_bkp%" banco_bkp

echo "Backup realizado, copiando para o servidor"

rem Copiando o backup para o servidor linux usando a ferramenta PSCP do PuTTy
pscp -pw SENHA_SERVIDOR_BKP "%banco_bkp%" USUARIO_SERVIDOR_BKP@IP_SERVIDOR_BKP:CAMINHO_SERVIDOR_BKP

echo "Copiado, excluindo arquivo gerado na máquina"

rem deletando o arquivo gerando localmente pelo backup
del "%banco_bkp%"

goto End

:saida
echo saindo!

rem PAUSE
