#!/bin/bash

# =============================================
# CYBERTRACE v2.1 - Painel de Investigação
# Consultas com APIs públicas reais
# =============================================
# INSTALAÇÃO NO TERMUX:
#   pkg update && pkg upgrade -y
#   pkg install -y curl python3 git
#   git clone https://github.com/ClubeDoTermux/cybertrace-panel.git
#   cd cybertrace-panel
#   bash cybertrace.sh
#
# INSTALAÇÃO NO LINUX (Debian/Ubuntu):
#   sudo apt update && sudo apt install -y curl python3 git dnsutils
#   git clone https://github.com/ClubeDoTermux/cybertrace-panel.git
#   cd cybertrace-panel
#   bash cybertrace.sh
#
# DEPENDÊNCIAS:
#   curl       → consultas HTTP (IP, CNPJ, CEP, Placa, etc)
#   python3    → processamento JSON e validações
#   dig        → consultas DNS e WHOIS (dnsutils)
#   git        → clonar o repositório (instalação)
#   qrencode   → gerar QR Code (opcional)
# =============================================

VERDE='\033[1;32m'
VERMELHO='\033[1;31m'
AZUL='\033[1;34m'
AMARELO='\033[1;33m'
CIANO='\033[1;36m'
ROXO='\033[1;35m'
RESET='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# =============================================
# FUNÇÕES AUXILIARES
# =============================================
is_termux() {
    command -v termux-open-url &>/dev/null
}

url_encode() {
    python3 -c "import urllib.parse, sys; print(urllib.parse.quote(sys.argv[1]))" "$1" 2>/dev/null
}

api_get() {
    curl -s --max-time 10 "$1" 2>/dev/null
}

press_enter() {
    echo ""
    read -p "Pressione ENTER para voltar..."
}

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
    echo -e "║   ${AMARELO}🔍 PAINEL DE INVESTIGAÇÃO DIGITAL v2.1${VERMELHO}   ║"
    echo -e "║   ${CIANO}🌐 github.com/ClubeDoTermux/cybertrace-panel${VERMELHO}  ║"
    echo "╚═══════════════════════════════════════════════╝"
    echo -e "${RESET}"
}

section() {
    echo -e "${AZUL}╔═══════════════════════════════════════════════╗${RESET}"
    echo -e "${AZUL}║${RESET}   ${VERDE}$1${RESET}"
    echo -e "${AZUL}╚═══════════════════════════════════════════════╝${RESET}"
    echo ""
}

