#!/bin/bash

USER_NAME="user"
USER_ID=$(id -u $USER_NAME)
IMAGE_PATH="/home/$USER_NAME/imagens_sistema/capa.png"

echo "Iniciando configuracao..."

############################################
# DESATIVAR SUSPENSAO
############################################

sudo -u user gsettings set org.cinnamon.settings-daemon.plugins.power sleep-display-ac 0
sudo -u user gsettings set org.cinnamon.settings-daemon.plugins.power sleep-display-battery 0

sudo -u user gsettings set org.cinnamon.settings-daemon.plugins.power sleep-inactive-ac-type 'nothing'
sudo -u user gsettings set org.cinnamon.settings-daemon.plugins.power sleep-inactive-battery-type 'nothing'

############################################
# GRUPOS
############################################

sudo adduser user lp
sudo adduser user tty
sudo adduser user dialout

############################################
# PERMISSAO USB
############################################

sudo chmod -Rf 777 /dev/usb/lp0

############################################
# SUDO SEM SENHA
############################################

echo "user ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/user

############################################
# DIRETORIO IMAGENS
############################################

mkdir -p /home/user/imagens_sistema

############################################
# DOWNLOAD DAS IMAGENS
############################################

cp /home/user/configuracaoInicial/capa.png /home/user/imagens_sistema
cp /home/user/configuracaoInicial/logo.png /home/user/imagens_sistema

chown -R user:user /home/user/imagens_sistema

############################################
# DEFINIR WALLPAPER
############################################

sudo -u $USER_NAME DISPLAY=:0 DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$USER_ID/bus" \
gsettings set org.cinnamon.desktop.background picture-uri "file://$IMAGE_PATH"

############################################
# ICONE MENU
############################################

sudo -u user sed -i 's|"value": "linuxmint-logo-ring-symbolic"|"value": "/home/user/imagens_sistema/logo.png"|' \
/home/user/.config/cinnamon/spices/menu@cinnamon.org/0.json

############################################
# INSTALACAO PDV 
############################################

wget -O pdv.deb "https://drive.usercontent.google.com/download?id=1TEzZk55Xk5sDWYC_YqhxRamKw-LS5EAc&export=download&authuser=0&confirm=t&uuid=9224594e-c815-4ce2-b645-9afa386817a2&at=AGN2oQ2LrFENKJ1l-McldWSCrq09:1773089697757"
sudo apt install -y ./pdv_5.3.3-1_amd64.deb &&\
sudo cp -r /opt/pdv/lib/* /usr/lib &&\
sudo nano /usr/lib/CONFITLS.INI

echo "Configuracao finalizada!"
