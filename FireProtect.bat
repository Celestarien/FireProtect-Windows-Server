REM Nom du Script : FireProtect
REM Date de création : 13/10/2020
REM Dernière modification : 13/10/2020
REM Revision : Aucune
REM Auteur : Julien GIOVANNANGELI, Anthony Bigeau, Alexandre Fraschini

REM Version : Alpha

REM Utilisation : Configuration Firewall

REM Reporting Bug : Unknow



REM Force l'administrateur

:: BatchGotAdmin
:-------------------------------------
REM  --> Regarde si on a les permission Administrateur
    IF "%PROCESSOR_ARCHITECTURE%" EQU "amd64" (
>nul 2>&1 "%SYSTEMROOT%\SysWOW64\cacls.exe" "%SYSTEMROOT%\SysWOW64\config\system"
) ELSE (
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"
)

REM --> Si on n'est pas administrateur
if '%errorlevel%' NEQ '0' (
    echo Requesting administrative privileges...
    goto UACPrompt
) else ( goto gotAdmin )

:UACPrompt
    echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\getadmin.vbs"
    set params= %*
    echo UAC.ShellExecute "cmd.exe", "/c ""%~s0"" %params:"=""%", "", "runas", 1 >> "%temp%\getadmin.vbs"

    "%temp%\getadmin.vbs"
    del "%temp%\getadmin.vbs"
    exit /B

:gotAdmin
    pushd "%CD%"
    CD /D "%~dp0"
:--------------------------------------


echo off
color b
title FireProtect
cls

echo FireProtect loading...

TIMEOUT /T 5
cls

REM Active le firewall
netsh advfirewall set currentprofile state on
REM Créer une backup
netsh advfirewall export "backups\backup" + %date% + ".wfw"
REM Importe une backup
netsh advfirewall import "backups\backup" + %date% + ".wfw"

REM Active les logs pour la profil private en ajoutant des options comme la taille maximal du fichier
netsh advfirewall set Privateprofile logging filename %systemroot%\system32\LogFiles\Firewall\pfirewall.log
netsh advfirewall set Privateprofile logging maxfilesize 4096
netsh advfirewall set Privateprofile logging droppedconnections enable
netsh advfirewall set Privateprofile logging allowedconnections enable

REM Active les logs pour la profil public en ajoutant des options comme la taille maximal du fichier
netsh advfirewall set Publicprofile logging filename %systemroot%\system32\LogFiles\Firewall\pfirewall.log
netsh advfirewall set Publicprofile logging maxfilesize 4096
netsh advfirewall set Publicprofile logging droppedconnections enable
netsh advfirewall set Publicprofile logging allowedconnections enable

REM Active les logs pour la profil domain en ajoutant des options comme la taille maximal du fichier
netsh advfirewall set Domainprofile logging filename %systemroot%\system32\LogFiles\Firewall\pfirewall.log
netsh advfirewall set Domainprofile logging maxfilesize 4096
netsh advfirewall set Domainprofile logging droppedconnections enable
netsh advfirewall set Domainprofile logging allowedconnections enable

REM Applique pour chacun des profils une politique stricte pour les flux entrants et sortants
netsh advfirewall set allprofiles firewallpolicy blockinbound,blockoutbound
REM Supprime toutes les règles existantes avec la commande
netsh advfirewall firewall delete rule all

REM Ajoute des règles
netsh advfirewall firewall add rule name="TCP Port HTTP" dir=out action=allow profile=public,private protocol=TCP localport=80
netsh advfirewall firewall add rule name="TCP Port HTTPs" dir=out action=allow profile=public,private protocol=TCP localport=443
netsh advfirewall firewall add rule name="TCP Port DNS" dir=out action=allow profile=public,private protocol=TCP localport=53

netsh advfirewall firewall add rule name="TCP Port SSH" dir=out action=allow profile=public,private protocol=TCP localport=22
netsh advfirewall firewall add rule name="TCP Port RDP" dir=out action=allow profile=public,private protocol=TCP localport=3389

netsh advfirewall firewall add rule name="TCP Port IMAP" dir=out action=allow profile=public,private,domain protocol=TCP localport=993
netsh advfirewall firewall add rule name="TCP Port SMTP" dir=out action=allow profile=public,private,domain protocol=TCP localport=465

netsh advfirewall firewall add rule name="Printer" dir=out action=allow profile=private protocol=TCP localport=515 localip=192.168.1.60

netsh advfirewall firewall add rule name="NAS (Web and SFTP Server)" dir=out action=allow profile=private protocol=TCP localport=443,22 localip=192.168.1.60

netsh advfirewall firewall add rule name="Printer and SFTP Server" dir=in action=allow profile=domain protocol=TCP localport=515,22

netsh advfirewall firewall add rule name="Web Proxy Enterprise" dir=out action=allow profile=domain protocol=TCP localport=8080 localip=10.20.40.1

netsh advfirewall firewall add rule name="Printer Server" dir=out action=allow profile=domain protocol=TCP localport=515 localip=10.20.40.251

netsh advfirewall firewall add rule name="DNS Server" dir=out action=allow profile=domain protocol=TCP localport=53 localip=10.20.40.10,10.20.40.11

netsh advfirewall firewall add rule name="Exchange Server" dir=out action=allow profile=domain protocol=TCP localport=443,143,993,110,995,587 localip=10.20.40.60