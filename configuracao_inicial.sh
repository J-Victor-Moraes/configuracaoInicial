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

echo "Executando as permissões necessárias para o usuário user"
sudo adduser user lp
sudo adduser user tty
sudo adduser user dialout &&\
echo "Finalizado as permissões"

############################################
# PERMISSAO USB
############################################

echo "Executando as permissões na porta da impressora"
sudo chmod -Rf 777 /dev/usb/lp1
sudo chmod -Rf 777 /dev/ttyS0
sudo chmod -Rf 777 /dev/ttyS1
sudo chmod -Rf 777 /dev/ttyACM0
sudo chmod -Rf 777 /dev/usb/lp0 &&\
echo "Permissão realizada com sucesso"

############################################
# EXECUTANDO O ANYDESK AO INICIAR O COMPUTADOR
############################################

echo "Executando o anydesk ao iniciar o computador"
sudo apt remove anydesk -y
sudo apt update
sudo apt install anydesk -y
sudo systemctl enable anydesk
sudo systemctl start anydesk 
echo "full@time15" | sudo anydesk --set-password &&\
echo "Anydesk configurado de forma correta"

############################################
# INSTALACAO DO SSH E NET-TOOLS
############################################

echo "Executando a instalação do net-tools e ssh"
sudo apt install net-tools &&\
sudo apt install ssh &&\
echo "Instalação das Ferramentas de rede realizada com sucesso"

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

echo "Definindo wallpapper e ícone de menu"
sudo -u $USER_NAME DISPLAY=:0 DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$USER_ID/bus" \
gsettings set org.cinnamon.desktop.background picture-uri "file://$IMAGE_PATH"

############################################
# ICONE MENU
############################################

sudo -u user sed -i 's|"value": "linuxmint-logo-ring-symbolic"|"value": "/home/user/imagens_sistema/logo.png"|' \
/home/user/.config/cinnamon/spices/menu@cinnamon.org/0.json
echo "Finalizado as configurações de imagens"

############################################
# INSTALACAO PDV 
############################################

echo "Instalação a atualização do PDV"
wget -O pdv.deb "https://drive.usercontent.google.com/download?id=1TEzZk55Xk5sDWYC_YqhxRamKw-LS5EAc&export=download&authuser=0&confirm=t&uuid=9224594e-c815-4ce2-b645-9afa386817a2&at=AGN2oQ2LrFENKJ1l-McldWSCrq09:1773089697757"
sudo apt install -y ./pdv.deb &&\
sudo cp -r /opt/pdv/lib/* /usr/lib &&\
sudo nano /usr/lib/CONFITLS.INI
echo "PDV atualizado"

echo "Configuracao finalizada!"
