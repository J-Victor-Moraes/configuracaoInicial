#!/bin/bash

USER_NAME="user"
USER_ID=$(id -u $USER_NAME)
IMAGE_PATH="/home/$USER_NAME/imagens_sistema/capa.png"

echo "Iniciando configuracao..."
sleep 5

############################################
# DESATIVAR SUSPENSAO
############################################

echo "Configurando a suspensão de tela"
sleep 5
gsettings set org.cinnamon.settings-daemon.plugins.power sleep-display-ac 0
gsettings set org.cinnamon.settings-daemon.plugins.power sleep-display-battery 0

gsettings set org.cinnamon.desktop.session idle-delay 0
gsettings set org.cinnamon.desktop.screensaver lock-enabled false
gsettings set org.cinnamon.settings-daemon.plugins.power lock-on-suspend false
echo "Configuração de tela finalizada"
sleep 5

############################################
# GRUPOS
############################################

echo "Executando as permissões necessárias para o usuário user"
sleep 5
sudo adduser user lp
sudo adduser user tty
sudo adduser user dialout &&\
echo "Finalizado as permissões"
sleep 5

############################################
# PERMISSAO USB
############################################

echo "Executando as permissões na porta da impressora"
sleep 5
sudo chmod -Rf 777 /dev/usb/lp1
sudo chmod -Rf 777 /dev/ttyS0
sudo chmod -Rf 777 /dev/ttyS1
sudo chmod -Rf 777 /dev/ttyACM0
sudo chmod -Rf 777 /dev/usb/lp0 &&\
echo "Permissão realizada com sucesso"
sleep 5

############################################
# EXECUTANDO O ANYDESK AO INICIAR O COMPUTADOR
############################################

echo "Executando o anydesk ao iniciar o computador"
sleep 5
sudo apt remove anydesk -y
sudo apt update
sudo apt install anydesk -y
sudo systemctl enable anydesk
sudo systemctl start anydesk 
echo "full@time15" | sudo anydesk --set-password &&\
echo "Anydesk configurado de forma correta"
sleep 5

############################################
# INSTALACAO DO SSH E NET-TOOLS
############################################

echo "Executando a instalação do net-tools e ssh"
sleep 5
sudo apt install net-tools &&\
sudo apt install ssh &&\
echo "Instalação das Ferramentas de rede realizada com sucesso"
sleep 5

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
sleep 5
sudo -u $USER_NAME DISPLAY=:0 DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$USER_ID/bus" \
gsettings set org.cinnamon.desktop.background picture-uri "file://$IMAGE_PATH"

############################################
# ICONE MENU
############################################

sudo -u user sed -i 's|"value": "linuxmint-logo-ring-symbolic"|"value": "/home/user/imagens_sistema/logo.png"|' \
/home/user/.config/cinnamon/spices/menu@cinnamon.org/0.json
echo "Finalizado as configurações de imagens"
sleep 5

############################################
# INSTALACAO PDV 
############################################

echo "Instalando ou atualizando do PDV"
sleep 5

# Configurações
REPO="J-Victor-Moraes/configuracaoInicial"
PACOTE="pdv"
CAMINHO_INI="/opt/pdv/pdv.ini"
BACKUP_INI="$HOME/pdv.ini"

# Função para realizar a instalação
instalar_pacote() {
    local url=$1
    local versao=$2
    
    if [ -z "$url" ] || [ "$url" == "null" ]; then
        echo "------------------------------------------"
        echo "ERRO: Link de download não encontrado para a versão $versao."
        echo "------------------------------------------"
        sleep 3
        return
    fi

    # ENCERRA O PDV ANTES DE QUALQUER COISA
    echo "Encerrando processos do PDV para garantir a instalação..."
    sudo pkill -9 -f "$PACOTE" 2>/dev/null
    sleep 1

    echo "------------------------------------------"
    if [ -f "$CAMINHO_INI" ]; then
        echo "Fazendo backup do pdv.ini em $BACKUP_INI..."
        cp "$CAMINHO_INI" "$BACKUP_INI"
    fi

    echo "Baixando versão: $versao..."
    rm -f pdv.deb
    wget -q --show-progress --no-cache -O pdv.deb "$url"
    
    if [ ! -s pdv.deb ]; then
        echo "ERRO: O download falhou ou o arquivo está vazio."
        sleep 3
        return
    fi

    chmod 644 pdv.deb
    echo "Instalando..."
    sudo dpkg -i ./pdv.deb
    sudo apt-get install -f -y
    
    if [ -f "$BACKUP_INI" ]; then
        echo "Restaurando pdv.ini..."
        sudo mkdir -p /opt/pdv
        sudo cp "$BACKUP_INI" "$CAMINHO_INI"
        sudo chmod 666 "$CAMINHO_INI"
    fi

    echo "Processo finalizado com sucesso!"
    exit 0
}

