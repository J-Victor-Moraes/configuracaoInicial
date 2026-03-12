#!/bin/bash

# Configurações
REPO="J-Victor-Moraes/configuracaoInicial"
PACOTE="pdv"
CAMINHO_INI="/opt/pdv/pdv.ini"
BACKUP_INI="$HOME/pdv.ini"

# Função para configuração do TEF (Executada após a instalação)
configurar_tef() {
    echo ""
    echo "=========================================="
    echo "       CONFIGURAÇÃO ADICIONAL TEF"
    echo "=========================================="
    read -p "Possui TEF? (s/N): " POSSUI_TEF
    
    if [[ "$POSSUI_TEF" =~ ^([sS])$ ]]; then
        echo "------------------------------------------"
        echo "Configurando TLS..."
        
        # Comando: copiar libs e abrir configuração
        echo "Copiando bibliotecas para /usr/lib..."
        sudo cp -r /opt/pdv/lib/* /usr/lib
        
        echo "Abrindo configuração TLS..."
        sudo nano /usr/lib/CONFITLS.INI
    fi
    
    echo "------------------------------------------"
    echo "Processo finalizado com sucesso!"
    exit 0
}

# Função para realizar a instalação padrão
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

    configurar_tef
}

while true; do
    clear
    echo "=========================================="
    echo "       SISTEMA DE ATUALIZAÇÃO PDV"
    echo "=========================================="
    echo "Buscando informações no GitHub..."

    # Captura das versões
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
    
    if [ -z "$VER_LATEST" ] && [ -z "$VER_BETA" ]; then
        echo "AVISO: Problema na conexão com GitHub. Tentando em 5s..."
        sleep 5
        continue
    fi

    read -p "Escolha uma opção: " OPCAO

    case $OPCAO in
        1)
            [ -z "$URL_LATEST" ] && echo "Erro: Versão Estável sem .deb" && sleep 2 && continue
            if [ "$VER_LATEST" == "$VER_LOCAL" ]; then
                read -p "Versão idêntica. Reinstalar? (s/N): " RESP
                [[ ! "$RESP" =~ ^([sS])$ ]] && continue
            fi
            instalar_pacote "$URL_LATEST" "$VER_LATEST"
            ;;
        2)
            [ -z "$URL_BETA" ] && echo "Erro: Versão Beta sem .deb" && sleep 2 && continue
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
                URL_ALVO="$URL_LATEST"; VER_ALVO="$VER_LATEST"
            elif [ "$OPCAO_DOWN" == "2" ]; then
                URL_ALVO="$URL_BETA"; VER_ALVO="$VER_BETA"
            else
                echo "Opção inválida!" && sleep 2 && continue
            fi

            # Passo 1: Download antecipado
            echo "Passo 1/4: Baixando arquivo .deb..."
            rm -f pdv.deb
            wget -q --show-progress --no-cache -O pdv.deb "$URL_ALVO"

            if [ ! -s pdv.deb ]; then
                echo "ERRO: Falha no download." && sleep 3 && continue
            fi

            # Passo 2: Confirmação
            echo "--------------------------------------------------------"
            echo "AVISO: O arquivo da versão $VER_ALVO foi baixado."
            echo "Ao prosseguir, o sistema encerrará o PDV e limpará tudo."
            echo "--------------------------------------------------------"
            read -p "Deseja realizar o Downgrade/Limpeza agora? (s/N): " CONFIRM
            if [[ ! "$CONFIRM" =~ ^([sS])$ ]]; then
                echo "Operação cancelada." && rm -f pdv.deb && sleep 2 && continue
            fi

            # Passo 3: Encerramento e Limpeza
            echo "Passo 2/4: Encerrando processos e limpando sistema..."
            sudo pkill -9 -f "$PACOTE" 2>/dev/null
            sleep 1
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

            configurar_tef
            ;;
        4) echo "Saindo..."; exit 0 ;;
        *) echo "Opção inválida!"; sleep 1 ;;
    esac
done
