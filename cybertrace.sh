#!/bin/bash

# =============================================
# CYBERTRACE v2.0 - Painel de Investigação
# Consultas com APIs públicas reais
# =============================================
#
# INSTALAÇÃO NO TERMUX:
#   pkg update && pkg upgrade -y
#   pkg install -y curl python3 git
#   git clone https://github.com/carlos46743/cybertrace-panel.git
#   cd cybertrace-panel
#   bash cybertrace.sh
#
# INSTALAÇÃO NO LINUX (Debian/Ubuntu):
#   sudo apt update && sudo apt install -y curl python3 git
#   git clone https://github.com/carlos46743/cybertrace-panel.git
#   cd cybertrace-panel
#   bash cybertrace.sh
#
# CPF COMPLETO (opção 11) requer adicional:
#   pip install selenium webdriver-manager beautifulsoup4
#   # E ter o Google Chrome ou Chromium instalado
#
# DEPENDÊNCIAS:
#   curl         → consultas HTTP (IP, CNPJ, CEP, Placa, etc)
#   python3      → processamento JSON e validações
#   dig (dnsutils) → consultas DNS e WHOIS
#   git         → clonar o repositório (instalação)
#   qrencode    → gerar QR Code (opcional, ferramentas extras)
# =============================================

VERDE="\033[1;32m"
VERMELHO="\033[1;31m"
AZUL="\033[1;34m"
AMARELO="\033[1;33m"
CIANO="\033[1;36m"
RESET="\033[0m"

# =============================================
# HELP / USO VIA TERMINAL
# =============================================
show_help() {
    echo -e "${CIANO}CYBERTRACE v2.0 - Painel de Investigação Digital${RESET}"
    echo -e "${AMARELO}Uso:${RESET} bash cybertrace.sh [opção]"
    echo ""
    echo -e "${VERDE}Opções:${RESET}"
    echo -e "  ${AMARELO}sem argumentos${RESET}  → Menu interativo"
    echo -e "  ${AMARELO}--help${RESET}          → Mostra esta ajuda"
    echo -e "  ${AMARELO}--ip <IP>${RESET}       → Geolocalização de IP"
    echo -e "  ${AMARELO}--cnpj <CNPJ>${RESET}   → Consulta CNPJ (BrasilAPI)"
    echo -e "  ${AMARELO}--cep <CEP>${RESET}     → Consulta CEP (ViaCEP)"
    echo -e "  ${AMARELO}--cpf <CPF>${RESET}     → Valida CPF"
    echo -e "  ${AMARELO}--placa <PLACA>${RESET}  → Consulta veículo (FIPE)"
    echo ""
    echo -e "${VERDE}Instalação Termux:${RESET}"
    echo "  pkg install -y curl python3 git"
    echo "  git clone https://github.com/carlos46743/cybertrace-panel.git"
    echo "  cd cybertrace-panel && bash cybertrace.sh"
    echo ""
    echo -e "${VERDE}Instalação Linux:${RESET}"
    echo "  sudo apt install -y curl python3 git dnsutils"
    echo "  git clone https://github.com/carlos46743/cybertrace-panel.git"
    echo "  cd cybertrace-panel && bash cybertrace.sh"
    echo ""
    echo -e "${VERDE}CPF Completo (opção 11 do menu):${RESET}"
    echo "  pip install selenium webdriver-manager beautifulsoup4"
    echo "  # Requer Google Chrome/Chromium instalado"
    exit 0
}

# Processa argumentos de linha de comando
case "$1" in
    --help|-h) show_help ;;
    --ip) buscar_ip_direto "$2"; exit 0 ;;
    --cnpj) buscar_cnpj_direto "$2"; exit 0 ;;
    --cep) buscar_cep_direto "$2"; exit 0 ;;
    --cpf) validar_cpf_direto "$2"; exit 0 ;;
    --placa) buscar_placa_direto "$2"; exit 0 ;;
esac

banner() {
    clear
    echo -e "${VERMELHO}"
    echo "╔═══════════════════════════════════════════════╗"
    echo "║                                               ║"
    echo -e "║     ${CIANO}██████╗██╗   ██╗██████╗ ███████╗██████╗${VERMELHO}    ║"
    echo -e "║     ${CIANO}██╔══██╗╚██╗ ██╔╝██╔══██╗██╔════╝██╔══██╗${VERMELHO}   ║"
    echo -e "║     ${CIANO}██████╔╝ ╚████╔╝ ██████╔╝█████╗  ██████╔╝${VERMELHO}   ║"
    echo -e "║     ${CIANO}██╔══██╗  ╚██╔╝  ██╔══██╗██╔══╝  ██╔══██╗${VERMELHO}   ║"
    echo -e "║     ${CIANO}██████╔╝   ██║   ██████╔╝███████╗██║  ██║${VERMELHO}   ║"
    echo -e "║     ${CIANO}╚═════╝    ╚═╝   ╚═════╝ ╚══════╝╚═╝  ╚═╝${VERMELHO}   ║"
    echo "║                                               ║"
    echo "╠═══════════════════════════════════════════════╣"
    echo -e "║   ${AMARELO}🔍 PAINEL DE INVESTIGAÇÃO DIGITAL v2.0${VERMELHO}   ║"
    echo -e "║   ${CIANO}🌐 github.com/carlos46743/cybertrace-panel${VERMELHO}  ║"
    echo "╚═══════════════════════════════════════════════╝"
    echo -e "${RESET}"
}

