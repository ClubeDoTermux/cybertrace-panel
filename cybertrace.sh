#!/bin/bash

# ============================================================
# CYBERTRACE v2.4 - Painel de Investigacao Digital
# Consultas com APIs publicas reais
# ------------------------------------------------------------
# TERMUX:  bash install.sh
# LINUX:   bash install.sh --linux
# AJUDA:   bash cybertrace.sh --help
# ============================================================

VERDE='\033[1;32m'
VERMELHO='\033[1;31m'
AZUL='\033[1;34m'
AMARELO='\033[1;33m'
CIANO='\033[1;36m'
RESET='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
HIST_FILE="$SCRIPT_DIR/.cybertrace_historico.log"

# ============================================================
# AUXILIARES
# ============================================================
is_termux() { command -v termux-open-url &>/dev/null; }

url_encode() {
    python3 -c "import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))" "$1" 2>/dev/null
}

api_get() {
    curl -s --max-time 12 "$1" 2>/dev/null
}

press_enter() {
    echo ""
    read -r -p "Pressione ENTER para continuar..." _
}

banner() {
    clear
    echo -e "${VERMELHO}"
    echo "╔═══════════════════════════════════════════════╗"
    echo "║                                               ║"
    echo -e "║     ${CIANO}██████╗██╗   ██╗██████╗ ███████╗██████╗${VERMELHO}   ║"
    echo -e "║     ${CIANO}██╔══██╗╚██╗ ██╔╝██╔══██╗██╔════╝██╔══██╗${VERMELHO} ║"
    echo -e "║     ${CIANO}██████╔╝ ╚████╔╝ ██████╔╝█████╗  ██████╔╝${VERMELHO} ║"
    echo -e "║     ${CIANO}██╔══██╗  ╚██╔╝  ██╔══██╗██╔══╝  ██╔══██╗${VERMELHO} ║"
    echo -e "║     ${CIANO}██████╔╝   ██║   ██████╔╝███████╗██║  ██║${VERMELHO} ║"
    echo -e "║     ${CIANO}╚═════╝    ╚═╝   ╚═════╝ ╚══════╝╚═╝  ╚═╝${VERMELHO} ║"
    echo "║                                               ║"
    echo "╠═══════════════════════════════════════════════╣"
    echo -e "║${AMARELO}    PAINEL DE INVESTIGACAO DIGITAL v2.4   ${VERMELHO}║"
    echo -e "║${CIANO} github.com/ClubeDoTermux/cybertrace-panel ${VERMELHO}║"
    echo "╚═══════════════════════════════════════════════╝"
    echo -e "${RESET}"
}

section() {
    echo -e "${AZUL}╔═══════════════════════════════════════════════╗${RESET}"
    echo -e "${AZUL}║${RESET}   ${VERDE}$1${RESET}"
    echo -e "${AZUL}╚═══════════════════════════════════════════════╝${RESET}"
    echo ""
}

linha() {
    echo -e "${VERDE}════════════════════════════════════════════${RESET}"
}

salvar_historico() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') | $1" >> "$HIST_FILE" 2>/dev/null
}
# ============================================================
# HELP
# ============================================================
show_help() {
    echo -e "${CIANO}CYBERTRACE v2.4 - Painel de Investigacao Digital${RESET}"
    echo -e "${AMARELO}Uso:${RESET} bash cybertrace.sh [opcao] [valor]"
    echo ""
    echo -e "${VERDE}Opcoes:${RESET}"
    echo -e "  ${AMARELO}sem argumentos${RESET}    -> Menu interativo"
    echo -e "  ${AMARELO}--help, -h${RESET}        -> Mostra esta ajuda"
    echo -e "  ${AMARELO}--ip <IP>${RESET}         -> IP detalhado"
    echo -e "  ${AMARELO}--cnpj <CNPJ>${RESET}     -> CNPJ (BrasilAPI)"
    echo -e "  ${AMARELO}--cep <CEP>${RESET}       -> CEP (ViaCEP)"
    echo -e "  ${AMARELO}--cpf <CPF>${RESET}       -> Valida CPF + UF"
    echo -e "  ${AMARELO}--fipe <CODIGO>${RESET}   -> Preco FIPE do veiculo"
    echo -e "  ${AMARELO}--dominio <DOM>${RESET}   -> DNS + WHOIS"
    echo -e "  ${AMARELO}--email <EMAIL>${RESET}   -> MX + Gravatar + HIBP"
    echo -e "  ${AMARELO}--telefone <NUM>${RESET}  -> DDD + cidades"
    echo -e "  ${AMARELO}--redes <USER>${RESET}    -> Username nas redes"
    echo -e "  ${AMARELO}--tempo <CIDADE>${RESET}  -> Previsao do tempo"
    echo -e "  ${AMARELO}--banco <COD>${RESET}     -> Nome do banco (ISPB)"
    echo -e "  ${AMARELO}--cotacoes${RESET}        -> Dolar, Euro, BTC"
    echo -e "  ${AMARELO}--rastreio <COD>${RESET}  -> Rastreio de encomenda"
    echo -e "  ${AMARELO}--feriados [ANO]${RESET}  -> Feriados nacionais"
    echo -e "  ${AMARELO}--ssl <DOM>${RESET}       -> Certificado SSL"
    echo -e "  ${AMARELO}--rdap <DOM>${RESET}      -> WHOIS JSON via RDAP"
    echo -e "  ${AMARELO}--portas <ALVO>${RESET}   -> Portas comuns abertas"
    echo -e "  ${AMARELO}--target <VALOR>${RESET}  -> Auto-detecta e consulta"
    echo -e "  ${AMARELO}--historico${RESET}       -> Historico de consultas"
    echo -e "  ${AMARELO}--update${RESET}          -> Atualiza do GitHub"
    echo ""
    echo -e "${VERDE}Exemplos:${RESET}"
    echo "  bash cybertrace.sh --ip 8.8.8.8"
    echo "  bash cybertrace.sh --target 52998224725"
    echo "  bash cybertrace.sh --cotacoes"
    echo "  bash cybertrace.sh --ddd 11"
    exit 0
}

# ============================================================
# DDD (BrasilAPI) - substitui a tabela fixa do v2.3
# ============================================================
consultar_ddd() {
    local ddd="$1"
    if [[ ! "$ddd" =~ ^[0-9]{2}$ ]]; then
        echo -e "${VERMELHO}DDD invalido.${RESET}"
        return 1
    fi
    local data
    data=$(api_get "https://brasilapi.com.br/api/ddd/v1/$ddd")
    if echo "$data" | python3 -c "import sys,json; json.load(sys.stdin)" 2>/dev/null; then
        echo "$data" | python3 -c "
import sys, json
d = json.load(sys.stdin)
uf = d.get('state','')
cities = d.get('cities', [])
print('  UF     : ' + uf)
print('  Cidades: ' + (', '.join(cities) if cities else '-'))
" 2>/dev/null
    else
        echo -e "${AMARELO}  DDD nao encontrado na BrasilAPI.${RESET}"
    fi
}