while true; do
    clear
    echo "=========================================="
    echo "       SISTEMA DE ATUALIZAÇÃO PDV"
    echo "=========================================="
    echo "Buscando informações no GitHub..."

    # Captura da versão LATEST (Estável)
    JSON_LATEST=$(curl -sL "https://api.github.com/repos/$REPO/releases/latest")
    VER_LATEST=$(echo "$JSON_LATEST" | grep -m 1 '"tag_name":' | cut -d'"' -f4 | tr -d 'v')
    URL_LATEST=$(echo "$JSON_LATEST" | grep "browser_download_url" | grep ".deb" | head -n 1 | cut -d'"' -f4)

    # Captura da versão BETA (Primeira da lista de releases)
    JSON_BETA=$(curl -sL "https://api.github.com/repos/$REPO/releases")
    VER_BETA=$(echo "$JSON_BETA" | grep -m 1 '"tag_name":' | cut -d'"' -f4 | tr -d 'v')
    URL_BETA=$(echo "$JSON_BETA" | grep "browser_download_url" | grep ".deb" | head -n 1 | cut -d'"' -f4)

    # Versão instalada localmente
    VER_LOCAL=$(dpkg-query -W -f='${Version}' "$PACOTE" 2>/dev/null | xargs)

    clear
    echo "=========================================="
    echo "       SISTEMA DE ATUALIZAÇÃO PDV"
    echo "=========================================="
    echo "Versão Instalada:  [${VER_LOCAL:-Não encontrada}]"
    echo ""
    echo "Disponível no Git:"
    echo "Estável (Latest):  [${VER_LATEST:-Indisponível}]"
    echo "Teste (Beta):      [${VER_BETA:-Indisponível}]"
    echo "=========================================="
    echo "1) Instalar Versão Estável (${VER_LATEST:-...})"
    echo "2) Instalar Versão de Teste (${VER_BETA:-...})"
    echo "3) Downgrade / Limpeza Total (Assistido)"
    echo "4) Sair"
    echo "=========================================="
    
    if [ -z "$VER_LATEST" ] && [ -z "$VER_BETA" ]; then
        echo "AVISO: Não foi possível conectar ao GitHub ou atingiu limite de busca."
        echo "Tentando novamente em 5 segundos..."
        sleep 5
        continue
    fi

    read -p "Escolha uma opção: " OPCAO

    case $OPCAO in
        1)
            [ -z "$URL_LATEST" ] && echo "Erro: Versão Estável sem arquivo .deb" && sleep 2 && continue
            if [ "$VER_LATEST" == "$VER_LOCAL" ]; then
                read -p "Versão idêntica. Reinstalar? (s/N): " RESP
                [[ ! "$RESP" =~ ^([sS])$ ]] && continue
            fi
            instalar_pacote "$URL_LATEST" "$VER_LATEST"
            ;;
        2)
            [ -z "$URL_BETA" ] && echo "Erro: Versão Beta sem arquivo .deb" && sleep 2 && continue
            if [ "$VER_BETA" == "$VER_LOCAL" ]; then
                read -p "Versão idêntica. Reinstalar? (s/N): " RESP
                [[ ! "$RESP" =~ ^([sS])$ ]] && continue
            fi
            instalar_pacote "$URL_BETA" "$VER_BETA"
            ;;
        3)
            echo ""
            echo ">>> MODO DOWNGRADE / LIMPEZA TOTAL <<<"
            echo "Qual versão deseja baixar para o Downgrade?"
            echo "1) Estável ($VER_LATEST)"
            echo "2) Teste ($VER_BETA)"
            read -p "Escolha: " OPCAO_DOWN
            
            if [ "$OPCAO_DOWN" == "1" ]; then
                URL_ALVO="$URL_LATEST"
                VER_ALVO="$VER_LATEST"
            elif [ "$OPCAO_DOWN" == "2" ]; then
                URL_ALVO="$URL_BETA"
                VER_ALVO="$VER_BETA"
            else
                echo "Opção inválida!" && sleep 2 && continue
            fi

            # Passo 1: Download antecipado
            echo "Passo 1/4: Baixando arquivo .deb..."
            rm -f pdv.deb
            wget -q --show-progress --no-cache -O pdv.deb "$URL_ALVO"

            if [ ! -s pdv.deb ]; then
                echo "ERRO: Falha ao baixar o arquivo. O sistema não foi alterado."
                sleep 3 && continue
            fi

            # Passo 2: Confirmação de segurança
            echo ""
            echo "--------------------------------------------------------"
            echo "AVISO: O arquivo da versão $VER_ALVO foi baixado."
            echo "Ao prosseguir, o sistema encerrará o PDV e limpará tudo."
            echo "--------------------------------------------------------"
            read -p "Deseja realizar o Downgrade/Limpeza agora? (s/N): " CONFIRM
            if [[ ! "$CONFIRM" =~ ^([sS])$ ]]; then
                echo "Operação cancelada. O arquivo baixado foi removido."
                rm -f pdv.deb
                sleep 2 && continue
            fi

            # Passo 3: Encerramento e Limpeza
            echo "Passo 2/4: Encerrando processos do PDV..."
            sudo pkill -9 -f "$PACOTE" 2>/dev/null
            sleep 1

            echo "Passo 3/4: Fazendo backup do pdv.ini e limpando /opt/pdv..."
            [ -f "$CAMINHO_INI" ] && cp "$CAMINHO_INI" "$BACKUP_INI"
            
            sudo apt remove "$PACOTE" -y
            sudo rm -rf /opt/pdv
            
            # Passo 4: Instalação
            echo "Passo 4/4: Instalando versão $VER_ALVO..."
            chmod 644 pdv.deb
            sudo dpkg -i ./pdv.deb
            sudo apt-get install -f -y
            
            if [ -f "$BACKUP_INI" ]; then
                echo "Restaurando pdv.ini..."
                sudo mkdir -p /opt/pdv
                sudo cp "$BACKUP_INI" "$CAMINHO_INI"
                sudo chmod 666 "$CAMINHO_INI"
            fi

            echo "Downgrade concluído com sucesso!"
            exit 0
            ;;
        4)
            echo "Saindo..."; exit 0
            ;;
        *)
            echo "Opção inválida!"; sleep 1
            ;;
    esac
done
sudo cp -r /opt/pdv/lib/* /usr/lib &&\
sudo nano /usr/lib/CONFITLS.INI
echo "PDV atualizado"

echo "Configuracao finalizada!"