loader() {
    local pid=$1
    local spin='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    local i=0
    while kill -0 "$pid" 2>/dev/null; do
        printf "\r${CIANO}%s${RESET} Aguardando..." "${spin:$i:1}"
        i=$(( (i+1) % ${#spin} ))
        sleep 0.1
    done
    printf "\r${VERDE}✓${RESET} Pronto!          \n"
}

# =============================================
# HELP / USO VIA TERMINAL
# =============================================
show_help() {
    echo -e "${CIANO}CYBERTRACE v2.1 - Painel de Investigação Digital${RESET}"
    echo -e "${AMARELO}Uso:${RESET} bash cybertrace.sh [opção] [valor]"
    echo ""
    echo -e "${VERDE}Opções:${RESET}"
    echo -e "  ${AMARELO}sem argumentos${RESET}   → Menu interativo"
    echo -e "  ${AMARELO}--help, -h${RESET}       → Mostra esta ajuda"
    echo -e "  ${AMARELO}--ip <IP>${RESET}        → Geolocalização + proxy/VPN"
    echo -e "  ${AMARELO}--cnpj <CNPJ>${RESET}    → Consulta CNPJ (BrasilAPI)"
    echo -e "  ${AMARELO}--cep <CEP>${RESET}      → Consulta CEP (ViaCEP)"
    echo -e "  ${AMARELO}--cpf <CPF>${RESET}      → Valida CPF + UF de origem"
    echo -e "  ${AMARELO}--placa <PLACA>${RESET}   → Consulta veículo (FIPE)"
    echo -e "  ${AMARELO}--dominio <DOM>${RESET}   → DNS + WHOIS"
    echo -e "  ${AMARELO}--email <EMAIL>${RESET}   → MX, Gravatar, HIBP"
    echo -e "  ${AMARELO}--telefone <NUM>${RESET}  → DDD, operadora, região"
    echo -e "  ${AMARELO}--redes <USER>${RESET}    → Busca username em redes"
    echo -e "  ${AMARELO}--tempo <CIDADE>${RESET}  → Previsão do tempo"
    echo ""
    echo -e "${VERDE}Instalação Termux:${RESET}"
    echo "  pkg install -y curl python3 git"
    echo "  git clone https://github.com/ClubeDoTermux/cybertrace-panel.git"
    echo "  cd cybertrace-panel && bash cybertrace.sh"
    echo ""
    echo -e "${VERDE}Instalação Linux:${RESET}"
    echo "  sudo apt install -y curl python3 git dnsutils"
    echo "  git clone https://github.com/ClubeDoTermux/cybertrace-panel.git"
    echo "  cd cybertrace-panel && bash cybertrace.sh"
    exit 0
}

# =============================================
# FUNÇÕES DE CONSULTA
# =============================================

# 1 - Buscar IP
buscar_ip() {
    banner
    section "📍 GEOLOCALIZAÇÃO POR IP"
    echo -ne "${AMARELO}IP (ex: 8.8.8.8) ou Enter p/ seu IP: ${RESET}"
    read ip
    if [[ -z "$ip" ]]; then
        ip=$(api_get "ifconfig.me")
        echo -e "${CIANO}➜ Seu IP: $ip${RESET}"
    fi
    echo -e "${CIANO}Consultando...${RESET}"
    data=$(api_get "http://ip-api.com/json/${ip}?fields=status,country,countryCode,region,city,zip,lat,lon,isp,org,as,timezone,query,mobile,proxy,hosting")
    status=$(echo "$data" | python3 -c "import sys,json; print(json.load(sys.stdin).get('status',''))" 2>/dev/null)
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
proxy = d.get('proxy','')
hosting = d.get('hosting','')
mobile = d.get('mobile','')
if proxy: print(f'${VERMELHO}🛡️ Proxy/VPN:${RESET} SIM')
if mobile: print(f'${AMARELO}📱 Rede móvel:${RESET} SIM')
if hosting: print(f'${AMARELO}☁️  Hosting/Datacenter:${RESET} SIM')
print(f'${AMARELO}🗺️ Mapa:${RESET} https://www.google.com/maps?q={d.get(\"lat\",\"\")},{d.get(\"lon\",\"\")}')
        " 2>/dev/null
    else
        echo -e "${VERMELHO}IP inválido ou não encontrado${RESET}"
    fi
    press_enter
    menu
}

# 2 - Telefone
buscar_telefone() {
    banner
    section "📱 CONSULTAR TELEFONE"
    echo -e "${AMARELO}📌 Formato: 55 11 999999999 (país DDD número)${RESET}"
    echo -ne "${AMARELO}Número: ${RESET}"
    read tel
    tel=$(echo "$tel" | tr -d ' +-')
    if [[ ${#tel} -lt 12 ]]; then
        echo -e "${VERMELHO}Número muito curto (use código do país + DDD)${RESET}"
        sleep 2
        menu
        return
    fi
    echo -e "${CIANO}Analisando número...${RESET}"
    pais="${tel:0:2}"
    ddd="${tel:2:2}"
    numero="${tel:4}"
    echo -e "${VERDE}════════════════════════════════════════════${RESET}"
    echo -e "${AMARELO}📞 Número completo:${RESET} +$tel"
    echo -e "${AMARELO}🌍 País:${RESET} $( [[ "$pais" == "55" ]] && echo "Brasil" || echo "$pais")"
    echo -e "${AMARELO}📌 DDD:${RESET} $ddd"
    echo -e "${AMARELO}📱 Número:${RESET} $numero"
    echo -e "${AMARELO}🔢 Tipo:${RESET} $( [[ ${#numero} -eq 9 ]] && echo "Celular" || echo "Fixo")"
    echo -e "${VERDE}════════════════════════════════════════════${RESET}"
    echo ""
    echo -e "${CIANO}📋 DADOS DO DDD:${RESET}"
    case $ddd in
        11) echo -e "${AMARELO}📍 Estado:${RESET} SP - São Paulo"
            echo -e "${AMARELO}📡 Operadoras:${RESET} Vivo, TIM, Claro, Oi" ;;
        12) echo -e "${AMARELO}📍 Estado:${RESET} SP - São José dos Campos"
            echo -e "${AMARELO}📡 Operadoras:${RESET} Vivo, TIM, Claro" ;;
        13) echo -e "${AMARELO}📍 Estado:${RESET} SP - Santos"
            echo -e "${AMARELO}📡 Operadoras:${RESET} Vivo, TIM, Claro" ;;
        14) echo -e "${AMARELO}📍 Estado:${RESET} SP - Bauru"
            echo -e "${AMARELO}📡 Operadoras:${RESET} Vivo, TIM, Claro" ;;
        15) echo -e "${AMARELO}📍 Estado:${RESET} SP - Sorocaba"
            echo -e "${AMARELO}📡 Operadoras:${RESET} Vivo, TIM, Claro" ;;
        16) echo -e "${AMARELO}📍 Estado:${RESET} SP - Ribeirão Preto"
            echo -e "${AMARELO}📡 Operadoras:${RESET} Vivo, TIM, Claro" ;;
        17) echo -e "${AMARELO}📍 Estado:${RESET} SP - São José do Rio Preto"
            echo -e "${AMARELO}📡 Operadoras:${RESET} Vivo, TIM, Claro" ;;
        18) echo -e "${AMARELO}📍 Estado:${RESET} SP - Presidente Prudente"
            echo -e "${AMARELO}📡 Operadoras:${RESET} Vivo, TIM, Claro" ;;
        19) echo -e "${AMARELO}📍 Estado:${RESET} SP - Campinas"
            echo -e "${AMARELO}📡 Operadoras:${RESET} Vivo, TIM, Claro" ;;
        21) echo -e "${AMARELO}📍 Estado:${RESET} RJ - Rio de Janeiro"
            echo -e "${AMARELO}📡 Operadoras:${RESET} Vivo, TIM, Claro, Oi" ;;
        22) echo -e "${AMARELO}📍 Estado:${RESET} RJ - Campos"
            echo -e "${AMARELO}📡 Operadoras:${RESET} Vivo, TIM, Claro" ;;
        24) echo -e "${AMARELO}📍 Estado:${RESET} RJ - Volta Redonda"
            echo -e "${AMARELO}📡 Operadoras:${RESET} Vivo, TIM, Claro" ;;
        27) echo -e "${AMARELO}📍 Estado:${RESET} ES - Vitória"
            echo -e "${AMARELO}📡 Operadoras:${RESET} Vivo, TIM, Claro, Oi" ;;
        28) echo -e "${AMARELO}📍 Estado:${RESET} ES - Cachoeiro"
            echo -e "${AMARELO}📡 Operadoras:${RESET} Vivo, TIM, Claro" ;;
        31) echo -e "${AMARELO}📍 Estado:${RESET} MG - Belo Horizonte"
            echo -e "${AMARELO}📡 Operadoras:${RESET} Vivo, TIM, Claro, Oi" ;;
        32) echo -e "${AMARELO}📍 Estado:${RESET} MG - Juiz de Fora"
            echo -e "${AMARELO}📡 Operadoras:${RESET} Vivo, TIM, Claro" ;;
        33) echo -e "${AMARELO}📍 Estado:${RESET} MG - Governador Valadares"
            echo -e "${AMARELO}📡 Operadoras:${RESET} Vivo, TIM, Claro" ;;
        34) echo -e "${AMARELO}📍 Estado:${RESET} MG - Uberlândia"
            echo -e "${AMARELO}📡 Operadoras:${RESET} Vivo, TIM, Claro" ;;
        35) echo -e "${AMARELO}📍 Estado:${RESET} MG - Poços de Caldas"
            echo -e "${AMARELO}📡 Operadoras:${RESET} Vivo, TIM, Claro" ;;
        37) echo -e "${AMARELO}📍 Estado:${RESET} MG - Divinópolis"
            echo -e "${AMARELO}📡 Operadoras:${RESET} Vivo, TIM, Claro" ;;
        38) echo -e "${AMARELO}📍 Estado:${RESET} MG - Montes Claros"
            echo -e "${AMARELO}📡 Operadoras:${RESET} Vivo, TIM, Claro" ;;
        41) echo -e "${AMARELO}📍 Estado:${RESET} PR - Curitiba"
            echo -e "${AMARELO}📡 Operadoras:${RESET} Vivo, TIM, Claro, Oi" ;;
        42) echo -e "${AMARELO}📍 Estado:${RESET} PR - Ponta Grossa"
            echo -e "${AMARELO}📡 Operadoras:${RESET} Vivo, TIM, Claro" ;;
        43) echo -e "${AMARELO}📍 Estado:${RESET} PR - Londrina"
            echo -e "${AMARELO}📡 Operadoras:${RESET} Vivo, TIM, Claro" ;;
        44) echo -e "${AMARELO}📍 Estado:${RESET} PR - Maringá"
            echo -e "${AMARELO}📡 Operadoras:${RESET} Vivo, TIM, Claro" ;;
        45) echo -e "${AMARELO}📍 Estado:${RESET} PR - Foz do Iguaçu"
            echo -e "${AMARELO}📡 Operadoras:${RESET} Vivo, TIM, Claro" ;;
        46) echo -e "${AMARELO}📍 Estado:${RESET} PR - Francisco Beltrão"
            echo -e "${AMARELO}📡 Operadoras:${RESET} Vivo, TIM, Claro" ;;
        47) echo -e "${AMARELO}📍 Estado:${RESET} SC - Joinville"
            echo -e "${AMARELO}📡 Operadoras:${RESET} Vivo, TIM, Claro, Oi" ;;
        48) echo -e "${AMARELO}📍 Estado:${RESET} SC - Florianópolis"
            echo -e "${AMARELO}📡 Operadoras:${RESET} Vivo, TIM, Claro" ;;
        49) echo -e "${AMARELO}📍 Estado:${RESET} SC - Chapecó"
            echo -e "${AMARELO}📡 Operadoras:${RESET} Vivo, TIM, Claro" ;;
        51) echo -e "${AMARELO}📍 Estado:${RESET} RS - Porto Alegre"
            echo -e "${AMARELO}📡 Operadoras:${RESET} Vivo, TIM, Claro, Oi" ;;
        53) echo -e "${AMARELO}📍 Estado:${RESET} RS - Pelotas"
            echo -e "${AMARELO}📡 Operadoras:${RESET} Vivo, TIM, Claro" ;;
        54) echo -e "${AMARELO}📍 Estado:${RESET} RS - Caxias do Sul"
            echo -e "${AMARELO}📡 Operadoras:${RESET} Vivo, TIM, Claro" ;;
        55) echo -e "${AMARELO}📍 Estado:${RESET} RS - Santa Maria"
            echo -e "${AMARELO}📡 Operadoras:${RESET} Vivo, TIM, Claro" ;;
        61) echo -e "${AMARELO}📍 Estado:${RESET} DF - Brasília"
            echo -e "${AMARELO}📡 Operadoras:${RESET} Vivo, TIM, Claro, Oi" ;;
        62) echo -e "${AMARELO}📍 Estado:${RESET} GO - Goiânia"
            echo -e "${AMARELO}📡 Operadoras:${RESET} Vivo, TIM, Claro" ;;
        63) echo -e "${AMARELO}📍 Estado:${RESET} TO - Palmas"
            echo -e "${AMARELO}📡 Operadoras:${RESET} Vivo, TIM, Claro" ;;
        64) echo -e "${AMARELO}📍 Estado:${RESET} GO - Rio Verde"
            echo -e "${AMARELO}📡 Operadoras:${RESET} Vivo, TIM, Claro" ;;
        65) echo -e "${AMARELO}📍 Estado:${RESET} MT - Cuiabá"
            echo -e "${AMARELO}📡 Operadoras:${RESET} Vivo, TIM, Claro" ;;
        66) echo -e "${AMARELO}📍 Estado:${RESET} MT - Rondonópolis"
            echo -e "${AMARELO}📡 Operadoras:${RESET} Vivo, TIM, Claro" ;;
        67) echo -e "${AMARELO}📍 Estado:${RESET} MS - Campo Grande"
            echo -e "${AMARELO}📡 Operadoras:${RESET} Vivo, TIM, Claro" ;;
        68) echo -e "${AMARELO}📍 Estado:${RESET} AC - Rio Branco"
            echo -e "${AMARELO}📡 Operadoras:${RESET} Vivo, TIM, Claro" ;;
        69) echo -e "${AMARELO}📍 Estado:${RESET} RO - Porto Velho"
            echo -e "${AMARELO}📡 Operadoras:${RESET} Vivo, TIM, Claro" ;;
        71) echo -e "${AMARELO}📍 Estado:${RESET} BA - Salvador"
            echo -e "${AMARELO}📡 Operadoras:${RESET} Vivo, TIM, Claro, Oi" ;;
        73) echo -e "${AMARELO}📍 Estado:${RESET} BA - Ilhéus"
            echo -e "${AMARELO}📡 Operadoras:${RESET} Vivo, TIM, Claro" ;;
        74) echo -e "${AMARELO}📍 Estado:${RESET} BA - Juazeiro"
            echo -e "${AMARELO}📡 Operadoras:${RESET} Vivo, TIM, Claro" ;;
        75) echo -e "${AMARELO}📍 Estado:${RESET} BA - Feira de Santana"
            echo -e "${AMARELO}📡 Operadoras:${RESET} Vivo, TIM, Claro" ;;
        77) echo -e "${AMARELO}📍 Estado:${RESET} BA - Barreiras"
            echo -e "${AMARELO}📡 Operadoras:${RESET} Vivo, TIM, Claro" ;;
        79) echo -e "${AMARELO}📍 Estado:${RESET} SE - Aracaju"
            echo -e "${AMARELO}📡 Operadoras:${RESET} Vivo, TIM, Claro" ;;
        81) echo -e "${AMARELO}📍 Estado:${RESET} PE - Recife"
            echo -e "${AMARELO}📡 Operadoras:${RESET} Vivo, TIM, Claro, Oi" ;;
        82) echo -e "${AMARELO}📍 Estado:${RESET} AL - Maceió"
            echo -e "${AMARELO}📡 Operadoras:${RESET} Vivo, TIM, Claro" ;;
        83) echo -e "${AMARELO}📍 Estado:${RESET} PB - João Pessoa"
            echo -e "${AMARELO}📡 Operadoras:${RESET} Vivo, TIM, Claro" ;;
        84) echo -e "${AMARELO}📍 Estado:${RESET} RN - Natal"
            echo -e "${AMARELO}📡 Operadoras:${RESET} Vivo, TIM, Claro" ;;
        85) echo -e "${AMARELO}📍 Estado:${RESET} CE - Fortaleza"
            echo -e "${AMARELO}📡 Operadoras:${RESET} Vivo, TIM, Claro, Oi" ;;
        86) echo -e "${AMARELO}📍 Estado:${RESET} PI - Teresina"
            echo -e "${AMARELO}📡 Operadoras:${RESET} Vivo, TIM, Claro" ;;
        87) echo -e "${AMARELO}📍 Estado:${RESET} PE - Petrolina"
            echo -e "${AMARELO}📡 Operadoras:${RESET} Vivo, TIM, Claro" ;;
        88) echo -e "${AMARELO}📍 Estado:${RESET} CE - Juazeiro do Norte"
            echo -e "${AMARELO}📡 Operadoras:${RESET} Vivo, TIM, Claro" ;;
        89) echo -e "${AMARELO}📍 Estado:${RESET} PI - Parnaíba"
            echo -e "${AMARELO}📡 Operadoras:${RESET} Vivo, TIM, Claro" ;;
        91) echo -e "${AMARELO}📍 Estado:${RESET} PA - Belém"
            echo -e "${AMARELO}📡 Operadoras:${RESET} Vivo, TIM, Claro, Oi" ;;
        92) echo -e "${AMARELO}📍 Estado:${RESET} AM - Manaus"
            echo -e "${AMARELO}📡 Operadoras:${RESET} Vivo, TIM, Claro" ;;
        93) echo -e "${AMARELO}📍 Estado:${RESET} PA - Santarém"
            echo -e "${AMARELO}📡 Operadoras:${RESET} Vivo, TIM, Claro" ;;
        94) echo -e "${AMARELO}📍 Estado:${RESET} PA - Marabá"
            echo -e "${AMARELO}📡 Operadoras:${RESET} Vivo, TIM, Claro" ;;
        95) echo -e "${AMARELO}📍 Estado:${RESET} RR - Boa Vista"
            echo -e "${AMARELO}📡 Operadoras:${RESET} Vivo, TIM, Claro" ;;
        96) echo -e "${AMARELO}📍 Estado:${RESET} AP - Macapá"
            echo -e "${AMARELO}📡 Operadoras:${RESET} Vivo, TIM, Claro" ;;
        97) echo -e "${AMARELO}📍 Estado:${RESET} AM - Coari"
            echo -e "${AMARELO}📡 Operadoras:${RESET} Vivo, TIM, Claro" ;;
        98) echo -e "${AMARELO}📍 Estado:${RESET} MA - São Luís"
            echo -e "${AMARELO}📡 Operadoras:${RESET} Vivo, TIM, Claro, Oi" ;;
        99) echo -e "${AMARELO}📍 Estado:${RESET} MA - Imperatriz"
            echo -e "${AMARELO}📡 Operadoras:${RESET} Vivo, TIM, Claro" ;;
        *) echo -e "${AMARELO}📍 DDD não mapeado${RESET}"
           echo -e "${CIANO}💡 Consulte: https://www.codigosddd.com.br/${RESET}" ;;
    esac
    echo -e "${VERDE}════════════════════════════════════════════${RESET}"
    press_enter
    menu
}