# ============================================================
# TELEFONE (DDD dinamico)
# ============================================================
buscar_telefone() {
    banner
    section "CONSULTAR TELEFONE (DDD dinamico)"
    echo -e "${AMARELO}Formato: 55 11 999999999 (pais DDD numero)${RESET}"
    echo -ne "${AMARELO}Numero: ${RESET}"
    read -r tel
    tel=$(echo "$tel" | tr -d ' +-')
    if [[ ${#tel} -lt 12 ]]; then
        echo -e "${VERMELHO}Numero muito curto (use codigo do pais + DDD)${RESET}"
        press_enter
        return
    fi
    local pais="${tel:0:2}"
    local ddd="${tel:2:2}"
    local numero="${tel:4}"
    linha
    echo -e "${AMARELO}Numero completo:${RESET} +$tel"
    echo -e "${AMARELO}Pais:${RESET} $( [[ "$pais" == "55" ]] && echo "Brasil" || echo "$pais" )"
    echo -e "${AMARELO}DDD:${RESET} $ddd"
    echo -e "${AMARELO}Numero:${RESET} $numero"
    echo -e "${AMARELO}Tipo:${RESET} $( [[ ${#numero} -eq 9 ]] && echo "Celular" || echo "Fixo" )"
    linha
    echo ""
    echo -e "${CIANO}Cidades do DDD $ddd:${RESET}"
    consultar_ddd "$ddd"
    salvar_historico "telefone: +$tel"
    press_enter
}

# ============================================================
# VEICULO (FIPE por codigo - corrige o bug da placa)
# ============================================================
buscar_veiculo() {
    banner
    section "VEICULO - PRECO FIPE (codigo)"
    echo -e "${AMARELO}Dados por placa exigem Detran (pago/LGPD).${RESET}"
    echo -e "${CIANO}Consulte o preco FIPE pelo CODIGO, achado em:${RESET}"
    echo -e "${CIANO}  https://veiculos.fipe.org.br${RESET}"
    echo -n "${AMARELO}Codigo FIPE (ex: 001004-0): ${RESET}"
    read -r cod
    [[ -z "$cod" ]] && { echo -e "${VERMELHO}Invalido${RESET}"; press_enter; return; }
    echo -e "${CIANO}Consultando BrasilAPI/FIPE...${RESET}"
    if cli_fipe "$cod"; then
        salvar_historico "FIPE: $cod"
    fi
    press_enter
}

# ============================================================
# CNPJ (BrasilAPI)
# ============================================================
cli_cnpj() {
    local cnpj="$1"
    local data
    data=$(api_get "https://brasilapi.com.br/api/cnpj/v1/$cnpj")
    if echo "$data" | python3 -c "import sys,json; d=json.load(sys.stdin); exit(0 if 'cnpj' in d else 1)" 2>/dev/null; then
        echo "$data" | python3 -c "
import sys, json
d = json.load(sys.stdin)
print('=' * 60)
print('  CNPJ        : %s' % d.get('cnpj',''))
print('  Razao Social: %s' % d.get('razao_social',''))
print('  Fantasia    : %s' % d.get('nome_fantasia',''))
print('  Endereco    : %s, %s - %s' % (d.get('logradouro',''), d.get('numero',''), d.get('bairro','')))
print('  Cidade/UF   : %s/%s - %s' % (d.get('municipio',''), d.get('uf',''), d.get('cep','')))
print('  Telefone    : %s' % d.get('ddd_telefone_1',''))
print('  Email       : %s' % d.get('email',''))
print('  Porte       : %s' % d.get('porte',''))
print('  Abertura    : %s' % d.get('data_inicio_atividade',''))
print('  Situacao    : %s' % d.get('situacao_cadastral',''))
print('  Capital     : R$ %s' % d.get('capital_social',''))
print('  CNAE        : %s - %s' % (d.get('cnae_fiscal',''), d.get('cnae_fiscal_descricao','')))
print('=' * 60)
" 2>/dev/null
    else
        echo -e "${VERMELHO}CNPJ nao encontrado ou invalido.${RESET}"
    fi
}

buscar_cnpj() {
    banner
    section "CNPJ REAL (BrasilAPI - Receita Federal)"
    echo -ne "${AMARELO}CNPJ (14 digitos): ${RESET}"
    read -r cnpj
    cnpj=$(echo "$cnpj" | tr -d ' ./-')
    if [[ ${#cnpj} -ne 14 ]]; then
        echo -e "${VERMELHO}CNPJ deve ter 14 digitos${RESET}"
        press_enter
        return
    fi
    echo -e "${CIANO}Consultando Receita Federal via BrasilAPI...${RESET}"
    cli_cnpj "$cnpj"
    salvar_historico "CNPJ: $cnpj"
    press_enter
}

# ============================================================
# CPF (validacao de digitos + UF)
# ============================================================
cli_cpf() {
    local cpf
    cpf=$(echo "$1" | tr -d ' .-')
    python3 -c "
import sys
cpf = sys.argv[1]
if len(cpf) != 11 or not cpf.isdigit():
    print('ERRO: CPF deve ter 11 digitos')
    sys.exit(1)
d1, d2 = int(cpf[9]), int(cpf[10])
r1 = (sum(int(cpf[i])*(10-i) for i in range(9))*10) % 11
r2 = (sum(int(cpf[i])*(11-i) for i in range(10))*10) % 11
if r1 == 10: r1 = 0
if r2 == 10: r2 = 0
v = (r1 == d1 and r2 == d2)
e = {0:'RS',1:'DF/GO/MS/MT',2:'PA/AM/AC/RO/RR',3:'CE/MA/PI',4:'PE/PB/RN/AL',5:'BA/SE',6:'MG',7:'RJ/ES',8:'SP',9:'PR/SC'}
print('CPF: %s.%s.%s-%s' % (cpf[:3], cpf[3:6], cpf[6:9], cpf[9:]))
print('Valido: %s' % ('SIM' if v else 'NAO'))
if v:
    print('UF emissor: %s' % e.get(int(cpf[8]), 'Desconhecido'))
" "$cpf" 2>/dev/null
}

validar_cpf() {
    banner
    section "VALIDACAO DE CPF"
    echo -e "${VERMELHO}[!] Dados reais de CPF sao protegidos por lei (LGPD)${RESET}"
    echo -n "${AMARELO}CPF (11 digitos): ${RESET}"
    read -r cpf
    cpf=$(echo "$cpf" | tr -d ' .-')
    if [[ ${#cpf} -ne 11 ]]; then
        echo -e "${VERMELHO}CPF invalido${RESET}"
        press_enter
        return
    fi
    linha
    cli_cpf "$cpf"
    linha
    salvar_historico "CPF: $cpf"
    press_enter
}

# ============================================================
# DOMINIO (DNS + WHOIS)
# ============================================================
cli_dominio() {
    local dom="$1"
    local ip
    ip=$(timeout 6 dig +short "$dom" 2>/dev/null | head -1)
    linha
    echo -e "${AMARELO}Dominio:${RESET} $dom"
    echo -e "${AMARELO}IP:${RESET} ${ip:-Nao resolvido}"
    echo ""
    echo -e "${CIANO}Registros DNS:${RESET}"
    echo -e "${AMARELO}MX:${RESET}"
    timeout 6 dig +short MX "$dom" 2>/dev/null | while read -r l; do echo "   $l"; done
    echo -e "${AMARELO}NS:${RESET}"
    timeout 6 dig +short NS "$dom" 2>/dev/null | while read -r l; do echo "   $l"; done
    echo -e "${AMARELO}TXT (5):${RESET}"
    timeout 6 dig +short TXT "$dom" 2>/dev/null | head -5 | while read -r l; do echo "   $l"; done
    echo ""
    if command -v whois &>/dev/null; then
        echo -e "${CIANO}WHOIS (resumo):${RESET}"
        timeout 8 whois "$dom" 2>/dev/null | grep -iE "registrant|owner|email|created|expir|name|organization|status" | head -8
    else
        echo -e "${AMARELO}whois nao instalado - use RDAP para mais dados.${RESET}"
    fi
    linha
}

buscar_dominio() {
    banner
    section "CONSULTAR DOMINIO (DNS + WHOIS)"
    echo -n "${AMARELO}Dominio: ${RESET}"
    read -r dom
    [[ -z "$dom" ]] && { echo -e "${VERMELHO}Invalido${RESET}"; press_enter; return; }
    cli_dominio "$dom"
    salvar_historico "dominio: $dom"
    press_enter
}

# ============================================================
# CEP (ViaCEP)
# ============================================================
cli_cep() {
    local cep="$1"
    local data
    data=$(api_get "https://viacep.com.br/ws/$cep/json/")
    if echo "$data" | python3 -c "import sys,json; d=json.load(sys.stdin); exit(0 if 'erro' not in d else 1)" 2>/dev/null; then
        echo "$data" | python3 -c "
import sys, json
d = json.load(sys.stdin)
print('=' * 60)
print('  CEP     : %s' % d.get('cep',''))
print('  Rua     : %s' % d.get('logradouro',''))
print('  Bairro  : %s' % d.get('bairro',''))
print('  Cidade  : %s' % d.get('localidade',''))
print('  UF      : %s (%s)' % (d.get('uf',''), d.get('estado','')))
print('  DDD     : %s' % d.get('ddd',''))
print('  IBGE    : %s' % d.get('ibge',''))
print('=' * 60)
" 2>/dev/null
    else
        echo -e "${VERMELHO}CEP nao encontrado.${RESET}"
    fi
}

buscar_cep() {
    banner
    section "CONSULTAR CEP (ViaCEP API)"
    echo -n "${AMARELO}CEP: ${RESET}"
    read -r cep
    cep=$(echo "$cep" | tr -d ' -')
    if [[ ${#cep} -ne 8 ]]; then
        echo -e "${VERMELHO}CEP deve ter 8 digitos${RESET}"
        press_enter
        return
    fi
    echo -e "${CIANO}Consultando ViaCEP...${RESET}"
    cli_cep "$cep"
    salvar_historico "CEP: $cep"
    press_enter
}

# ============================================================
# BANCO (ISPB - BrasilAPI) - NOVO
# ============================================================
cli_banco() {
    local cod="$1"
    local data
    data=$(api_get "https://brasilapi.com.br/api/banks/v1/$cod")
    if echo "$data" | python3 -c "import sys,json; d=json.load(sys.stdin); exit(0 if 'name' in d else 1)" 2>/dev/null; then
        echo "$data" | python3 -c "
import sys, json
d = json.load(sys.stdin)
print('=' * 60)
print('  Codigo: %s' % d.get('code',''))
print('  Banco : %s' % d.get('name',''))
print('  ISPB  : %s' % d.get('ispb',''))
print('  Nome  : %s' % d.get('fullName',''))
print('=' * 60)
" 2>/dev/null
        return 0
    fi
    return 1
}

consultar_banco() {
    banner
    section "CONSULTAR BANCO (BrasilAPI)"
    echo -e "${AMARELO}Ex: 260 Nubank, 341 Itau, 237 Bradesco, 001 BB${RESET}"
    echo -n "${AMARELO}Codigo do banco: ${RESET}"
    read -r cod
    [[ -z "$cod" ]] && { echo -e "${VERMELHO}Invalido${RESET}"; press_enter; return; }
    echo -e "${CIANO}Consultando...${RESET}"
    if cli_banco "$cod"; then
        salvar_historico "banco: $cod"
    else
        echo -e "${VERMELHO}Banco nao encontrado (tente 001, 237, 341, 260).${RESET}"
    fi
    press_enter
}

# ============================================================
# DDD (menu) - NOVO
# ============================================================
buscar_ddd() {
    banner
    section "DDD + CIDADES (BrasilAPI)"
    echo -n "${AMARELO}DDD: ${RESET}"
    read -r ddd
    [[ -z "$ddd" ]] && { echo -e "${VERMELHO}Invalido${RESET}"; press_enter; return; }
    salvar_historico "DDD: $ddd"
    consultar_ddd "$ddd"
    press_enter
}

# ============================================================
# COTACOES (AwesomeAPI) - NOVO
# ============================================================
cli_cotacoes() {
    local data
    data=$(api_get "https://economia.awesomeapi.com.br/json/last/USD-BRL,EUR-BRL,BTC-BRL")
    if echo "$data" | python3 -c "import sys,json; json.load(sys.stdin)" 2>/dev/null; then
        echo "$data" | python3 -c "
import sys, json
d = json.load(sys.stdin)
print('=' * 60)
for k in ('USDBRL','EURBRL','BTCBRL'):
    v = d.get(k, {})
    if v:
        print('  %-5s: R$ %s (variacao %s%%)' % (v.get('code',''), v.get('bid',''), v.get('pctChange','')))
print('=' * 60)
" 2>/dev/null
        return 0
    fi
    return 1
}

cotacoes() {
    banner
    section "COTACOES (Dolar, Euro, BTC)"
    if cli_cotacoes; then
        salvar_historico "cotacoes"
    else
        echo -e "${VERMELHO}Erro ao consultar cotacoes.${RESET}"
    fi
    press_enter
}

# ============================================================
# RASTREIO (Linketrack API gratuita) - NOVO
# ============================================================
cli_rastreio() {
    local cod="$1"
    local data
    # Credenciais: use LINKETRACK_USER/LINKETRACK_TOKEN do ambiente se existirem
    local user="${LINKETRACK_USER:-teste}"
    local token="${LINKETRACK_TOKEN:-teste}"
    data=$(curl -s --max-time 15 "https://api.linketrack.com/track/json?user=$user&token=$token&codigo=$cod" 2>/dev/null)
    if echo "$data" | python3 -c "import sys,json; d=json.load(sys.stdin); exit(0 if d.get('eventos') else 1)" 2>/dev/null; then
        echo "$data" | python3 -c "
import sys, json
d = json.load(sys.stdin)
print('=' * 60)
print('  Codigo : %s' % d.get('codigo',''))
print('  Servico: %s' % d.get('servico',''))
print('  Eventos:')
for e in d.get('eventos', [])[:8]:
    print('    [%s %s] %s' % (e.get('data',''), e.get('hora',''), e.get('local','')))
    print('        %s' % e.get('status',''))
print('=' * 60)
" 2>/dev/null
        return 0
    fi
    echo -e "${AMARELO}Dica: cadastre-se gratis em linketrack.com e rode:${RESET}"
    echo -e "${AMARELO}  LINKETRACK_USER=seu LINKETRACK_TOKEN=seu bash cybertrace.sh --rastreio CODIGO${RESET}"
    return 1
}

rastrear() {
    banner
    section "RASTREAR ENCOMENDA (Correios)"
    echo -e "${AMARELO}Codigo: LU123456789BR (PAC/SEDEX)${RESET}"
    echo -n "${AMARELO}Codigo de rastreio: ${RESET}"
    read -r cod
    [[ -z "$cod" ]] && { echo -e "${VERMELHO}Invalido${RESET}"; press_enter; return; }
    echo -e "${CIANO}Rastreando...${RESET}"
    if cli_rastreio "$cod"; then
        salvar_historico "rastreio: $cod"
    else
        echo -e "${VERMELHO}Nao encontrado (confira o codigo ou tente de novo).${RESET}"
    fi
    press_enter
}

# ============================================================
# FERIADOS (BrasilAPI) - NOVO
# ============================================================
cli_feriados() {
    local ano="$1"
    local data
    data=$(api_get "https://brasilapi.com.br/api/feriados/v1/$ano")
    if echo "$data" | python3 -c "import sys,json; d=json.load(sys.stdin); exit(0 if isinstance(d,list) and d else 1)" 2>/dev/null; then
        echo "$data" | python3 -c "
import sys, json
d = json.load(sys.stdin)
print('=' * 60)
for f in d:
    print('  %s  %s' % (f.get('date',''), f.get('name','')))
print('=' * 60)
" 2>/dev/null
        return 0
    fi
    return 1
}

feriados() {
    banner
    section "FERIADOS NACIONAIS"
    echo -n "${AMARELO}Ano (padrao: atual): ${RESET}"
    read -r ano
    ano="${ano:-$(date +%Y)}"
    echo -e "${CIANO}Buscando feriados de $ano...${RESET}"
    if cli_feriados "$ano"; then
        salvar_historico "feriados $ano"
    else
        echo -e "${VERMELHO}Erro ao buscar feriados.${RESET}"
    fi
    press_enter
}

# ============================================================
# SSL (certificado) - NOVO
# ============================================================
cli_ssl() {
    local dom="$1"
    if ! command -v openssl &>/dev/null; then
        echo -e "${VERMELHO}openssl nao encontrado (pkg install openssl-tool).${RESET}"
        return 1
    fi
    local saida
    saida=$(echo | timeout 12 openssl s_client -servername "$dom" -connect "$dom:443" 2>/dev/null | openssl x509 -noout -dates -issuer 2>/dev/null)
    if [[ -n "$saida" ]]; then
        linha
        echo "$saida"
        linha
        return 0
    fi
    return 1
}

ssl_certificado() {
    banner
    section "CERTIFICADO SSL"
    echo -n "${AMARELO}Dominio: ${RESET}"
    read -r dom
    [[ -z "$dom" ]] && { echo -e "${VERMELHO}Invalido${RESET}"; press_enter; return; }
    echo -e "${CIANO}Verificando certificado de $dom...${RESET}"
    if cli_ssl "$dom"; then
        salvar_historico "ssl: $dom"
    else
        echo -e "${VERMELHO}Nao foi possivel obter (porta 443 fechada?).${RESET}"
    fi
    press_enter
}

# ============================================================
# RDAP (WHOIS JSON) - NOVO
# ============================================================
cli_rdap() {
    local dom="$1"
    local tld="${dom##*.}"
    local data=""
    # Tenta fontes RDAP em ordem (rdap.org global, Verisign p/ com/net, registro.br p/ br)
    case "$tld" in
        br)   data=$(api_get "https://rdap.registro.br/domain/$dom") ;;
        com|net)
              data=$(api_get "https://rdap.verisign.com/$tld/v1/domain/$dom") ;;
    esac
    [[ -z "$data" ]] && data=$(api_get "https://rdap.org/domain/$dom")
    if echo "$data" | python3 -c "import sys,json; json.load(sys.stdin)" 2>/dev/null; then
        echo "$data" | python3 -c "
import sys, json
d = json.load(sys.stdin)
print('=' * 60)
print('  Dominio  : %s' % d.get('ldhName',''))
st = d.get('status', [])
if st: print('  Status   : %s' % ', '.join(st))
for ev in d.get('events', []):
    print('  %s: %s' % (ev.get('eventAction',''), ev.get('eventDate','')[:10]))
for ent in d.get('entities', []):
    roles = ent.get('roles', [])
    vcard = ent.get('vcardArray', [[], []])[1]
    fn = ''
    em = ''
    for item in vcard:
        if item[0] == 'fn': fn = item[3]
        if item[0] == 'email': em = item[3]
    if 'registrar' in roles and fn: print('  Registrar: %s' % fn)
    if 'abuse' in roles and em: print('  Abuse    : %s' % em)
ns = d.get('nameservers', [])
if ns: print('  NS       : %s' % ', '.join(n.get('ldhName','') for n in ns))
print('=' * 60)
" 2>/dev/null
        return 0
    fi
    return 1
}

rdap_whois() {
    banner
    section "WHOIS VIA RDAP (JSON)"
    echo -n "${AMARELO}Dominio: ${RESET}"
    read -r dom
    [[ -z "$dom" ]] && { echo -e "${VERMELHO}Invalido${RESET}"; press_enter; return; }
    if cli_rdap "$dom"; then
        salvar_historico "rdap: $dom"
    else
        echo -e "${VERMELHO}Dominio nao encontrado no RDAP.${RESET}"
    fi
    press_enter
}

# ============================================================
# HASH DETECTOR - NOVO
# ============================================================
detectar_hash() {
    banner
    section "IDENTIFICAR TIPO DE HASH"
    echo -n "${AMARELO}Hash: ${RESET}"
    read -r hash
    [[ -z "$hash" ]] && { echo -e "${VERMELHO}Invalido${RESET}"; press_enter; return; }
    linha
    echo "$hash" | python3 -c "
import sys, re
h = sys.stdin.read().strip().lower()
l = len(h)
tipo = 'Provavel texto (nao parece hash)'
if re.fullmatch(r'[0-9a-f]{32}', h):   tipo = 'MD5 (32 hex)'
elif re.fullmatch(r'[0-9a-f]{40}', h): tipo = 'SHA1 (40 hex)'
elif re.fullmatch(r'[0-9a-f]{64}', h): tipo = 'SHA256 (64 hex)'
elif re.fullmatch(r'[0-9a-f]{96}', h): tipo = 'SHA384 (96 hex)'
elif re.fullmatch(r'[0-9a-f]{128}', h): tipo = 'SHA512 (128 hex)'
elif h.startswith('\$2a\$') or h.startswith('\$2b\$'): tipo = 'bcrypt'
elif h.startswith('\$1\$'): tipo = 'MD5 crypt'
elif h.startswith('\$6\$'): tipo = 'SHA512 crypt'
print(tipo + ' (%d caracteres)' % l)
" 2>/dev/null
    salvar_historico "hash detector"
    press_enter
}

# ============================================================
# PORTAS - NOVO
# ============================================================
cli_portas() {
    local alvo="$1"
    local portas="21 22 25 53 80 110 143 443 465 993 3306 3389 5432 8080"
    local encontrou=0
    for p in $portas; do
        if timeout 3 bash -c "echo > /dev/tcp/$alvo/$p" 2>/dev/null; then
            echo -e "  ${VERDE}[ABERTA]${RESET} porta $p"
            encontrou=1
        fi
    done
    [[ $encontrou -eq 0 ]] && echo -e "${AMARELO}Nenhuma porta comum aberta.${RESET}"
}

scanner_portas() {
    banner
    section "SCANNER DE PORTAS COMUNS"
    echo -n "${AMARELO}Alvo (IP ou dominio): ${RESET}"
    read -r alvo
    [[ -z "$alvo" ]] && { echo -e "${VERMELHO}Invalido${RESET}"; press_enter; return; }
    echo -e "${CIANO}Testando portas: 21 22 25 53 80 110 143 443 465 993 3306 3389 5432 8080${RESET}"
    linha
    cli_portas "$alvo"
    linha
    salvar_historico "portas: $alvo"
    press_enter
}

# ============================================================
# EMAIL (CLI)
# ============================================================
cli_email() {
    local email="$1"
    local dominio ip hash
    dominio=$(echo "$email" | cut -d'@' -f2)
    echo -e "${AMARELO}Email:${RESET} $email"
    echo -e "${AMARELO}Dominio:${RESET} $dominio"
    ip=$(dig +short "$dominio" 2>/dev/null | head -1)
    echo -e "${AMARELO}IP:${RESET} ${ip:-Nao resolvido}"
    echo -e "${AMARELO}MX:${RESET}"
    dig +short MX "$dominio" 2>/dev/null | while read -r l; do echo "   $l"; done
    echo -e "${AMARELO}NS:${RESET}"
    dig +short NS "$dominio" 2>/dev/null | while read -r l; do echo "   $l"; done
    hash=$(echo -n "$email" | md5sum 2>/dev/null | cut -d' ' -f1)
    echo -e "${AMARELO}Gravatar:${RESET} https://www.gravatar.com/avatar/$hash"
    echo -e "${AMARELO}HIBP:${RESET} https://haveibeenpwned.com/account/$email"
    echo -e "${AMARELO}Hunter.io:${RESET} https://hunter.io/search/$dominio"
}

consultar_email() {
    banner
    section "CONSULTAR E-MAIL (MX, Gravatar, HIBP)"
    echo -n "${AMARELO}E-mail: ${RESET}"
    read -r email
    [[ -z "$email" ]] && { echo -e "${VERMELHO}Invalido${RESET}"; press_enter; return; }
    linha
    cli_email "$email"
    linha
    salvar_historico "email: $email"
    press_enter
}

# ============================================================
# MODO AUTO --target - NOVO
# ============================================================
cli_target() {
    local valor="$1"
    local tipo
    tipo=$(echo "$valor" | python3 -c "
import sys, re
v = sys.argv[1].strip()
if re.fullmatch(r'\d{1,3}(\.\d{1,3}){3}', v): print('ip')
elif re.fullmatch(r'\d{8}', v): print('cep')
elif re.fullmatch(r'\d{11}', v): print('cpf')
elif re.fullmatch(r'\d{14}', v): print('cnpj')
elif '@' in v: print('email')
elif re.fullmatch(r'[A-Za-z0-9-]+(\.[A-Za-z0-9-]+)+', v): print('dominio')
elif re.fullmatch(r'\+?\d{10,13}', v): print('telefone')
elif re.fullmatch(r'[A-Za-z]{3}\d[A-Za-z0-9]\d{2}', v): print('placa')
else: print('desconhecido')
" "$valor" 2>/dev/null)
    case "$tipo" in
        ip)        python3 "$SCRIPT_DIR/ip_consulta.py" "$valor" ;;
        cep)       cli_cep "$valor" ;;
        cpf)       echo -e "${CIANO}CPF detectado:${RESET}"; cli_cpf "$valor" ;;
        cnpj)      echo -e "${CIANO}CNPJ detectado:${RESET}"; cli_cnpj "$valor" ;;
        email)     echo -e "${CIANO}Email detectado:${RESET}"; cli_email "$valor" ;;
        dominio)   cli_dominio "$valor" ;;
        telefone)  echo -e "${CIANO}Telefone detectado:${RESET}"
                   tel=$(echo "$valor" | tr -d ' +-')
                   echo -e "${AMARELO}DDD:${RESET} ${tel:2:2}"
                   consultar_ddd "${tel:2:2}" ;;
        placa)     echo -e "${AMARELO}Placa: dados pagos do Detran. Use FIPE p/ precos.${RESET}" ;;
        *)         echo -e "${VERMELHO}Tipo nao identificado.${RESET}" ;;
    esac
    salvar_historico "target: $valor"
}

modo_target() {
    banner
    section "MODO AUTO (detecta o tipo da consulta)"
    echo -e "${CIANO}IP, CEP, CPF, CNPJ, email, dominio, telefone, placa...${RESET}"
    echo -n "${AMARELO}Valor: ${RESET}"
    read -r valor
    [[ -z "$valor" ]] && { echo -e "${VERMELHO}Invalido${RESET}"; press_enter; return; }
    cli_target "$valor"
    press_enter
}

# ============================================================
# CONSULTA EM LOTE - NOVO
# ============================================================
consulta_lote() {
    banner
    section "CONSULTA EM LOTE (arquivo)"
    echo -n "${AMARELO}Arquivo (um alvo por linha): ${RESET}"
    read -r arq
    if [[ -z "$arq" || ! -f "$arq" ]]; then
        echo -e "${VERMELHO}Arquivo nao encontrado.${RESET}"
        press_enter
        return
    fi
    echo -n "${AMARELO}Tipo (ip, cep, cnpj, dominio, email): ${RESET}"
    read -r tipo
    echo -e "${CIANO}Processando $(wc -l < "$arq") alvos...${RESET}"
    while IFS= read -r alvo; do
        [[ -z "$alvo" || "$alvo" == \#* ]] && continue
        echo ""
        echo -e "${AMARELO}--- $alvo${RESET}"
        case "$tipo" in
            ip)      python3 "$SCRIPT_DIR/ip_consulta.py" "$alvo" | head -8 ;;
            cep)     cli_cep "$alvo" ;;
            cnpj)    cli_cnpj "$alvo" ;;
            dominio) cli_dominio "$alvo" ;;
            email)   cli_email "$alvo" ;;
            *)       echo "tipo invalido: $tipo"; break ;;
        esac
    done < "$arq"
    salvar_historico "lote: $tipo"
    press_enter
}