# =============================================
# Funções diretas (chamadas via argumento CLI)
# =============================================
buscar_ip_direto() { local ip="$1"; echo -e "${CIANO}Buscando IP $ip...${RESET}"; curl -s "http://ip-api.com/json/${ip}?fields=status,country,region,city,isp,org,query" | python3 -c "import sys,json; d=json.load(sys.stdin); [print(f'{k}: {v}') for k,v in d.items()]" 2>/dev/null; }
buscar_cnpj_direto() { local cnpj="$1"; echo -e "${CIANO}Consultando CNPJ $cnpj...${RESET}"; curl -s "https://brasilapi.com.br/api/cnpj/v1/$cnpj" | python3 -c "import sys,json; d=json.load(sys.stdin); [print(f'{k}: {v}') for k,v in d.items()]" 2>/dev/null; }
buscar_cep_direto() { local cep="$1"; echo -e "${CIANO}Consultando CEP $cep...${RESET}"; curl -s "https://viacep.com.br/ws/$cep/json/" | python3 -c "import sys,json; d=json.load(sys.stdin); [print(f'{k}: {v}') for k,v in d.items()]" 2>/dev/null; }
validar_cpf_direto() { 
    local cpf=$(echo "$1" | tr -d ' .-')
    python3 -c "
cpf='$cpf'
d1,d2=int(cpf[9]),int(cpf[10])
r1=(sum(int(cpf[i])*(10-i) for i in range(9))*10)%11
r2=(sum(int(cpf[i])*(11-i) for i in range(10))*10)%11
if r1==10: r1=0
if r2==10: r2=0
v=r1==d1 and r2==d2
e={0:'RS',1:'DF/GO/MS/MT',2:'PA/AM/AC/RO/RR',3:'CE/MA/PI',4:'PE/PB/RN/AL',5:'BA/SE',6:'MG',7:'RJ/ES',8:'SP',9:'PR/SC'}
print(f'CPF: {cpf[:3]}.{cpf[3:6]}.{cpf[6:9]}-{cpf[9:]}')
print(f'Valido: {\"SIM\" if v else \"NAO\"}')
if v: print(f'UF: {e.get(int(cpf[8]),\"?\")}')
" 2>/dev/null
}
buscar_placa_direto() { 
    local placa=$(echo "$1" | tr 'a-z' 'A-Z')
    echo -e "${CIANO}Consultando placa $placa...${RESET}"
    curl -s "https://brasilapi.com.br/api/fipe/preco/v1/$placa" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d if isinstance(d,str) else '\n'.join(f'{k}: {v}' for k,v in (d[0] if isinstance(d,list) else d).items()))" 2>/dev/null
}

menu() {
    banner
    echo -e "${CIANO}╔═══════════════════════════════════════════════╗${RESET}"
    echo -e "${CIANO}║${RESET}   ${AMARELO}1.${RESET} 📍 Buscar IP (ip-api.com real)      ${CIANO}║${RESET}"
    echo -e "${CIANO}║${RESET}   ${AMARELO}2.${RESET} 📱 Dados de Telefone                ${CIANO}║${RESET}"
    echo -e "${CIANO}║${RESET}   ${AMARELO}3.${RESET} 🚗 Buscar Placa (API real)          ${CIANO}║${RESET}"
    echo -e "${CIANO}║${RESET}   ${AMARELO}4.${RESET} 🆔 CNPJ (BrasilAPI - Receita)       ${CIANO}║${RESET}"
    echo -e "${CIANO}║${RESET}   ${AMARELO}5.${RESET} 📇 CPF (validação + dígitos)        ${CIANO}║${RESET}"
    echo -e "${CIANO}║${RESET}   ${AMARELO}6.${RESET} 🌐 Buscar Domínio                  ${CIANO}║${RESET}"
    echo -e "${CIANO}║${RESET}   ${AMARELO}7.${RESET} 🔍 Buscar Nome (Google Dork)       ${CIANO}║${RESET}"
    echo -e "${CIANO}║${RESET}   ${AMARELO}8.${RESET} 👤 Redes Sociais (username)        ${CIANO}║${RESET}"
    echo -e "${CIANO}║${RESET}   ${AMARELO}9.${RESET} 📧 Consultar E-mail                ${CIANO}║${RESET}"
    echo -e "${CIANO}║${RESET}   ${AMARELO}10.${RESET} 📮 CEP (ViaCEP - rua, bairro)     ${CIANO}║${RESET}"
    echo -e "${CIANO}║${RESET}   ${AMARELO}11.${RESET} 🆔 CPF Completo (Selenium)         ${CIANO}║${RESET}"
    echo -e "${CIANO}║${RESET}   ${AMARELO}12.${RESET} 🛠️  Ferramentas Extras            ${CIANO}║${RESET}"
    echo -e "${CIANO}║${RESET}   ${AMARELO}0.${RESET} ❌ Sair                            ${CIANO}║${RESET}"
    echo -e "${CIANO}╚═══════════════════════════════════════════════╝${RESET}"
    echo ""
    echo -ne "${VERDE}➜ Escolha: ${RESET}"
    read opcao
    case $opcao in
        1) buscar_ip ;;
        2) buscar_telefone ;;
        3) buscar_placa ;;
        4) buscar_cnpj ;;
        5) validar_cpf ;;
        6) buscar_dominio ;;
        7) buscar_nome ;;
        8) redes_sociais ;;
        9) consultar_email ;;
        10) buscar_cep ;;
        11) buscar_cpf_completo ;;
        12) ferramentas_extras ;;
        0) exit 0 ;;
        *) echo -e "${VERMELHO}Inválido!${RESET}"; sleep 2; menu ;;
    esac
}