# 3 - Placa
buscar_placa() {
    banner
    section "🚗 CONSULTAR PLACA"
    echo -ne "${AMARELO}Placa (ABC1234 ou ABC1D23 Mercosul): ${RESET}"
    read placa
    placa=$(echo "$placa" | tr 'a-z' 'A-Z' | tr -d ' ')
    if [[ ${#placa} -lt 7 ]]; then
        echo -e "${VERMELHO}Placa inválida${RESET}"
        sleep 2
        menu
        return
    fi
    echo -e "${CIANO}Consultando API BrasilAPI/FIPE...${RESET}"
    result=$(api_get "https://brasilapi.com.br/api/fipe/preco/v1/$(echo "$placa" | sed 's/[^A-Z0-9]//g')")
    if echo "$result" | python3 -c "import sys,json; d=json.load(sys.stdin); exit(0 if isinstance(d,list) and len(d)>0 else 1)" 2>/dev/null; then
        echo "$result" | python3 -c "
import sys,json
d=json.load(sys.stdin)
if isinstance(d,list): d=d[0]
print('${VERDE}════════════════════════════════════════════${RESET}')
print(f'${AMARELO}🔢 Placa:${RESET} $placa')
for k,v in d.items():
    print(f'${AMARELO}• {k}:${RESET} {v}')
        " 2>/dev/null
    else
        echo -e "${AMARELO}⚠️ API FIPE sem dados para esta placa${RESET}"
        echo -e "${VERDE}════════════════════════════════════════════${RESET}"
        echo -e "${AMARELO}🔢 Placa:${RESET} $placa"
        echo -e "${AMARELO}📌 Formato:${RESET} $( [[ ${#placa} -eq 7 ]] && echo "Padrão antigo" || echo "Mercosul")"
        echo -e "${CIANO}💡 Consulte o site do Detran do seu estado${RESET}"
    fi
    press_enter
    menu
}

# 4 - CNPJ
buscar_cnpj() {
    banner
    section "🆔 CNPJ REAL (BrasilAPI - Receita Federal)"
    echo -ne "${AMARELO}CNPJ (apenas números): ${RESET}"
    read cnpj
    cnpj=$(echo "$cnpj" | tr -d ' ./-')
    if [[ ${#cnpj} -ne 14 ]]; then
        echo -e "${VERMELHO}CNPJ deve ter 14 dígitos${RESET}"
        sleep 2
        menu
        return
    fi
    echo -e "${CIANO}Consultando Receita Federal via BrasilAPI...${RESET}"
    result=$(api_get "https://brasilapi.com.br/api/cnpj/v1/$cnpj")
    if echo "$result" | python3 -c "import sys,json; d=json.load(sys.stdin); exit(0 if 'cnpj' in d else 1)" 2>/dev/null; then
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
if d.get(\"cnpj_raiz\"): print(f'${AMARELO}📎 Matriz:${RESET} {d.get(\"cnpj_raiz\",\"\")}')
print('${VERDE}════════════════════════════════════════════${RESET}')
        " 2>/dev/null
    else
        echo -e "${VERMELHO}CNPJ não encontrado ou inválido${RESET}"
    fi
    press_enter
    menu
}

# 5 - Validar CPF
validar_cpf() {
    banner
    section "📇 VALIDAÇÃO DE CPF"
    echo -e "${VERMELHO}⚠️ Dados reais de CPF são protegidos por lei${RESET}"
    echo -e "${AMARELO}   Só é possível validar os dígitos (verificar se é válido)${RESET}"
    echo ""
    echo -ne "${AMARELO}CPF (11 dígitos): ${RESET}"
    read cpf
    cpf=$(echo "$cpf" | tr -d ' .-')
    if [[ ${#cpf} -ne 11 ]]; then
        echo -e "${VERMELHO}CPF inválido${RESET}"
        sleep 2
        menu
        return
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
    print(f'${AMARELO}🔢 Dígitos verificadores:${RESET} OK')
print(f'${VERDE}════════════════════════════════════════════${RESET}')
    " 2>/dev/null
    press_enter
    menu
}

# 6 - Domínio
buscar_dominio() {
    banner
    section "🌐 CONSULTAR DOMÍNIO (DNS + WHOIS)"
    echo -ne "${AMARELO}Domínio (ex: google.com): ${RESET}"
    read dominio
    [[ -z "$dominio" ]] && { echo -e "${VERMELHO}Inválido${RESET}"; sleep 2; menu; return; }
    echo -e "${CIANO}Consultando registros DNS...${RESET}"
    ip=$(dig +short "$dominio" 2>/dev/null | head -1)
    if [[ -n "$ip" ]]; then
        echo -e "${VERDE}════════════════════════════════════════════${RESET}"
        echo -e "${AMARELO}🌐 Domínio:${RESET} $dominio"
        echo -e "${AMARELO}📡 IP:${RESET} $ip"
        echo ""
        echo -e "${CIANO}📋 Registros DNS:${RESET}"
        echo -e "${AMARELO}📬 MX:${RESET}"
        dig +short MX "$dominio" 2>/dev/null | while read line; do echo "   $line"; done
        echo -e "${AMARELO}📝 NS:${RESET}"
        dig +short NS "$dominio" 2>/dev/null | while read line; do echo "   $line"; done
        echo -e "${AMARELO}📧 TXT:${RESET}"
        dig +short TXT "$dominio" 2>/dev/null | head -5 | while read line; do echo "   $line"; done
        echo ""
        if command -v whois &>/dev/null; then
            echo -e "${CIANO}📋 WHOIS (primeiras linhas):${RESET}"
            whois "$dominio" 2>/dev/null | grep -iE "registrant|owner|email|country|created|expir|name|organization|status" | head -10 | while read line; do
                echo -e "${AMARELO}   ${RESET}$line"
            done
        fi
        echo ""
        echo -e "${AMARELO}🔗 Registro.br:${RESET} https://www.registro.br/cgi-bin/whois/?qr=$dominio"
    else
        echo -e "${VERMELHO}Domínio não encontrado ou sem DNS resolvido${RESET}"
    fi
    press_enter
    menu
}

# 7 - Buscar Nome (Google Dorking)
buscar_nome() {
    banner
    section "🔍 BUSCAR NOME (Google Dorking)"
    echo -ne "${AMARELO}Nome completo: ${RESET}"
    read nome
    [[ -z "$nome" ]] && { echo -e "${VERMELHO}Inválido${RESET}"; sleep 2; menu; return; }
    nome_encoded=$(url_encode "$nome")
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
        if is_termux; then
            termux-open-url "https://www.google.com/search?q=$nome_encoded" 2>/dev/null
        elif command -v xdg-open &>/dev/null; then
            xdg-open "https://www.google.com/search?q=$nome_encoded" 2>/dev/null
        else
            echo -e "${AMARELO}Abra manualmente: https://www.google.com/search?q=$nome_encoded${RESET}"
        fi
    fi
    press_enter
    menu
}

# 8 - Redes Sociais
redes_sociais() {
    banner
    section "👤 BUSCAR USERNAME EM REDES SOCIAIS"
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
        "Snapchat:https://www.snapchat.com/add/$user"
        "SoundCloud:https://soundcloud.com/$user"
        "Behance:https://www.behance.net/$user"
        "Dribbble:https://dribbble.com/$user"
        "Vimeo:https://vimeo.com/$user"
        "Flickr:https://www.flickr.com/people/$user"
        "Tumblr:https://$user.tumblr.com"
        "WordPress:https://$user.wordpress.com"
        "Blogger:https://$user.blogspot.com"
        "Telegram:https://t.me/$user"
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
    press_enter
    menu
}

# 9 - E-mail
consultar_email() {
    banner
    section "📧 CONSULTAR E-MAIL"
    echo -ne "${AMARELO}E-mail: ${RESET}"
    read email
    [[ -z "$email" ]] && { echo -e "${VERMELHO}Inválido${RESET}"; sleep 2; menu; return; }
    dominio=$(echo "$email" | cut -d'@' -f2)
    usuario=$(echo "$email" | cut -d'@' -f1)
    echo -e "${VERDE}════════════════════════════════════════════${RESET}"
    echo -e "${AMARELO}📧 E-mail:${RESET} $email"
    echo -e "${AMARELO}🌐 Domínio:${RESET} $dominio"
    ip=$(dig +short "$dominio" 2>/dev/null | head -1)
    echo -e "${AMARELO}📡 IP do servidor:${RESET} ${ip:-Não resolvido}"
    echo -e "${AMARELO}📬 Servidores MX:${RESET}"
    dig +short MX "$dominio" 2>/dev/null | while read line; do echo "   $line"; done
    echo -e "${AMARELO}📝 Servidores NS:${RESET}"
    dig +short NS "$dominio" 2>/dev/null | while read line; do echo "   $line"; done
    echo ""
    echo -e "${CIANO}🔗 Links úteis:${RESET}"
    hash=$(echo -n "$email" | md5sum 2>/dev/null | cut -d' ' -f1)
    echo -e "${AMARELO}   🔍 Gravatar:${RESET} https://www.gravatar.com/avatar/$hash"
    echo -e "${AMARELO}   🔍 HIBP (vazamentos):${RESET} https://haveibeenpwned.com/account/$email"
    echo -e "${AMARELO}   🔍 Google:${RESET} https://www.google.com/search?q=$(url_encode "$email")"
    echo -e "${AMARELO}   🔍 Hunter.io:${RESET} https://hunter.io/search/$dominio"
    echo -e "${VERDE}════════════════════════════════════════════${RESET}"
    press_enter
    menu
}

# 10 - CEP
buscar_cep() {
    banner
    section "📮 CONSULTAR CEP (ViaCEP API)"
    echo -ne "${AMARELO}CEP (apenas números): ${RESET}"
    read cep
    cep=$(echo "$cep" | tr -d ' -')
    if [[ ${#cep} -ne 8 ]]; then
        echo -e "${VERMELHO}CEP deve ter 8 dígitos${RESET}"
        sleep 2
        menu
        return
    fi
    echo -e "${CIANO}Consultando ViaCEP...${RESET}"
    data=$(api_get "https://viacep.com.br/ws/$cep/json/")
    if echo "$data" | python3 -c "import sys,json; d=json.load(sys.stdin); exit(0 if 'erro' not in d else 1)" 2>/dev/null; then
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
if d.get(\"gia\"): print(f'${AMARELO}🏪 GIA:${RESET} {d.get(\"gia\",\"\")}')
print('${VERDE}════════════════════════════════════════════${RESET}')
        " 2>/dev/null
    else
        echo -e "${VERMELHO}CEP não encontrado${RESET}"
    fi
    press_enter
    menu
}

# 11 - CPF Completo (Selenium)
buscar_cpf_completo() {
    banner
    section "🆔 CPF COMPLETO (Selenium + situacao-cadastral)"
    echo -e "${AMARELO}⚠️ Requer Python + Selenium + Chrome instalados${RESET}"
    echo -e "${AMARELO}   pip install selenium webdriver-manager beautifulsoup4${RESET}"
    echo ""
    echo -ne "${AMARELO}CPF (11 dígitos): ${RESET}"
    read cpf
    cpf=$(echo "$cpf" | tr -d ' .-')
    if [[ ${#cpf} -ne 11 ]]; then
        echo -e "${VERMELHO}CPF inválido${RESET}"
        sleep 2
        menu
        return
    fi
    PY_SCRIPT="$SCRIPT_DIR/cpf_consulta.py"
    if [[ -f "$PY_SCRIPT" ]]; then
        echo -e "${CIANO}Consultando CPF $cpf...${RESET}"
        python3 "$PY_SCRIPT" "$cpf"
    else
        echo -e "${VERMELHO}Script Python não encontrado!${RESET}"
        echo -e "${AMARELO}Certifique-se de que cpf_consulta.py está no diretório:${RESET}"
        echo -e "${AMARELO}$PY_SCRIPT${RESET}"
    fi
    press_enter
    menu
}

# =============================================
# FERRAMENTAS EXTRAS
# =============================================

ferramenta_clima() {
    banner
    section "🌦️ PREVISÃO DO TEMPO"
    echo -ne "${AMARELO}Cidade (ex: Sao+Paulo, London): ${RESET}"
    read cidade
    [[ -z "$cidade" ]] && cidade="Sao+Paulo"
    echo -e "${CIANO}Consultando wttr.in...${RESET}"
    curl -s "wttr.in/$cidade?m2&lang=pt" 2>/dev/null | head -40
    echo ""
    echo -e "${CIANO}💡 Fonte: wttr.in${RESET}"
    press_enter
}

ferramenta_senha() {
    banner
    section "🔑 GERADOR DE SENHAS"
    echo -ne "${AMARELO}Tamanho (8-64, padrão 16): ${RESET}"
    read tam
    tam=${tam:-16}
    if ! [[ "$tam" =~ ^[0-9]+$ ]] || [[ $tam -lt 8 ]] || [[ $tam -gt 64 ]]; then
        tam=16
    fi
    echo -ne "${AMARELO}Incluir símbolos? (s/N): ${RESET}"
    read sym
    echo -e "${VERDE}════════════════════════════════════════════${RESET}"
    echo -e "${CIANO}🔑 Senhas geradas:${RESET}"
    for i in 1 2 3; do
        if [[ "$sym" == "s" || "$sym" == "S" ]]; then
            pass=$(python3 -c "import secrets,string; c=string.ascii_letters+string.digits+string.punctuation; print(''.join(secrets.choice(c) for _ in range($tam)))" 2>/dev/null)
        else
            pass=$(python3 -c "import secrets,string; c=string.ascii_letters+string.digits; print(''.join(secrets.choice(c) for _ in range($tam)))" 2>/dev/null)
        fi
        echo -e "${AMARELO}   $i.${RESET} $pass"
    done
    echo -e "${VERDE}════════════════════════════════════════════${RESET}"
    press_enter
}

ferramenta_hash() {
    banner
    section "🔐 GERADOR DE HASH"
    echo -ne "${AMARELO}Texto: ${RESET}"
    read texto
    [[ -z "$texto" ]] && { echo -e "${VERMELHO}Inválido${RESET}"; sleep 2; return; }
    echo -e "${VERDE}════════════════════════════════════════════${RESET}"
    echo -e "${AMARELO}📝 Texto:${RESET} $texto"
    echo -e "${VERDE}────────────────────────────────────────────${RESET}"
    echo -e "${AMARELO}🔹 MD5:${RESET} $(echo -n "$texto" | md5sum 2>/dev/null | cut -d' ' -f1)"
    echo -e "${AMARELO}🔹 SHA1:${RESET} $(echo -n "$texto" | sha1sum 2>/dev/null | cut -d' ' -f1)"
    echo -e "${AMARELO}🔹 SHA256:${RESET} $(echo -n "$texto" | sha256sum 2>/dev/null | cut -d' ' -f1)"
    echo -e "${AMARELO}🔹 SHA512:${RESET} $(echo -n "$texto" | sha512sum 2>/dev/null | cut -d' ' -f1)"
    echo -e "${VERDE}════════════════════════════════════════════${RESET}"
    press_enter
}

ferramenta_base64() {
    banner
    section "🔣 BASE64 ENCODE/DECODE"
    echo -e "${CIANO}╔═══════════════════════════════════════════════╗${RESET}"
    echo -e "${CIANO}║${RESET}   ${AMARELO}1.${RESET} Codificar (encode)           ${CIANO}║${RESET}"
    echo -e "${CIANO}║${RESET}   ${AMARELO}2.${RESET} Decodificar (decode)         ${CIANO}║${RESET}"
    echo -e "${CIANO}║${RESET}   ${AMARELO}0.${RESET} 🔙 Voltar                   ${CIANO}║${RESET}"
    echo -e "${CIANO}╚═══════════════════════════════════════════════╝${RESET}"
    echo ""
    echo -ne "${VERDE}➜ Escolha: ${RESET}"
    read sub
    case $sub in
        1)
            echo -ne "${AMARELO}Texto: ${RESET}"
            read txt
            echo -e "${VERDE}════════════════════════════════════════════${RESET}"
            echo -e "${AMARELO}🔣 Base64:${RESET}"
            echo -n "$txt" | base64 2>/dev/null
            echo -e "${VERDE}════════════════════════════════════════════${RESET}"
            ;;
        2)
            echo -ne "${AMARELO}Base64: ${RESET}"
            read b64
            echo -e "${VERDE}════════════════════════════════════════════${RESET}"
            echo -e "${AMARELO}📝 Decodificado:${RESET}"
            echo "$b64" | base64 -d 2>/dev/null || echo -e "${VERMELHO}Base64 inválido${RESET}"
            echo -e "${VERDE}════════════════════════════════════════════${RESET}"
            ;;
        0) ferramentas_extras; return ;;
        *) echo -e "${VERMELHO}Inválido${RESET}"; sleep 2 ;;
    esac
    press_enter
    ferramenta_base64
}

ferramenta_useragent() {
    banner
    section "🌐 SEU USER-AGENT"
    echo -e "${CIANO}Consultando...${RESET}"
    ua=$(api_get "https://httpbin.org/user-agent")
    if [[ -n "$ua" ]]; then
        echo -e "${VERDE}════════════════════════════════════════════${RESET}"
        echo "$ua" | python3 -c "import sys,json; print(f'${AMARELO}🌍 User-Agent:${RESET} {json.load(sys.stdin).get(\"user-agent\",\"\")}')" 2>/dev/null
        echo -e "${VERDE}════════════════════════════════════════════${RESET}"
    else
        echo -e "${VERMELHO}Não foi possível determinar${RESET}"
    fi
    press_enter
}

ferramenta_info_sistema() {
    echo -e "${CIANO}📊 INFORMAÇÕES DO SISTEMA${RESET}"
    echo -e "${VERDE}────────────────────────────────────────────${RESET}"
    echo -e "${AMARELO}🖥️  OS:${RESET} $(uname -o 2>/dev/null || echo N/A)"
    echo -e "${AMARELO}🐚 Shell:${RESET} $SHELL"
    echo -e "${AMARELO}📦 Pacotes:${RESET} $(command -v dpkg &>/dev/null && dpkg -l 2>/dev/null | wc -l || echo N/A)"
    if is_termux; then
        echo -e "${AMARELO}📱 Dispositivo:${RESET} $(getprop ro.product.model 2>/dev/null || echo N/A)"
        echo -e "${AMARELO}🤖 Android:${RESET} $(getprop ro.build.version.release 2>/dev/null || echo N/A)"
        echo -e "${AMARELO}🔋 Bateria:${RESET} $(termux-battery-status 2>/dev/null | python3 -c "import sys,json; d=json.load(sys.stdin); print(f\"{d['percentage']}%\")" 2>/dev/null || echo N/A)"
    fi
    echo -e "${AMARELO}🌐 IP público:${RESET} $(api_get "ifconfig.me" || echo N/A)"
    echo -e "${AMARELO}⏰ Uptime:${RESET} $(uptime -p 2>/dev/null || echo N/A)"
    echo -e "${VERDE}────────────────────────────────────────────${RESET}"
    press_enter
}

ferramenta_speedtest() {
    echo -ne "${AMARELO}Alvo (IP/URL, padrão google.com): ${RESET}"
    read alvo
    alvo=${alvo:-google.com}
    echo -e "${CIANO}Testando ping para $alvo...${RESET}"
    ping -c 4 "$alvo" 2>&1 | tail -4
    press_enter
}

ferramenta_matriz() {
    clear
    echo -e "${VERDE}"
    for i in {1..30}; do
        for j in {1..50}; do
            echo -ne "$((RANDOM % 2))"
        done
        echo
        sleep 0.03
    done
    echo -e "${RESET}"
    sleep 1
}

ferramentas_extras() {
    banner
    section "🛠️  FERRAMENTAS EXTRAS"
    echo -e "${CIANO}╔═══════════════════════════════════════════════╗${RESET}"
    echo -e "${CIANO}║${RESET}   ${AMARELO}1.${RESET} 📊 Info do sistema               ${CIANO}║${RESET}"
    echo -e "${CIANO}║${RESET}   ${AMARELO}2.${RESET} 🧹 Limpar histórico              ${CIANO}║${RESET}"
    echo -e "${CIANO}║${RESET}   ${AMARELO}3.${RESET} 📡 Ping/Speedtest                ${CIANO}║${RESET}"
    echo -e "${CIANO}║${RESET}   ${AMARELO}4.${RESET} 💡 QR Code                       ${CIANO}║${RESET}"
    echo -e "${CIANO}║${RESET}   ${AMARELO}5.${RESET} 🌙 Matrix Rain                   ${CIANO}║${RESET}"
    echo -e "${CIANO}║${RESET}   ${AMARELO}6.${RESET} 🔗 Encurtar URL                  ${CIANO}║${RESET}"
    echo -e "${CIANO}║${RESET}   ${AMARELO}7.${RESET} 🕵️ Verificar vazamento email    ${CIANO}║${RESET}"
    echo -e "${CIANO}║${RESET}   ${AMARELO}8.${RESET} 🌦️  Previsão do tempo            ${CIANO}║${RESET}"
    echo -e "${CIANO}║${RESET}   ${AMARELO}9.${RESET} 🔑 Gerador de senhas             ${CIANO}║${RESET}"
    echo -e "${CIANO}║${RESET}   ${AMARELO}10.${RESET} 🔐 Gerador de hash              ${CIANO}║${RESET}"
    echo -e "${CIANO}║${RESET}   ${AMARELO}11.${RESET} 🔣 Base64 encode/decode         ${CIANO}║${RESET}"
    echo -e "${CIANO}║${RESET}   ${AMARELO}12.${RESET} 🌐 Meu User-Agent               ${CIANO}║${RESET}"
    echo -e "${CIANO}║${RESET}   ${AMARELO}0.${RESET}  🔙 Voltar                      ${CIANO}║${RESET}"
    echo -e "${CIANO}╚═══════════════════════════════════════════════╝${RESET}"
    echo ""
    echo -ne "${VERDE}➜ Escolha: ${RESET}"
    read sub
    case $sub in
        1) ferramenta_info_sistema ;;
        2)
            history -c 2>/dev/null
            echo -e "${VERDE}✅ Histórico limpo${RESET}"
            sleep 2
            ;;
        3) ferramenta_speedtest ;;
        4)
            echo -ne "${AMARELO}Texto: ${RESET}"
            read qt
            if command -v qrencode &>/dev/null; then
                echo -e "${VERDE}════════════════════════════════════════════${RESET}"
                qrencode -t ANSI "$qt" 2>/dev/null || echo -e "${VERMELHO}Erro ao gerar QR Code (texto muito longo?)${RESET}"
                echo -e "${VERDE}════════════════════════════════════════════${RESET}"
            else
                echo -e "${VERMELHO}Instale qrencode: pkg install qrencode${RESET}"
            fi
            press_enter
            ;;
        5) ferramenta_matriz ;;
        6)
            echo -ne "${AMARELO}URL: ${RESET}"
            read url
            short=$(api_get "https://tinyurl.com/api-create.php?url=$(url_encode "$url")")
            if [[ -n "$short" ]]; then
                echo -e "${VERDE}════════════════════════════════════════════${RESET}"
                echo -e "${AMARELO}🔗 Original:${RESET} $url"
                echo -e "${AMARELO}🔗 Encurtada:${RESET} $short"
                echo -e "${VERDE}════════════════════════════════════════════${RESET}"
            else
                echo -e "${VERMELHO}Erro ao encurtar URL${RESET}"
            fi
            press_enter
            ;;
        7)
            echo -ne "${AMARELO}E-mail: ${RESET}"
            read em
            echo -e "${CIANO}🔗 Consulte: https://haveibeenpwned.com/account/$em${RESET}"
            if is_termux; then
                termux-open-url "https://haveibeenpwned.com/account/$em"
            fi
            press_enter
            ;;
        8) ferramenta_clima ;;
        9) ferramenta_senha ;;
        10) ferramenta_hash ;;
        11) ferramenta_base64 ;;
        12) ferramenta_useragent ;;
        0) menu; return ;;
        *)
            echo -e "${VERMELHO}Inválido${RESET}"
            sleep 2
            ;;
    esac
    ferramentas_extras
}