# ============================================================
# HISTORICO
# ============================================================
historico_menu() {
    banner
    section "HISTORICO DE CONSULTAS"
    if [[ -f "$HIST_FILE" ]] && [[ -s "$HIST_FILE" ]]; then
        echo -e "${CIANO}Arquivo:${RESET} $HIST_FILE"
        echo -e "${VERDE}──────────────────────────────────────────${RESET}"
        tail -30 "$HIST_FILE"
        echo -e "${VERDE}──────────────────────────────────────────${RESET}"
    else
        echo -e "${AMARELO}Historico vazio.${RESET}"
    fi
    echo ""
    echo -n "${AMARELO}Limpar historico? (s/N): ${RESET}"
    read -r r
    if [[ "$r" == "s" || "$r" == "S" ]]; then
        : > "$HIST_FILE" 2>/dev/null
        echo -e "${VERDE}[OK] Historico limpo.${RESET}"
    fi
    press_enter
}

# ============================================================
# ATUALIZAR (git pull) - NOVO
# ============================================================
atualizar_painel() {
    banner
    section "ATUALIZAR (GIT PULL)"
    cd "$SCRIPT_DIR" || return
    git fetch origin main 2>/dev/null || git fetch origin master 2>/dev/null
    local atual nova
    atual=$(git rev-parse HEAD 2>/dev/null)
    nova=$(git rev-parse origin/main 2>/dev/null || git rev-parse origin/master 2>/dev/null)
    if [[ "$atual" != "$nova" ]]; then
        echo -e "${CIANO}Atualizacao encontrada. Baixando...${RESET}"
        git pull 2>/dev/null
        echo -e "${VERDE}[OK] Painel atualizado. Reinicie!${RESET}"
    else
        echo -e "${VERDE}[OK] Voce esta na versao mais recente.${RESET}"
    fi
    press_enter
}

