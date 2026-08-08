#!/bin/bash

# ============================================================
# install.sh - Instalador do Cybertrace Panel v2.4
#   Termux:  bash install.sh
#   Linux:   bash install.sh --linux
# ============================================================

VERDE='\033[1;32m'
VERMELHO='\033[1;31m'
AMARELO='\033[1;33m'
CIANO='\033[1;36m'
RESET='\033[0m'

echo -e "${CIANO}=============================================${RESET}"
echo -e "${CIANO}  CYBERTRACE PANEL v2.4 - INSTALADOR${RESET}"
echo -e "${CIANO}=============================================${RESET}"
echo ""

# Detecta sistema
if [[ "$1" == "--linux" ]]; then
    SISTEMA="linux"
elif command -v pkg &>/dev/null; then
    SISTEMA="termux"
elif command -v apt &>/dev/null; then
    SISTEMA="linux"
else
    echo -e "${VERMELHO}[!] Sistema não suportado (use Termux ou Debian/Ubuntu).${RESET}"
    exit 1
fi

echo -e "${AMARELO}[i] Sistema detectado: $SISTEMA${RESET}"

# Pacotes por sistema
if [[ "$SISTEMA" == "termux" ]]; then
    PACOTES="curl python3 git dnsutils openssl-tool qrencode"
    echo -e "${CIANO}[1/3] Atualizando pacotes...${RESET}"
    pkg update -y >/dev/null 2>&1
    echo -e "${CIANO}[2/3] Instalando dependências...${RESET}"
    pkg install -y $PACOTES
else
    PACOTES="curl python3 git dnsutils openssl qrencode whois"
    echo -e "${CIANO}[1/3] Atualizando pacotes...${RESET}"
    sudo apt update -y >/dev/null 2>&1
    echo -e "${CIANO}[2/3] Instalando dependências...${RESET}"
    sudo apt install -y $PACOTES
fi

# Permissão de execução
chmod +x cybertrace.sh install.sh 2>/dev/null

echo -e "${CIANO}[3/3] Verificando instalação...${RESET}"
FALTANDO=""
for cmd in curl python3 git dig openssl qrencode; do
    if ! command -v $cmd &>/dev/null; then
        FALTANDO="$FALTANDO $cmd"
    fi
done
if [[ -n "$FALTANDO" ]]; then
    echo -e "${AMARELO}[!] Ainda faltam: $FALTANDO${RESET}"
    echo -e "${AMARELO}    No Termux rode: pkg install -y $PACOTES${RESET}"
else
    echo -e "${VERDE}[OK] Todas as dependências instaladas!${RESET}"
fi

echo ""
echo -e "${VERDE}=============================================${RESET}"
echo -e "${VERDE}  INSTALAÇÃO CONCLUÍDA!${RESET}"
echo -e "${VERDE}=============================================${RESET}"
echo ""
echo -e "${AMARELO}Para iniciar:${RESET}"
echo -e "  ${CIANO}bash cybertrace.sh${RESET}        (menu interativo)"
echo -e "  ${CIANO}bash cybertrace.sh --help${RESET}  (todas as opções CLI)"
echo ""
echo -e "${AMARELO}Opcional (CPF completo, só Linux):${RESET}"
echo -e "  ${CIANO}pip install selenium webdriver-manager beautifulsoup4${RESET}"
echo ""
echo -e "${AMARELO}Rastreio (opcional, grátis):${RESET}"
echo -e "  ${CIANO}cadastro em linketrack.com e exporte:${RESET}"
echo -e "  ${CIANO}export LINKETRACK_USER=seu LINKETRACK_TOKEN=seu${RESET}"
echo ""