buscar_ip() {
    banner
    echo -e "${AZUL}╔═══════════════════════════════════════════════╗${RESET}"
    echo -e "${AZUL}║${RESET}   ${VERDE}📍 GEOLOCALIZAÇÃO POR IP (API REAL)${RESET}     ${AZUL}║${RESET}"
    echo -e "${AZUL}╚═══════════════════════════════════════════════╝${RESET}"
    echo ""
    echo -ne "${AMARELO}IP (ex: 8.8.8.8) ou Enter p/ seu IP: ${RESET}"
    read ip
    if [[ -z "$ip" ]]; then
        ip=$(curl -s ifconfig.me 2>/dev/null)
        echo -e "${CIANO}➜ Seu IP: $ip${RESET}"
    fi
    echo -e "${CIANO}Consultando...${RESET}"
    data=$(curl -s "http://ip-api.com/json/${ip}?fields=status,country,countryCode,region,city,zip,lat,lon,isp,org,as,timezone,query")
    status=$(echo "$data" | grep -o '"status":"[^"]*"' | cut -d'"' -f4)
    if [[ "$status" == "success" ]]; then
        echo "$data" | python3 -c "
import sys,json
d=json.load(sys.stdin)
print('${VERDE}════════════════════════════════════════════${RESET}')
print(f'${AMARELO}🌍 IP:${RESET} {d[\"query\"]}')
print(f'${AMARELO}📍 País:${RESET} {d[\"country\"]} ({d.get(\"countryCode\",\"\")})')
print(f'${AMARELO}🏙️ Cidade:${RESET} {d.get(\"city\",\"\")} - {d.get(\"region\",\"\")}')
print(f'${AMARELO}📮 CEP:${RESET} {d.get(\"zip\",\"\")}')
print(f'${AMARELO}🌐 Coord:${RESET} {d.get(\"lat\",\"\")}, {d.get(\"lon\",\"\")}')
print(f'${AMARELO}🏢 ISP:${RESET} {d.get(\"isp\",\"\")}')
print(f'${AMARELO}📡 Org:${RESET} {d.get(\"org\",\"\")}')
print(f'${AMARELO}🔗 ASN:${RESET} {d.get(\"as\",\"\")}')
print(f'${AMARELO}🕐 TZ:${RESET} {d.get(\"timezone\",\"\")}')
print(f'${AMARELO}🗺️ Mapa:${RESET} https://www.google.com/maps?q={d.get(\"lat\",\"\")},{d.get(\"lon\",\"\")}')
        " 2>/dev/null
    else
        echo -e "${VERMELHO}IP inválido${RESET}"
    fi
    echo ""; read -p "ENTER p/ voltar"; menu
}

buscar_telefone() {
    banner
    echo -e "${AZUL}╔═══════════════════════════════════════════════╗${RESET}"
    echo -e "${AZUL}║${RESET}   ${VERDE}📱 CONSULTAR TELEFONE${RESET}                    ${AZUL}║${RESET}"
    echo -e "${AZUL}╚═══════════════════════════════════════════════╝${RESET}"
    echo ""
    echo -e "${AMARELO}📌 APIs gratuitas: numverify, abstractapi, etc${RESET}"
    echo -ne "${AMARELO}Número (55 11 999999999): ${RESET}"
    read tel
    tel=$(echo "$tel" | tr -d ' +-')
    if [[ ${#tel} -lt 12 ]]; then
        echo -e "${VERMELHO}Número muito curto (use com código do país)${RESET}"
        sleep 2; menu; return
    fi
    echo -e "${CIANO}Consultando dados básicos...${RESET}"
    pais="${tel:0:2}"
    ddd="${tel:2:2}"
    numero="${tel:4}"
    echo -e "${VERDE}════════════════════════════════════════════${RESET}"
    echo -e "${AMARELO}📞 Número completo:${RESET} +$tel"
    echo -e "${AMARELO}🌍 País:${RESET} $( [[ "$pais" == "55" ]] && echo "Brasil" || echo "$pais")"
    echo -e "${AMARELO}📌 DDD:${RESET} $ddd"
    echo -e "${AMARELO}📱 Número:${RESET} $numero"
    echo -e "${AMARELO}🔢 Tipo:${RESET} $( [[ ${#numero} -eq 9 ]] && echo "Celular" || echo "Fixo")"
    op=$( [[ "$numero:0:1" == "9" ]] && echo "Vivo" || echo "TIM/Claro/Oi" )
    echo -e "${AMARELO}📡 Operadora provável:${RESET} $op"
    case $ddd in
        11) echo -e "${AMARELO}📍 Região:${RESET} São Paulo - SP" ;;
        21) echo -e "${AMARELO}📍 Região:${RESET} Rio de Janeiro - RJ" ;;
        31) echo -e "${AMARELO}📍 Região:${RESET} Belo Horizonte - MG" ;;
        41) echo -e "${AMARELO}📍 Região:${RESET} Curitiba - PR" ;;
        51) echo -e "${AMARELO}📍 Região:${RESET} Porto Alegre - RS" ;;
        61) echo -e "${AMARELO}📍 Região:${RESET} Brasília - DF" ;;
        71) echo -e "${AMARELO}📍 Região:${RESET} Salvador - BA" ;;
        81) echo -e "${AMARELO}📍 Região:${RESET} Recife - PE" ;;
        85) echo -e "${AMARELO}📍 Região:${RESET} Fortaleza - CE" ;;
        91) echo -e "${AMARELO}📍 Região:${RESET} Belém - PA" ;;
        *) echo -e "${AMARELO}📍 Região:${RESET} Consulte online" ;;
    esac
    echo -e "${CIANO}💡 Dica: consulte https://consultanumero.com/${RESET}"
    echo -e "${VERDE}════════════════════════════════════════════${RESET}"
    echo ""; read -p "ENTER p/ voltar"; menu
}