# ============================================================
# BUSCAR NOME (DORKING)
# ============================================================
buscar_nome() {
    banner
    section "BUSCAR NOME (Google Dorking)"
    echo -n "${CIANO}Nome completo: ${RESET}"
    read -r nome
    [[ -z "$nome" ]] && { echo -e "${VERMELHO}Invalido${RESET}"; press_enter; return; }
    local nome_encoded
    nome_encoded=$(url_encode "$nome")
    echo -e "${VERDE}════════════════════════════════════════════${RESET}"
    echo -e "${AMARELO}Google:${RESET} https://www.google.com/search?q=$nome_encoded"
    echo -e "${AMARELO}LinkedIn:${RESET} https://www.linkedin.com/search/results/all/?keywords=$nome_encoded"
    echo -e "${AMARELO}Facebook:${RESET} https://www.facebook.com/search/top/?q=$nome_encoded"
    echo -e "${AMARELO}X/Twitter:${RESET} https://twitter.com/search?q=$nome_encoded"
    echo -e "${AMARELO}Escavador:${RESET} https://www.escavador.com/?q=$nome_encoded"
    echo -e "${AMARELO}JusBrasil:${RESET} https://www.jusbrasil.com.br/busca?q=$nome_encoded"
    echo -e "${AMARELO}Telegram:${RESET} https://t.me/s?q=$nome_encoded"
    echo -e "${VERDE}════════════════════════════════════════════${RESET}"
    salvar_historico "dorking: $nome"
    echo -n "${AMARELO}Abrir no navegador? (s/N): ${RESET}"
    read -r resp
    if [[ "$resp" == "s" || "$resp" == "S" ]]; then
        if is_termux; then
            termux-open-url "https://www.google.com/search?q=$nome_encoded" 2>/dev/null
        elif command -v xdg-open &>/dev/null; then
            xdg-open "https://www.google.com/search?q=$nome_encoded" 2>/dev/null
        else
            echo -e "${AMARELO}Abra manualmente o link do Google.${RESET}"
        fi
    fi
    press_enter
}