# =============================================
# FUNÇÕES CLI DIRETAS
# =============================================
cli_ip() {
    echo -e "${CIANO}Buscando IP $1...${RESET}"
    api_get "http://ip-api.com/json/$1?fields=status,country,region,city,isp,org,query,proxy,hosting" | \
        python3 -c "import sys,json; d=json.load(sys.stdin); [print(f'{k}: {v}') for k,v in d.items()]" 2>/dev/null
}

cli_cnpj() {
    echo -e "${CIANO}Consultando CNPJ $1...${RESET}"
    api_get "https://brasilapi.com.br/api/cnpj/v1/$1" | \
        python3 -c "import sys,json; d=json.load(sys.stdin); [print(f'{k}: {v}') for k,v in d.items()]" 2>/dev/null
}

cli_cep() {
    echo -e "${CIANO}Consultando CEP $1...${RESET}"
    api_get "https://viacep.com.br/ws/$1/json/" | \
        python3 -c "import sys,json; d=json.load(sys.stdin); [print(f'{k}: {v}') for k,v in d.items()]" 2>/dev/null
}

cli_cpf() {
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

cli_placa() {
    local placa=$(echo "$1" | tr 'a-z' 'A-Z')
    echo -e "${CIANO}Consultando placa $placa...${RESET}"
    api_get "https://brasilapi.com.br/api/fipe/preco/v1/$placa" | \
        python3 -c "import sys,json; d=json.load(sys.stdin); print(d if isinstance(d,str) else '\n'.join(f'{k}: {v}' for k,v in (d[0] if isinstance(d,list) else d).items()))" 2>/dev/null
}

cli_dominio() {
    echo -e "${CIANO}Consultando domínio $1...${RESET}"
    ip=$(dig +short "$1" 2>/dev/null | head -1)
    echo "Dominio: $1"
    echo "IP: ${ip:-Não resolvido}"
    dig +short MX "$1" 2>/dev/null | while read line; do echo "MX: $line"; done
}

cli_telefone() {
    local tel=$(echo "$1" | tr -d ' +-')
    echo "Telefone: +$tel"
    echo "DDD: ${tel:2:2}"
    echo "Numero: ${tel:4}"
    echo "Tipo: $( [[ ${#tel:4} -eq 9 ]] && echo "Celular" || echo "Fixo")"
}

cli_tempo() {
    echo -e "${CIANO}Previsão para $1...${RESET}"
    curl -s "wttr.in/$1?m2&lang=pt" 2>/dev/null
}

# =============================================
# MENU PRINCIPAL
# =============================================
menu() {
    banner
    echo -e "${CIANO}╔═══════════════════════════════════════════════╗${RESET}"
    echo -e "${CIANO}║${RESET}   ${AMARELO}1.${RESET} 📍 Buscar IP (ip-api.com real)      ${CIANO}║${RESET}"
    echo -e "${CIANO}║${RESET}   ${AMARELO}2.${RESET} 📱 Dados de Telefone                ${CIANO}║${RESET}"
    echo -e "${CIANO}║${RESET}   ${AMARELO}3.${RESET} 🚗 Buscar Placa (API real)          ${CIANO}║${RESET}"
    echo -e "${CIANO}║${RESET}   ${AMARELO}4.${RESET} 🆔 CNPJ (BrasilAPI - Receita)       ${CIANO}║${RESET}"
    echo -e "${CIANO}║${RESET}   ${AMARELO}5.${RESET} 📇 CPF (validação + dígitos)        ${CIANO}║${RESET}"
    echo -e "${CIANO}║${RESET}   ${AMARELO}6.${RESET} 🌐 Buscar Domínio (DNS + WHOIS)     ${CIANO}║${RESET}"
    echo -e "${CIANO}║${RESET}   ${AMARELO}7.${RESET} 🔍 Buscar Nome (Google Dork)       ${CIANO}║${RESET}"
    echo -e "${CIANO}║${RESET}   ${AMARELO}8.${RESET} 👤 Redes Sociais (username)        ${CIANO}║${RESET}"
    echo -e "${CIANO}║${RESET}   ${AMARELO}9.${RESET} 📧 Consultar E-mail                ${CIANO}║${RESET}"
    echo -e "${CIANO}║${RESET}   ${AMARELO}10.${RESET} 📮 CEP (ViaCEP - rua, bairro)     ${CIANO}║${RESET}"
    echo -e "${CIANO}║${RESET}   ${AMARELO}11.${RESET} 🆔 CPF Completo (Selenium)         ${CIANO}║${RESET}"
    echo -e "${CIANO}║${RESET}   ${AMARELO}12.${RESET} 🛠️  Ferramentas Extras            ${CIANO}║${RESET}"
    echo -e "${CIANO}║${RESET}   ${AMARELO}0.${RESET}  ❌ Sair                           ${CIANO}║${RESET}"
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
        *)
            echo -e "${VERMELHO}Inválido!${RESET}"
            sleep 2
            menu
            ;;
    esac
}