buscar_placa() {
    banner
    echo -e "${AZUL}╔═══════════════════════════════════════════════╗${RESET}"
    echo -e "${AZUL}║${RESET}   ${VERDE}🚗 CONSULTAR PLACA (API PÚBLICA)${RESET}          ${AZUL}║${RESET}"
    echo -e "${AZUL}╚═══════════════════════════════════════════════╝${RESET}"
    echo ""
    echo -ne "${AMARELO}Placa (ABC1234 ou ABC1D23 Mercosul): ${RESET}"
    read placa
    placa=$(echo "$placa" | tr 'a-z' 'A-Z' | tr -d ' ')
    if [[ ${#placa} -lt 7 ]]; then
        echo -e "${VERMELHO}Placa inválida${RESET}"; sleep 2; menu; return
    fi
    echo -e "${CIANO}Consultando API BrasilAPI/FIPE...${RESET}"
    result=$(curl -s "https://brasilapi.com.br/api/fipe/preco/v1/$(echo "$placa" | sed 's/[^A-Z0-9]//g')" 2>/dev/null)
    if echo "$result" | grep -q '"erro"\|"error"\|"message"'; then
        echo -e "${AMARELO}⚠️ API FIPE sem dados p/ esta placa. Buscando dados básicos...${RESET}"
        echo -e "${VERDE}════════════════════════════════════════════${RESET}"
        echo -e "${AMARELO}🔢 Placa:${RESET} $placa"
        echo -e "${AMARELO}📌 Formato:${RESET} $( [[ ${#placa} -eq 7 ]] && echo "Padrão antigo" || echo "Mercosul")"
        echo -e "${CIANO}💡 Consulte: https://www.ipva.fazenda.sp.gov.br/${RESET}"
        echo -e "${CIANO}💡 Ou: https://portalservicos.denatran.serpro.gov.br/${RESET}"
    else
        echo "$result" | python3 -c "
import sys,json
try:
    d=json.load(sys.stdin)
    if isinstance(d,list): d=d[0]
    print('${VERDE}════════════════════════════════════════════${RESET}')
    print(f'${AMARELO}🔢 Placa:${RESET} $placa')
    for k,v in d.items():
        print(f'${AMARELO}• {k}:${RESET} {v}')
except: pass
        " 2>/dev/null
    fi
    echo ""; read -p "ENTER p/ voltar"; menu
}

buscar_cnpj() {
    banner
    echo -e "${AZUL}╔═══════════════════════════════════════════════╗${RESET}"
    echo -e "${AZUL}║${RESET}   ${VERDE}🆔 CNPJ REAL (BrasilAPI - Receita Federal)${RESET} ${AZUL}║${RESET}"
    echo -e "${AZUL}╚═══════════════════════════════════════════════╝${RESET}"
    echo ""
    echo -ne "${AMARELO}CNPJ (apenas números): ${RESET}"
    read cnpj
    cnpj=$(echo "$cnpj" | tr -d ' ./-')
    if [[ ${#cnpj} -ne 14 ]]; then
        echo -e "${VERMELHO}CNPJ deve ter 14 dígitos${RESET}"; sleep 2; menu; return
    fi
    echo -e "${CIANO}Consultando Receita Federal via BrasilAPI...${RESET}"
    result=$(curl -s "https://brasilapi.com.br/api/cnpj/v1/$cnpj")
    if echo "$result" | grep -q '"message"\|"erro"'; then
        echo -e "${VERMELHO}CNPJ não encontrado ou inválido${RESET}"
    else
        echo "$result" | python3 -c "
import sys,json
d=json.load(sys.stdin)
print('${VERDE}════════════════════════════════════════════${RESET}')
print(f'${AMARELO}🏢 CNPJ:${RESET} {d.get(\"cnpj\",\"\")}')
print(f'${AMARELO}📛 Razão Social:${RESET} {d.get(\"razao_social\",\"\")}')
print(f'${AMARELO}🧑 Nome Fantasia:${RESET} {d.get(\"nome_fantasia\",\"\")}')
print(f'${AMARELO}🏠 Endereço:${RESET} {d.get(\"logradouro\",\"\")}, {d.get(\"numero\",\"\")} - {d.get(\"bairro\",\"\")}')
print(f'${AMARELO}📍 Cidade/UF:${RESET} {d.get(\"municipio\",\"\")}/{d.get(\"uf\",\"\")} - {d.get(\"cep\",\"\")}')
print(f'${AMARELO}📞 Telefone:${RESET} {d.get(\"ddd_telefone_1\",\"\")}')
print(f'${AMARELO}📧 Email:${RESET} {d.get(\"email\",\"\")}')
print(f'${AMARELO}🏭 Porte:${RESET} {d.get(\"porte\",\"\")}')
print(f'${AMARELO}📅 Abertura:${RESET} {d.get(\"data_inicio_atividade\",\"\")}')
print(f'${AMARELO}📊 Situação:${RESET} {d.get(\"situacao_cadastral\",\"\")} ({d.get(\"data_situacao_cadastral\",\"\")})')
print(f'${AMARELO}💰 Capital:${RESET} R$ {d.get(\"capital_social\",\"\")}')
print(f'${AMARELO}🏛️ Natureza Jurídica:${RESET} {d.get(\"natureza_juridica\",\"\")}')
print(f'${AMARELO}📋 CNAE:${RESET} {d.get(\"cnae_fiscal\",\"\")} - {d.get(\"cnae_fiscal_descricao\",\"\")}')
print('${VERDE}════════════════════════════════════════════${RESET}')
        " 2>/dev/null
    fi
    echo ""; read -p "ENTER p/ voltar"; menu
}

validar_cpf() {
    banner
    echo -e "${AZUL}╔═══════════════════════════════════════════════╗${RESET}"
    echo -e "${AZUL}║${RESET}   ${VERDE}📇 VALIDAÇÃO DE CPF${RESET}                      ${AZUL}║${RESET}"
    echo -e "${AZUL}╚═══════════════════════════════════════════════╝${RESET}"
    echo ""
    echo -e "${VERMELHO}⚠️ Dados reais de CPF são protegidos por lei${RESET}"
    echo -e "${AMARELO}   Só é possível validar os dígitos (verificar se é válido)${RESET}"
    echo ""
    echo -ne "${AMARELO}CPF (11 dígitos): ${RESET}"
    read cpf
    cpf=$(echo "$cpf" | tr -d ' .-')
    if [[ ${#cpf} -ne 11 ]]; then
        echo -e "${VERMELHO}CPF inválido${RESET}"; sleep 2; menu; return
    fi
    python3 -c "
cpf = '$cpf'
dv1 = int(cpf[9])
dv2 = int(cpf[10])
s1 = sum(int(cpf[i]) * (10 - i) for i in range(9))
r1 = (s1 * 10) % 11
if r1 == 10: r1 = 0
s2 = sum(int(cpf[i]) * (11 - i) for i in range(10))
r2 = (s2 * 10) % 11
if r2 == 10: r2 = 0
valido = r1 == dv1 and r2 == dv2
print(f'${VERDE}════════════════════════════════════════════${RESET}')
print(f'${AMARELO}🆔 CPF:${RESET} {cpf[:3]}.{cpf[3:6]}.{cpf[6:9]}-{cpf[9:]}')
print(f'${AMARELO}✅ Válido:${RESET} {\"${VERDE}SIM${RESET}\" if valido else \"${VERMELHO}NÃO${RESET}\"}')
if valido:
    estados = {0:'RS',1:'DF/GO/MS/MT',2:'PA/AM/AC/RO/RR',3:'CE/MA/PI',4:'PE/PB/RN/AL',5:'BA/SE',6:'MG',7:'RJ/ES',8:'SP',9:'PR/SC'}
    print(f'${AMARELO}📍 UF emissor:${RESET} {estados.get(int(cpf[8]),\"Desconhecido\")}')
    print(f'${AMARELO}🔢 Dígitos:${RESET} Válidos')
print(f'${VERDE}════════════════════════════════════════════${RESET}')
    " 2>/dev/null
    echo ""; read -p "ENTER p/ voltar"; menu
}

buscar_dominio() {
    banner
    echo -e "${AZUL}╔═══════════════════════════════════════════════╗${RESET}"
    echo -e "${AZUL}║${RESET}   ${VERDE}🌐 CONSULTAR DOMÍNIO${RESET}                     ${AZUL}║${RESET}"
    echo -e "${AZUL}╚═══════════════════════════════════════════════╝${RESET}"
    echo ""
    echo -ne "${AMARELO}Domínio (ex: google.com): ${RESET}"
    read dominio
    [[ -z "$dominio" ]] && { echo -e "${VERMELHO}Inválido${RESET}"; sleep 2; menu; return; }
    echo -e "${CIANO}Consultando DNS e WHOIS...${RESET}"
    ip=$(dig +short "$dominio" 2>/dev/null | head -1)
    if [[ -n "$ip" ]]; then
        echo -e "${VERDE}════════════════════════════════════════════${RESET}"
        echo -e "${AMARELO}🌐 Domínio:${RESET} $dominio"
        echo -e "${AMARELO}📡 IP:${RESET} $ip"
        whois_data=$(whois "$dominio" 2>/dev/null | head -30)
        echo "$whois_data" | grep -iE "registrant|owner|email|country|created|expir|name|organization" | head -10 | while read line; do
            echo -e "${AMARELO}📋 ${RESET}$line"
        done
        echo -e "${AMARELO}🔗 Mais:${RESET} https://www.registro.br/cgi-bin/whois/?qr=$dominio"
    else
        echo -e "${VERMELHO}Domínio não encontrado${RESET}"
    fi
    echo ""; read -p "ENTER p/ voltar"; menu
}

buscar_nome() {
    banner
    echo -e "${AZUL}╔═══════════════════════════════════════════════╗${RESET}"
    echo -e "${AZUL}║${RESET}   ${VERDE}🔍 BUSCAR NOME (Google Dorking)${RESET}            ${AZUL}║${RESET}"
    echo -e "${AZUL}╚═══════════════════════════════════════════════╝${RESET}"
    echo ""
    echo -ne "${AMARELO}Nome completo: ${RESET}"
    read nome
    [[ -z "$nome" ]] && { echo -e "${VERMELHO}Inválido${RESET}"; sleep 2; menu; return; }
    nome_encoded=$(echo "$nome" | sed 's/ /+/g')
    echo -e "${CIANO}Buscando informações públicas sobre: $nome${RESET}"
    echo -e "${VERDE}════════════════════════════════════════════${RESET}"
    echo -e "${AMARELO}🔗 Google:${RESET} https://www.google.com/search?q=$nome_encoded"
    echo -e "${AMARELO}🔗 LinkedIn:${RESET} https://www.linkedin.com/search/results/all/?keywords=$nome_encoded"
    echo -e "${AMARELO}🔗 Facebook:${RESET} https://www.facebook.com/search/top/?q=$nome_encoded"
    echo -e "${AMARELO}🔗 Instagram:${RESET} https://www.instagram.com/$nome_encoded/"
    echo -e "${AMARELO}🔗 Twitter/X:${RESET} https://twitter.com/search?q=$nome_encoded"
    echo -e "${AMARELO}🔗 YouTube:${RESET} https://www.youtube.com/results?search_query=$nome_encoded"
    echo -e "${AMARELO}🔗 Escavador:${RESET} https://www.escavador.com/?q=$nome_encoded"
    echo -e "${AMARELO}🔗 JusBrasil:${RESET} https://www.jusbrasil.com.br/busca?q=$nome_encoded"
    echo -e "${AMARELO}🔗 Registro.br:${RESET} https://www.registro.br/cgi-bin/whois/?qr=$nome_encoded"
    echo -e "${AMARELO}🔗 Telegram:${RESET} https://t.me/s?q=$nome_encoded"
    echo -e "${VERDE}════════════════════════════════════════════${RESET}"
    echo ""
    echo -ne "${AMARELO}Quer abrir no navegador? (s/N): ${RESET}"
    read resp
    if [[ "$resp" == "s" || "$resp" == "S" ]]; then
        termux-open-url "https://www.google.com/search?q=$nome_encoded" 2>/dev/null
    fi
    echo ""; read -p "ENTER p/ voltar"; menu
}

redes_sociais() {
    banner
    echo -e "${AZUL}╔═══════════════════════════════════════════════╗${RESET}"
    echo -e "${AZUL}║${RESET}   ${VERDE}👤 BUSCAR USERNAME EM REDES SOCIAIS${RESET}      ${AZUL}║${RESET}"
    echo -e "${AZUL}╚═══════════════════════════════════════════════╝${RESET}"
    echo ""
    echo -ne "${AMARELO}Username: ${RESET}"
    read user
    [[ -z "$user" ]] && { echo -e "${VERMELHO}Inválido${RESET}"; sleep 2; menu; return; }
    echo -e "${CIANO}Verificando presença online de: @$user${RESET}"
    echo -e "${VERDE}════════════════════════════════════════════${RESET}"
    sites=(
        "Instagram:https://www.instagram.com/$user"
        "Twitter/X:https://twitter.com/$user"
        "GitHub:https://github.com/$user"
        "LinkedIn:https://www.linkedin.com/in/$user"
        "Facebook:https://www.facebook.com/$user"
        "TikTok:https://www.tiktok.com/@$user"
        "YouTube:https://www.youtube.com/@$user"
        "Reddit:https://www.reddit.com/user/$user"
        "Telegram:https://t.me/$user"
        "WhatsApp:https://wa.me/$user"
        "Pinterest:https://pinterest.com/$user"
        "Twitch:https://www.twitch.tv/$user"
        "Spotify:https://open.spotify.com/user/$user"
        "Medium:https://medium.com/@$user"
        "Dev.to:https://dev.to/$user"
        "Steam:https://steamcommunity.com/id/$user"
        "Discord:https://discord.com/users/$user"
        "Snapchat:https://www.snapchat.com/add/$user"
        "SoundCloud:https://soundcloud.com/$user"
        "Behance:https://www.behance.net/$user"
        "Dribbble:https://dribbble.com/$user"
        "Vimeo:https://vimeo.com/$user"
        "Flickr:https://www.flickr.com/people/$user"
        "Tumblr:https://$user.tumblr.com"
        "WordPress:https://$user.wordpress.com"
        "Blogger:https://$user.blogspot.com"
    )
    for site in "${sites[@]}"; do
        nome_site="${site%%:*}"
        url="${site#*:}"
        echo -e "${CIANO}• ${AMARELO}$nome_site:${RESET} $url"
    done
    echo -e "${VERDE}════════════════════════════════════════════${RESET}"
    echo ""
    echo -ne "${AMARELO}Verificar quais existem (HTTP check)? (s/N): ${RESET}"
    read check
    if [[ "$check" == "s" || "$check" == "S" ]]; then
        echo ""
        echo -e "${CIANO}Verificando perfis existentes...${RESET}"
        for site in "${sites[@]}"; do
            nome_site="${site%%:*}"
            url="${site#*:}"
            code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "$url" 2>/dev/null)
            if [[ "$code" != "404" && "$code" != "000" ]]; then
                echo -e "  ${VERDE}✅ $nome_site${RESET} ($code) - $url"
            fi
        done
    fi
    echo ""; read -p "ENTER p/ voltar"; menu
}

consultar_email() {
    banner
    echo -e "${AZUL}╔═══════════════════════════════════════════════╗${RESET}"
    echo -e "${AZUL}║${RESET}   ${VERDE}📧 CONSULTAR E-MAIL${RESET}                       ${AZUL}║${RESET}"
    echo -e "${AZUL}╚═══════════════════════════════════════════════╝${RESET}"
    echo ""
    echo -ne "${AMARELO}E-mail: ${RESET}"
    read email
    [[ -z "$email" ]] && { echo -e "${VERMELHO}Inválido${RESET}"; sleep 2; menu; return; }
    dominio=$(echo "$email" | cut -d'@' -f2)
    usuario=$(echo "$email" | cut -d'@' -f1)
    echo -e "${VERDE}════════════════════════════════════════════${RESET}"
    echo -e "${AMARELO}📧 E-mail:${RESET} $email"
    echo -e "${AMARELO}🌐 Domínio:${RESET} $dominio"
    ip=$(dig +short "$dominio" | head -1)
    echo -e "${AMARELO}📡 IP do servidor:${RESET} ${ip:-Não resolvido}"
    mx=$(dig +short MX "$dominio" | head -3)
    echo -e "${AMARELO}📬 Servidor MX:${RESET}"
    echo "$mx" | while read line; do echo "   $line"; done
    echo -e "${AMARELO}🔍 Have I Been Pwned:${RESET} https://haveibeenpwned.com/account/$email"
    echo -e "${AMARELO}🔗 Gravatar:${RESET} https://www.gravatar.com/avatar/$(echo -n "$email" | md5sum 2>/dev/null | cut -d' ' -f1)"
    echo -e "${AMARELO}🔍 Google:${RESET} https://www.google.com/search?q=$email"
    echo -e "${VERDE}════════════════════════════════════════════${RESET}"
    echo ""; read -p "ENTER p/ voltar"; menu
}

buscar_cep() {
    banner
    echo -e "${AZUL}╔═══════════════════════════════════════════════╗${RESET}"
    echo -e "${AZUL}║${RESET}   ${VERDE}📮 CONSULTAR CEP (ViaCEP API)${RESET}               ${AZUL}║${RESET}"
    echo -e "${AZUL}╚═══════════════════════════════════════════════╝${RESET}"
    echo ""
    echo -ne "${AMARELO}CEP (apenas números): ${RESET}"
    read cep
    cep=$(echo "$cep" | tr -d ' -')
    if [[ ${#cep} -ne 8 ]]; then
        echo -e "${VERMELHO}CEP deve ter 8 dígitos${RESET}"; sleep 2; menu; return
    fi
    echo -e "${CIANO}Consultando ViaCEP...${RESET}"
    data=$(curl -s "https://viacep.com.br/ws/$cep/json/")
    if echo "$data" | grep -q '"erro"'; then
        echo -e "${VERMELHO}CEP não encontrado${RESET}"
    else
        echo "$data" | python3 -c "
import sys,json
d=json.load(sys.stdin)
print('${VERDE}════════════════════════════════════════════${RESET}')
print(f'${AMARELO}📮 CEP:${RESET} {d.get(\"cep\",\"\")}')
print(f'${AMARELO}🏠 Logradouro:${RESET} {d.get(\"logradouro\",\"\")}')
print(f'${AMARELO}📍 Bairro:${RESET} {d.get(\"bairro\",\"\")}')
print(f'${AMARELO}🏙️ Cidade:${RESET} {d.get(\"localidade\",\"\")}')
print(f'${AMARELO}🌍 UF:${RESET} {d.get(\"uf\",\"\")} ({d.get(\"estado\",\"\")})')
print(f'${AMARELO}🔢 DDD:${RESET} {d.get(\"ddd\",\"\")}')
print(f'${AMARELO}📋 IBGE:${RESET} {d.get(\"ibge\",\"\")}')
print(f'${AMARELO}🗺️ Região:${RESET} {d.get(\"regiao\",\"\")}')
print(f'${AMARELO}🏛️ Complemento:${RESET} {d.get(\"complemento\",\"\")}')
print('${VERDE}════════════════════════════════════════════${RESET}')
        " 2>/dev/null
    fi
    echo ""; read -p "ENTER p/ voltar"; menu
}

buscar_cpf_completo() {
    banner
    echo -e "${AZUL}╔═══════════════════════════════════════════════╗${RESET}"
    echo -e "${AZUL}║${RESET}   ${VERDE}🆔 CPF COMPLETO (Selenium + situacao-cadastral)${RESET} ${AZUL}║${RESET}"
    echo -e "${AZUL}╚═══════════════════════════════════════════════╝${RESET}"
    echo ""
    echo -e "${AMARELO}⚠️  Requer Python + Selenium + Chrome instalados${RESET}"
    echo -e "${AMARELO}   Consulta via site situacao-cadastral.com${RESET}"
    echo ""
    echo -ne "${AMARELO}CPF (11 dígitos): ${RESET}"
    read cpf
    cpf=$(echo "$cpf" | tr -d ' .-')
    if [[ ${#cpf} -ne 11 ]]; then
        echo -e "${VERMELHO}CPF inválido${RESET}"; sleep 2; menu; return
    fi
    SCR_DIR="$(dirname "$0")"
    PY_SCRIPT="$SCR_DIR/cpf_consulta.py"
    if [[ ! -f "$PY_SCRIPT" ]]; then
        PY_SCRIPT="/sdcard/cybertrace/cpf_consulta.py"
    fi
    if [[ -f "$PY_SCRIPT" ]]; then
        echo -e "${CIANO}Consultando CPF $cpf...${RESET}"
        python3 "$PY_SCRIPT" "$cpf"
    else
        echo -e "${VERMELHO}Script Python não encontrado!${RESET}"
        echo -e "${AMARELO}Baixe: https://github.com/fernandobortotti/CPF-Tools${RESET}"
        echo -e "${AMARELO}Ou rode manualmente: python3 cpf_consulta.py $cpf${RESET}"
    fi
    echo ""; read -p "ENTER p/ voltar"; menu
}

ferramentas_extras() {
    banner
    echo -e "${AZUL}╔═══════════════════════════════════════════════╗${RESET}"
    echo -e "${AZUL}║${RESET}   ${VERDE}🛠️  FERRAMENTAS EXTRAS${RESET}                   ${AZUL}║${RESET}"
    echo -e "${AZUL}╚═══════════════════════════════════════════════╝${RESET}"
    echo ""
    echo -e "${CIANO}╔═══════════════════════════════════════════════╗${RESET}"
    echo -e "${CIANO}║${RESET}   ${AMARELO}1.${RESET} 📊 Info do sistema               ${CIANO}║${RESET}"
    echo -e "${CIANO}║${RESET}   ${AMARELO}2.${RESET} 🧹 Limpar histórico              ${CIANO}║${RESET}"
    echo -e "${CIANO}║${RESET}   ${AMARELO}3.${RESET} 📡 Speedtest (ping)              ${CIANO}║${RESET}"
    echo -e "${CIANO}║${RESET}   ${AMARELO}4.${RESET} 💡 QR Code                       ${CIANO}║${RESET}"
    echo -e "${CIANO}║${RESET}   ${AMARELO}5.${RESET} 🌙 Matrix Rain                   ${CIANO}║${RESET}"
    echo -e "${CIANO}║${RESET}   ${AMARELO}6.${RESET} 🔗 Encurtar URL                  ${CIANO}║${RESET}"
    echo -e "${CIANO}║${RESET}   ${AMARELO}7.${RESET} 🕵️ Verificar vazamento email    ${CIANO}║${RESET}"
    echo -e "${CIANO}║${RESET}   ${AMARELO}0.${RESET} 🔙 Voltar                       ${CIANO}║${RESET}"
    echo -e "${CIANO}╚═══════════════════════════════════════════════╝${RESET}"
    echo ""
    echo -ne "${VERDE}➜ Escolha: ${RESET}"
    read sub
    case $sub in
        1)
            echo -e "${CIANO}📊 SISTEMA${RESET}"
            echo -e "${AMARELO}Modelo:${RESET} $(getprop ro.product.model 2>/dev/null || echo N/A)"
            echo -e "${AMARELO}Bateria:${RESET} $(termux-battery-status 2>/dev/null | python3 -c "import sys,json; d=json.load(sys.stdin); print(f\"{d['percentage']}%\")" 2>/dev/null || echo N/A)"
            echo -e "${AMARELO}IP público:${RESET} $(curl -s ifconfig.me 2>/dev/null || echo N/A)"
            read -p "ENTER..." ;;
        2) history -c; echo -e "${VERDE}✅ Limpo${RESET}"; sleep 2 ;;
        3)
            echo -ne "${AMARELO}Alvo (IP/URL): ${RESET}"
            read alvo
            ping -c 4 "$alvo" 2>&1 | tail -3 ;;
        4)
            echo -ne "${AMARELO}Texto: ${RESET}"; read qt
            command -v qrencode &>/dev/null && qrencode -t ANSI "$qt" || echo -e "${VERMELHO}pkg install qrencode${RESET}"
            read -p "ENTER..." ;;
        5) clear; echo -e "${VERDE}"
            for i in {1..30}; do
                for j in {1..50}; do echo -ne "$((RANDOM % 2))"; done; echo; sleep 0.03
            done; echo -e "${RESET}"; sleep 1 ;;
        6)
            echo -ne "${AMARELO}URL: ${RESET}"; read url
            short=$(curl -s "https://tinyurl.com/api-create.php?url=$url" 2>/dev/null)
            echo -e "${VERDE}➜ $short${RESET}"
            read -p "ENTER..." ;;
        7)
            echo -ne "${AMARELO}E-mail: ${RESET}"; read em
            echo -e "${CIANO}Consulte: https://haveibeenpwned.com/account/$em${RESET}"
            termux-open-url "https://haveibeenpwned.com/account/$em" 2>/dev/null
            read -p "ENTER..." ;;
        0) menu; return ;;
        *) echo -e "${VERMELHO}Inválido${RESET}"; sleep 2 ;;
    esac
    ferramentas_extras
}

# Início
echo -e "${CIANO}🔧 Verificando dependências...${RESET}"
for cmd in curl dig python3; do
    command -v $cmd &>/dev/null || pkg install -y $cmd 2>/dev/null
done
menu

_ANYCLAW_SHIZK_XT482529__0
_UUEI_59427101