# ============================================================
# REDES SOCIAIS (sem duplicatas + check)
# ============================================================
redes_sociais() {
    banner
    section "BUSCAR USERNAME EM REDES SOCIAIS"
    echo -n "${AMARELO}Username: ${RESET}"
    read -r user
    [[ -z "$user" ]] && { echo -e "${VERMELHO}Invalido${RESET}"; press_enter; return; }
    echo -e "${CIANO}Verificando presenca de @$user...${RESET}"
    echo -e "${VERDE}════════════════════════════════════════════${RESET}"
    local sites=(
        "Instagram:https://www.instagram.com/$user"
        "X/Twitter:https://twitter.com/$user"
        "GitHub:https://github.com/$user"
        "LinkedIn:https://www.linkedin.com/in/$user"
        "Facebook:https://www.facebook.com/$user"
        "TikTok:https://www.tiktok.com/@$user"
        "YouTube:https://www.youtube.com/@$user"
        "Reddit:https://www.reddit.com/user/$user"
        "Telegram:https://t.me/$user"
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
        "WhatsApp:https://wa.me/$user"
    )
    local site nome_site url
    for site in "${sites[@]}"; do
        nome_site="${site%%:*}"
        url="${site#*:}"
        echo -e "${CIANO}• ${AMARELO}$nome_site:${RESET} $url"
    done
    echo -e "${VERDE}════════════════════════════════════════════${RESET}"
    salvar_historico "redes: $user"
    echo -n "${AMARELO}Verificar existencia (HTTP check)? (s/N): ${RESET}"
    read -r check
    if [[ "$check" == "s" || "$check" == "S" ]]; then
        echo ""
        echo -e "${CIANO}Perfis com resposta (HTTP 200 pode ser login):${RESET}"
        local code
        for site in "${sites[@]}"; do
            nome_site="${site%%:*}"
            url="${site#*:}"
            code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "$url" 2>/dev/null)
            if [[ "$code" != "000" && "$code" != "404" ]]; then
                echo -e "  ${VERDE}[HTTP $code]${RESET} $nome_site"
            fi
        done
    fi
    press_enter
}