# =============================================
# CLI ARGUMENT PARSING
# =============================================
case "$1" in
    --help|-h) show_help ;;
    --ip) cli_ip "$2"; exit 0 ;;
    --cnpj) cli_cnpj "$2"; exit 0 ;;
    --cep) cli_cep "$2"; exit 0 ;;
    --cpf) cli_cpf "$2"; exit 0 ;;
    --placa) cli_placa "$2"; exit 0 ;;
    --dominio) cli_dominio "$2"; exit 0 ;;
    --telefone) cli_telefone "$2"; exit 0 ;;
    --tempo) cli_tempo "$2"; exit 0 ;;
    --redes)
        echo -e "${CIANO}Buscando username $2 em redes sociais...${RESET}"
        for site in \
            "https://www.instagram.com/$2" \
            "https://twitter.com/$2" \
            "https://github.com/$2" \
            "https://www.tiktok.com/@$2" \
            "https://www.youtube.com/@$2" \
            "https://t.me/$2"; do
            code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "$site" 2>/dev/null)
            [[ "$code" != "404" && "$code" != "000" ]] && echo "✅ $site ($code)"
        done
        exit 0
        ;;
    --email)
        echo -e "${CIANO}Consultando email $2...${RESET}"
        dominio=$(echo "$2" | cut -d'@' -f2)
        echo "Email: $2"
        echo "Dominio: $dominio"
        echo "IP: $(dig +short "$dominio" 2>/dev/null | head -1)"
        dig +short MX "$dominio" 2>/dev/null | while read line; do echo "MX: $line"; done
        echo "HIBP: https://haveibeenpwned.com/account/$2"
        exit 0
        ;;
esac

# =============================================
# INÍCIO
# =============================================
trap 'echo -e "\n${VERMELHO}⚠️  Interrompido pelo usuário${RESET}"; exit 0' INT

echo -e "${CIANO}🔧 Verificando dependências...${RESET}"
for cmd in curl dig python3; do
    if ! command -v $cmd &>/dev/null; then
        echo -e "${AMARELO}⚠️  $cmd não encontrado. Tentando instalar...${RESET}"
        if command -v pkg &>/dev/null; then
            pkg install -y $cmd 2>/dev/null
        elif command -v apt &>/dev/null; then
            sudo apt install -y $cmd 2>/dev/null
        fi
    fi
done

menu
