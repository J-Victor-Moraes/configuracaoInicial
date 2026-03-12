#!/bin/bash

# Configurações
REPO="J-Victor-Moraes/configuracaoInicial"
PACOTE="pdv"
CAMINHO_INI="/opt/pdv/pdv.ini"
BACKUP_INI="$HOME/pdv.ini"

# Função para configuração do TEF
configurar_tef() {
    echo ""
    echo "=========================================="
    echo "       CONFIGURAÇÃO ADICIONAL TEF"
    echo "=========================================="
    read -p "Possui TEF? (s/N): " POSSUI_TEF
    
    if [[ "$POSSUI_TEF" =~ ^([sS])$ ]]; then
        echo "------------------------------------------"
        echo "Configurando TLS..."
        echo "Copiando bibliotecas para /usr/lib..."
        sudo cp -r /opt/pdv/lib/* /usr/lib
        echo "Abrindo configuração TLS..."
        sudo nano /usr/lib/CONFITLS.INI
    fi
    
    echo "------------------------------------------"
    echo "Processo finalizado com sucesso!"
    exit 0
}

# Função para realizar a instalação
instalar_pacote() {
    local url=$1
    local versao=$2
    
    if [ -z "$url" ] || [ "$url" == "null" ]; then
        echo "ERRO: Link de download não encontrado."
        sleep 3
        return
    fi

    echo "Encerrando apenas processos do executável PDV..."
    # MATA APENAS O BINÁRIO USANDO FILTRO DE PID
    sudo ps aux | grep "/opt/pdv/pdv" | grep -v grep | awk '{print $2}' | xargs -r sudo kill -9 2>/dev/null
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
        echo "ERRO: O download falhou."
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

    configurar_tef
}

while true; do
    clear
    echo "=========================================="
    echo "       SISTEMA DE ATUALIZAÇÃO PDV"
    echo "=========================================="
    echo "Buscando informações no GitHub..."

    JSON_LATEST=$(curl -sL "https://api.github.com/repos/$REPO/releases/latest")
    VER_LATEST=$(echo "$JSON_LATEST" | grep -m 1 '"tag_name":' | cut -d'"' -f4 | tr -d 'v')
    URL_LATEST=$(echo "$JSON_LATEST" | grep "browser_download_url" | grep ".deb" | head -n 1 | cut -d'"' -f4)

    JSON_BETA=$(curl -sL "https://api.github.com/repos/$REPO/releases")
    VER_BETA=$(echo "$JSON_BETA" | grep -m 1 '"tag_name":' | cut -d'"' -f4 | tr -d 'v')
    URL_BETA=$(echo "$JSON_BETA" | grep "browser_download_url" | grep ".deb" | head -n 1 | cut -d'"' -f4)

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
    
    read -p "Escolha uma opção: " OPCAO

    case $OPCAO in
        1)
            [ "$VER_LATEST" == "$VER_LOCAL" ] && read -p "Reinstalar? (s/N): " RESP && [[ ! "$RESP" =~ ^([sS])$ ]] && continue
            instalar_pacote "$URL_LATEST" "$VER_LATEST"
            ;;
        2)
            [ "$VER_BETA" == "$VER_LOCAL" ] && read -p "Reinstalar? (s/N): " RESP && [[ ! "$RESP" =~ ^([sS])$ ]] && continue
            instalar_pacote "$URL_BETA" "$VER_BETA"
            ;;
        3)
            echo ">>> MODO DOWNGRADE / LIMPEZA TOTAL <<<"
            read -p "1) Estável ou 2) Teste? " OPCAO_DOWN
            [ "$OPCAO_DOWN" == "1" ] && { URL_ALVO="$URL_LATEST"; VER_ALVO="$VER_LATEST"; } || { URL_ALVO="$URL_BETA"; VER_ALVO="$VER_BETA"; }
            
            rm -f pdv.deb
            wget -q --show-progress --no-cache -O pdv.deb "$URL_ALVO"
            [ ! -s pdv.deb ] && continue

            read -p "Confirmar limpeza e downgrade? (s/N): " CONFIRM
            [[ ! "$CONFIRM" =~ ^([sS])$ ]] && continue

            # MATA APENAS O BINÁRIO AQUI TAMBÉM
            sudo ps aux | grep "/opt/pdv/pdv" | grep -v grep | awk '{print $2}' | xargs -r sudo kill -9 2>/dev/null
            sleep 1

            [ -f "$CAMINHO_INI" ] && cp "$CAMINHO_INI" "$BACKUP_INI"
            sudo apt remove "$PACOTE" -y
            sudo rm -rf /opt/pdv
            
            chmod 644 pdv.deb
            sudo dpkg -i ./pdv.deb
            sudo apt-get install -f -y
            [ -f "$BACKUP_INI" ] && { sudo mkdir -p /opt/pdv; sudo cp "$BACKUP_INI" "$CAMINHO_INI"; sudo chmod 666 "$CAMINHO_INI"; }
            configurar_tef
            ;;
        4) exit 0 ;;
        *) sleep 1 ;;
    esac
done