# ============================================================
# CPF COMPLETO (Selenium - requer Linux/Chrome)
# ============================================================
cpf_completo_menu() {
    echo -e "${VERMELHO}[!] Requer Chrome + Selenium — indisponivel no Termux.${RESET}"
    echo -e "${AMARELO}Linux: pip install selenium webdriver-manager beautifulsoup4${RESET}"
    echo -e "${AMARELO}Depois: python3 cpf_consulta.py SEU_CPF${RESET}"
    press_enter
}

# ============================================================
# FERRAMENTAS EXTRAS
# ============================================================
info_sistema() {
    echo -e "${CIANO}INFORMACOES DO SISTEMA${RESET}"
    echo -e "${VERDE}────────────────────────────────────────────${RESET}"
    echo -e "${AMARELO}OS:${RESET} $(uname -o 2>/dev/null || echo N/A)"
    echo -e "${AMARELO}Kernel:${RESET} $(uname -r 2>/dev/null || echo N/A)"
    echo -e "${AMARELO}Shell:${RESET} $SHELL"
    echo -e "${AMARELO}Data:${RESET} $(date '+%d/%m/%Y %H:%M')"
    if is_termux; then
        echo -e "${AMARELO}Dispositivo:${RESET} $(getprop ro.product.model 2>/dev/null || echo N/A)"
        echo -e "${AMARELO}Android:${RESET} $(getprop ro.build.version.release 2>/dev/null || echo N/A)"
        echo -e "${AMARELO}Bateria:${RESET} $(termux-battery-status 2>/dev/null | python3 -c "import sys,json; d=json.load(sys.stdin); print(f\"{d['percentage']}%\")" 2>/dev/null || echo N/A)"
    fi
    echo -e "${AMARELO}IP publico:${RESET} $(curl -s --max-time 5 https://ifconfig.me 2>/dev/null || echo N/A)"
    echo -e "${AMARELO}Uptime:${RESET} $(uptime -p 2>/dev/null || echo N/A)"
    echo -e "${VERDE}────────────────────────────────────────────${RESET}"
    press_enter
}

gerar_senha() {
    echo -n "${AMARELO}Tamanho (8-50, padrao 16): ${RESET}"
    read -r tam
    tam=${tam:-16}
    if ! [[ "$tam" =~ ^[0-9]+$ ]] || [[ $tam -lt 8 ]] || [[ $tam -gt 50 ]]; then
        tam=16
    fi
    echo -e "${CIANO}Senhas:${RESET}"
    for _ in 1 2 3; do
        python3 -c "
import secrets, string
chars = string.ascii_letters + string.digits + string.punctuation
print('  ' + ''.join(secrets.choice(chars) for _ in range($tam)))
" 2>/dev/null
    done
    press_enter
}

gerar_hash() {
    echo -n "${AMARELO}Texto: ${RESET}"
    read -r texto
    [[ -z "$texto" ]] && { echo -e "${VERMELHO}Invalido${RESET}"; press_enter; return; }
    echo -e "${VERDE}────────────────────────────────────────────${RESET}"
    echo -e "${AMARELO}MD5:${RESET}    $(echo -n "$texto" | md5sum 2>/dev/null | cut -d' ' -f1)"
    echo -e "${AMARELO}SHA1:${RESET}   $(echo -n "$texto" | sha1sum 2>/dev/null | cut -d' ' -f1)"
    echo -e "${AMARELO}SHA256:${RESET} $(echo -n "$texto" | sha256sum 2>/dev/null | cut -d' ' -f1)"
    echo -e "${AMARELO}SHA512:${RESET} $(echo -n "$texto" | sha512sum 2>/dev/null | cut -d' ' -f1)"
    echo -e "${VERDE}────────────────────────────────────────────${RESET}"
    press_enter
}

