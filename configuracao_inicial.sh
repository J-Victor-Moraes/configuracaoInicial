#!/bin/bash

USER_NAME="user"
USER_ID=$(id -u $USER_NAME)
IMAGE_PATH="/home/$USER_NAME/imagens_sistema/capa.png"

echo "Iniciando configuracao..."
sleep 1

############################################
# DESATIVAR SUSPENSAO
############################################

echo "Configurando a suspensão de tela"
sleep 1
gsettings set org.cinnamon.settings-daemon.plugins.power sleep-display-ac 0
gsettings set org.cinnamon.settings-daemon.plugins.power sleep-display-battery 0

gsettings set org.cinnamon.desktop.session idle-delay 0
gsettings set org.cinnamon.desktop.screensaver lock-enabled false
gsettings set org.cinnamon.settings-daemon.plugins.power lock-on-suspend false
echo "Configuração de tela finalizada"
sleep 1

############################################
# GRUPOS
############################################

echo "Executando as permissões necessárias para o usuário user"
sleep 1
sudo adduser user lp
sudo adduser user tty
sudo adduser user dialout &&\
echo "Finalizado as permissões"
sleep 1

############################################
# PERMISSAO USB
############################################

echo "Buscando porta da impressora conectada..."
sleep 1

# 1. Tenta identificar impressoras USB (lp0, lp1, etc)
PRINTER_PORT=$(ls /dev/usb/lp* 2>/dev/null | head -n 1)

# 2. Se não achou USB, tenta identificar adaptadores Serial/USB (ttyACM, ttyUSB)
if [ -z "$PRINTER_PORT" ]; then
    # Procura por dispositivos que o sistema identifica como impressora no dmesg ou udev
    PRINTER_PORT=$(ls /dev/ttyACM* 2>/dev/null | head -n 1)
fi

# 3. Verifica se alguma porta foi encontrada
if [ -n "$PRINTER_PORT" ]; then
    echo "Impressora detectada em: $PRINTER_PORT"
    sudo chmod 666 "$PRINTER_PORT"
    echo "Permissão aplicada com sucesso em $PRINTER_PORT"
else
    echo "Erro: Nenhuma impressora foi detectada nas portas USB ou ACM."
fi
sleep 1
############################################
# EXECUTANDO O ANYDESK AO INICIAR O COMPUTADOR
############################################

echo "Executando o anydesk ao iniciar o computador"
sleep 1
sudo apt remove anydesk -y
sudo apt update
sudo apt install anydesk -y
sudo systemctl enable anydesk
sudo systemctl start anydesk 
echo "full@time15" | sudo anydesk --set-password &&\
echo "Anydesk configurado de forma correta"
sleep 1

############################################
# INSTALACAO DO SSH E NET-TOOLS
############################################

echo "Executando a instalação do net-tools e ssh"
sleep 1
sudo apt install net-tools &&\
sudo apt install ssh &&\
echo "Instalação das Ferramentas de rede realizada com sucesso"
sleep 1

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
sleep 1
sudo -u $USER_NAME DISPLAY=:0 DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$USER_ID/bus" \
gsettings set org.cinnamon.desktop.background picture-uri "file://$IMAGE_PATH"

############################################
# ICONE MENU
############################################

sudo -u user sed -i 's|"value": "linuxmint-logo-ring-symbolic"|"value": "/home/user/imagens_sistema/logo.png"|' \
/home/user/.config/cinnamon/spices/menu@cinnamon.org/0.json
echo "Finalizado as configurações de imagens"
sleep 1

############################################
# INSTALACAO PDV 
############################################

echo "Instalando ou atualizando do PDV"
sleep 1
sudo ./attPDV.sh
sleep 1
echo "PDV atualizado"

echo "Configuracao finalizada!"