menu_base64() {
    echo -e "${CIANO}BASE64 ENCODE/DECODE${RESET}"
    echo -e "${VERDE}────────────────────────────────────────────${RESET}"
    echo -e "  ${AMARELO}[1]${RESET} Codificar"
    echo -e "  ${AMARELO}[2]${RESET} Decodificar"
    echo -n "${VERDE}> ${RESET}"
    read -r op
    case $op in
        1) echo -n "${AMARELO}Texto: ${RESET}"; read -r t; echo -n "$t" | base64; echo "" ;;
        2) echo -n "${AMARELO}Base64: ${RESET}"; read -r b; echo "$b" | base64 -d 2>/dev/null || echo "invalido"; echo "" ;;
        *) echo -e "${VERMELHO}Invalido${RESET}" ;;
    esac
    press_enter
}

menu_qrcode() {
    echo -n "${AMARELO}Texto para o QR: ${RESET}"
    read -r qt
    if command -v qrencode &>/dev/null; then
        linha
        qrencode -t ANSIUTF8 "$qt" 2>/dev/null || echo -e "${VERMELHO}Erro ao gerar QR.${RESET}"
        linha
        echo ""
        echo -n "${AMARELO}Salvar como PNG? (s/N): ${RESET}"
        read -r sv
        if [[ "$sv" == "s" || "$sv" == "S" ]]; then
            qrencode -o "$SCRIPT_DIR/qr_$(date +%s).png" "$qt" 2>/dev/null && echo -e "${VERDE}[OK] Salvo em $SCRIPT_DIR${RESET}"
        fi
    else
        echo -e "${VERMELHO}Instale: pkg install qrencode${RESET}"
    fi
    press_enter
}

encurtar_url() {
    echo -n "${AMARELO}URL: ${RESET}"
    read -r url
    local short
    short=$(api_get "https://tinyurl.com/api-create.php?url=$(url_encode "$url")")
    if [[ -n "$short" ]]; then
        echo -e "${AMARELO}Original:${RESET} $url"
        echo -e "${AMARELO}Curta:${RESET} $short"
    else
        echo -e "${VERMELHO}Erro ao encurtar.${RESET}"
    fi
    press_enter
}

meu_user_agent() {
    local ua
    ua=$(api_get "https://httpbin.org/user-agent")
    if [[ -n "$ua" ]]; then
        echo "$ua" | python3 -c "import sys,json; print('User-Agent: ' + json.load(sys.stdin).get('user-agent',''))" 2>/dev/null
    else
        echo -e "${VERMELHO}Nao foi possivel.${RESET}"
    fi
    press_enter
}

ping_teste() {
    echo -n "${AMARELO}Alvo (padrao google.com): ${RESET}"
    read -r alvo
    alvo="${alvo:-google.com}"
    echo -e "${CIANO}Testando $alvo...${RESET}"
    ping -c 3 "$alvo" 2>&1 | tail -3
    press_enter
}

email_hibp() {
    echo -n "${AMARELO}E-mail: ${RESET}"
    read -r em
    echo -e "${CIANO}Verifique: https://haveibeenpwned.com/account/$em${RESET}"
    if is_termux; then
        echo -n "${AMARELO}Abrir no navegador? (s/N): ${RESET}"
        read -r ab
        [[ "$ab" == "s" || "$ab" == "S" ]] && termux-open-url "https://haveibeenpwned.com/account/$em" 2>/dev/null
    fi
    press_enter
}

ferramentas_extras() {
    while true; do
        banner
        echo -e "${CIANO}─────────────────────────────────────────────${RESET}"
        echo -e "  ${VERDE}FERRAMENTAS EXTRAS${RESET}"
        echo -e "${CIANO}─────────────────────────────────────────────${RESET}"
        echo ""
        echo -e "  ${AMARELO}[1]${RESET}  Info do sistema"
        echo -e "  ${AMARELO}[2]${RESET}  Gerador de senhas"
        echo -e "  ${AMARELO}[3]${RESET}  Gerador de hash"
        echo -e "  ${AMARELO}[4]${RESET}  Base64 encode/decode"
        echo -e "  ${AMARELO}[5]${RESET}  QR Code"
        echo -e "  ${AMARELO}[6]${RESET}  Encurtar URL (TinyURL)"
        echo -e "  ${AMARELO}[7]${RESET}  Meu User-Agent"
        echo -e "  ${AMARELO}[8]${RESET}  Ping / conectividade"
        echo -e "  ${AMARELO}[9]${RESET}  Vazamento de email (HIBP)"
        echo -e "  ${AMARELO}[10]${RESET} Reverse geocode (lat,lon)"
        echo -e "  ${AMARELO}[0]${RESET}  Voltar"
        echo ""
        echo -n "${VERDE}> Escolha: ${RESET}"
        read -r sub
        case $sub in
            0) return ;;
            1) info_sistema ;;
            2) gerar_senha ;;
            3) gerar_hash ;;
            4) menu_base64 ;;
            5) menu_qrcode ;;
            6) encurtar_url ;;
            7) meu_user_agent ;;
            8) ping_teste ;;
            9) email_hibp ;;
            10) reverse_geocode_menu ;;
            *) echo -e "${VERMELHO}Invalido!${RESET}"; sleep 1 ;;
        esac
    done
}

# ============================================================
# BUSCAR IP (usa ip_consulta.py)
# ============================================================
buscar_ip_menu() {
    banner
    section "GEOLOCALIZACAO POR IP"
    echo -n "${AMARELO}IP ou Enter para o seu IP: ${RESET}"
    read -r ip
    echo -e "${CIANO}Consultando...${RESET}"
    if [[ -z "$ip" ]]; then
        python3 "$SCRIPT_DIR/ip_consulta.py"
    else
        python3 "$SCRIPT_DIR/ip_consulta.py" "$ip"
    fi
    salvar_historico "IP: ${ip:-meu ip}"
    press_enter
}

# ============================================================
# MENU PRINCIPAL (loop - sem recursao)
# ============================================================
menu() {
    while true; do
        banner
        echo -e "${CIANO}───────────────────────────────────────────────${RESET}"
        echo -e "  ${VERDE}MENU PRINCIPAL${RESET}"
        echo -e "${CIANO}───────────────────────────────────────────────${RESET}"
        echo ""
        echo -e "  ${AMARELO}[1]${RESET}  Buscar IP (rua, CEP, ISP, ASN, proxy/VPN)"
        echo -e "  ${AMARELO}[2]${RESET}  Dados de Telefone (DDD + cidades)"
        echo -e "  ${AMARELO}[3]${RESET}  Veiculo (preco FIPE por codigo)"
        echo -e "  ${AMARELO}[4]${RESET}  CNPJ (BrasilAPI - Receita)"
        echo -e "  ${AMARELO}[5]${RESET}  CPF (validacao + UF)"
        echo -e "  ${AMARELO}[6]${RESET}  Buscar Dominio (DNS + WHOIS)"
        echo -e "  ${AMARELO}[7]${RESET}  Buscar Nome (Dorking)"
        echo -e "  ${AMARELO}[8]${RESET}  Redes Sociais (username + check)"
        echo -e "  ${AMARELO}[9]${RESET}  Consultar E-mail (MX, Gravatar, HIBP)"
        echo -e "  ${AMARELO}[10]${RESET} CEP (ViaCEP)"
        echo -e "  ${AMARELO}[11]${RESET} CPF Completo (Selenium - Linux)"
        echo -e "  ${AMARELO}[12]${RESET} Banco (codigo/ISPB) [NEW]"
        echo -e "  ${AMARELO}[13]${RESET} DDD + cidades [NEW]"
        echo -e "  ${AMARELO}[14]${RESET} Cotacoes (Dolar, EUR, BTC) [NEW]"
        echo -e "  ${AMARELO}[15]${RESET} Rastrear encomenda [NEW]"
        echo -e "  ${AMARELO}[16]${RESET} Feriados nacionais [NEW]"
        echo -e "  ${AMARELO}[17]${RESET} Certificado SSL [NEW]"
        echo -e "  ${AMARELO}[18]${RESET} WHOIS via RDAP [NEW]"
        echo -e "  ${AMARELO}[19]${RESET} Detector de hash [NEW]"
        echo -e "  ${AMARELO}[20]${RESET} Scanner de portas [NEW]"
        echo -e "  ${AMARELO}[21]${RESET} Modo AUTO (--target) [NEW]"
        echo -e "  ${AMARELO}[22]${RESET} Consulta em lote (arquivo) [NEW]"
        echo -e "  ${AMARELO}[23]${RESET} Historico de consultas"
        echo -e "  ${AMARELO}[24]${RESET} Atualizar painel (git pull)"
        echo -e "  ${AMARELO}[25]${RESET} Ferramentas Extras"
        echo -e "  ${AMARELO}[0]${RESET}  Sair"
        echo ""
        echo -n "${VERDE}> Escolha: ${RESET}"
        read -r op
        case $op in
            0) exit 0 ;;
            1) buscar_ip_menu ;;
            2) buscar_telefone ;;
            3) buscar_veiculo ;;
            4) buscar_cnpj ;;
            5) validar_cpf ;;
            6) buscar_dominio ;;
            7) buscar_nome ;;
            8) redes_sociais ;;
            9) consultar_email ;;
            10) buscar_cep ;;
            11) cpf_completo_menu ;;
            12) consultar_banco ;;
            13) buscar_ddd ;;
            14) cotacoes ;;
            15) rastrear ;;
            16) feriados ;;
            17) ssl_certificado ;;
            18) rdap_whois ;;
            19) detectar_hash ;;
            20) scanner_portas ;;
            21) modo_target ;;
            22) consulta_lote ;;
            23) historico_menu ;;
            24) atualizar_painel ;;
            25) ferramentas_extras ;;
            *) echo -e "${VERMELHO}Invalido!${RESET}"; sleep 1 ;;
        esac
    done
}

# ============================================================
cli_fipe() {
    local cod="$1"
    local data
    data=$(api_get "https://brasilapi.com.br/api/fipe/preco/v1/$cod")
    if echo "$data" | python3 -c "import sys,json; d=json.load(sys.stdin); exit(0 if (isinstance(d,list) and d) else 1)" 2>/dev/null; then
        echo "$data" | python3 -c "
import sys, json
d = json.load(sys.stdin)
if isinstance(d, list): d = d[0]
for k, v in d.items():
    print('  %s: %s' % (k, v))
" 2>/dev/null
        return 0
    fi
    # Distingue: fonte fora do ar vs codigo invalido
    if echo "$data" | python3 -c "import sys,json; d=json.load(sys.stdin); exit(0 if 'message' in d else 1)" 2>/dev/null; then
        echo -e "${AMARELO}API FIPE indisponivel no momento (fonte externa). Tente de novo em instantes.${RESET}"
    else
        echo -e "${VERMELHO}Codigo FIPE invalido.${RESET}"
    fi
    return 1
}

buscar_veiculo_cli() {
    cli_fipe "$1"
    exit 0
}
# CLI PARSING
# ============================================================
case "$1" in
    --help|-h)     show_help ;;
    --ip)          salvar_historico "IP: $2"; python3 "$SCRIPT_DIR/ip_consulta.py" "$2" ;;
    --cnpj)        cli_cnpj "$2" ;;
    --cep)         cli_cep "$2" ;;
    --cpf)         cli_cpf "$2" ;;
    --fipe|--veiculo) buscar_veiculo_cli "$2" ;;
    --dominio)     cli_dominio "$2" ;;
    --email)       cli_email "$2" ;;
    --telefone)    tel=$(echo "$2" | tr -d ' +-'); echo "Telefone: +$tel"; echo "DDD: ${tel:2:2}"; consultar_ddd "${tel:2:2}" ;;
    --redes)       for site in "https://www.instagram.com/$2" "https://twitter.com/$2" "https://github.com/$2" "https://www.tiktok.com/@$2" "https://t.me/$2"; do
                       code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "$site" 2>/dev/null)
                       [[ "$code" != "000" && "$code" != "404" ]] && echo "[HTTP $code] $site"
                   done ;;
    --tempo)       curl -s --max-time 15 "wttr.in/$2?m&lang=pt" 2>/dev/null | head -15 ;;
    --banco)       cli_banco "$2" ;;
    --ddd)         consultar_ddd "$2" ;;
    --cotacoes)    cli_cotacoes ;;
    --rastreio)    cli_rastreio "$2" ;;
    --feriados)    cli_feriados "${2:-$(date +%Y)}" ;;
    --ssl)         cli_ssl "$2" ;;
    --rdap)        cli_rdap "$2" ;;
    --portas)      cli_portas "$2" ;;
    --target)      cli_target "$2" ;;
    --historico)   tail -30 "$HIST_FILE" 2>/dev/null || echo "Historico vazio" ;;
    --update)      atualizar_painel ;;
    "")            menu ;;
    *)             echo "Opcao invalida: $1"; show_help ;;
esac

# ============================================================
# REVERSE GEOCODE (lat,lon -> endereco)
# ============================================================
cli_geocode() {
    local lat="$1" lon="$2"
    local url="https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=$lat&lon=$lon&accept-language=pt-BR&zoom=18"
    local data
    data=$(curl -s --max-time 12 -A "cybertrace-panel/2.4 (ClubeDoTermux)" "$url" 2>/dev/null)
    if echo "$data" | python3 -c "import sys,json; d=json.load(sys.stdin); exit(0 if d.get('display_name') else 1)" 2>/dev/null; then
        echo "$data" | python3 -c "
import sys, json
d = json.load(sys.stdin)
a = d.get('address', {})
print('=' * 60)
print('  Endereco : %s' % d.get('display_name',''))
print('=' * 60)
print('  Rua      : %s %s' % (a.get('road',''), a.get('house_number','')))
print('  Bairro   : %s' % a.get('neighbourhood', a.get('suburb','')))
print('  Cidade   : %s' % a.get('city', a.get('town','')))
print('  Estado   : %s' % a.get('state',''))
print('  CEP      : %s' % a.get('postcode',''))
print('=' * 60)
" 2>/dev/null
        return 0
    fi
    return 1
}

reverse_geocode_menu() {
    echo -n "${AMARELO}Latitude (ex: -23.5505): ${RESET}"
    read -r lat
    echo -n "${AMARELO}Longitude (ex: -46.6333): ${RESET}"
    read -r lon
    if ! [[ "$lat" =~ ^-?[0-9.]+$ ]] || ! [[ "$lon" =~ ^-?[0-9.]+$ ]]; then
        echo -e "${VERMELHO}Coordenadas invalidas.${RESET}"
        press_enter
        return
    fi
    echo -e "${CIANO}Consultando OpenStreetMap...${RESET}"
    if cli_geocode "$lat" "$lon"; then
        salvar_historico "geocode: $lat,$lon"
    else
        echo -e "${VERMELHO}Nao foi possivel reverter as coordenadas.${RESET}"
    fi
    press_enter
}
