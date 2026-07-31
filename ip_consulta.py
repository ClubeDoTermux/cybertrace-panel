#!/usr/bin/env python3
# =============================================
# ip_consulta.py - Consulta detalhada de IP
# Parte do Cybertrace Panel (ClubeDoTermux)
#
# Fontes:
#   ip-api.com     -> geolocalização base + proxy/VPN/hosting
#   Nominatim/OSM  -> reverse geocoding (rua, bairro, CEP)
#   ViaCEP         -> detalhes do CEP brasileiro (logradouro, DDD...)
#
# Uso:
#   python3 ip_consulta.py [IP] [--plain]
#   Sem IP  -> usa seu próprio IP (ifconfig.me)
#   --plain -> saída simples sem cores (modo CLI)
# =============================================
import json
import re
import sys
import urllib.request

# Cores (mesmas do cybertrace.sh)
VERDE = "\033[1;32m"
VERMELHO = "\033[1;31m"
AMARELO = "\033[1;33m"
CIANO = "\033[1;36m"
RESET = "\033[0m"

UA = "cybertrace-panel/2.2 (ClubeDoTermux; https://github.com/ClubeDoTermux/cybertrace-panel)"
TIMEOUT = 10

IP_API_FIELDS = (
    "status,message,country,countryCode,region,regionName,city,district,zip,"
    "lat,lon,timezone,isp,org,as,asname,reverse,mobile,proxy,hosting,query"
)


def http_get(url, plain=False):
    """Faz GET e retorna o texto da resposta (ou '' em erro)."""
    try:
        req = urllib.request.Request(url, headers={"User-Agent": UA})
        with urllib.request.urlopen(req, timeout=TIMEOUT) as resp:
            return resp.read().decode("utf-8", "replace")
    except Exception:
        return ""


def api_json(url, plain=False):
    """Faz GET e tenta parsear JSON (ou {} em erro)."""
    try:
        return json.loads(http_get(url))
    except Exception:
        return {}


def format_cep(cep):
    """Mascara CEP: 01310100 -> 01310-100"""
    cep = re.sub(r"\D", "", str(cep))
    if len(cep) == 8:
        return f"{cep[:5]}-{cep[5:]}"
    return cep


def get_own_ip():
    ip = http_get("http://ifconfig.me").strip()
    if re.match(r"^\d{1,3}(\.\d{1,3}){3}$", ip):
        return ip
    return ""


def reverse_geocode(lat, lon):
    """Nominatim (OpenStreetMap): lat/lon -> endereço detalhado."""
    if not lat or not lon:
        return {}
    url = (
        f"https://nominatim.openstreetmap.org/reverse?format=jsonv2"
        f"&lat={lat}&lon={lon}&accept-language=pt-BR&zoom=18"
    )
    data = api_json(url)
    if not data or data.get("error"):
        return {}
    return data


def viacep(cep):
    """ViaCEP: detalhes do CEP brasileiro (logradouro, bairro, DDD...)."""
    cep_digits = re.sub(r"\D", "", str(cep))
    if len(cep_digits) != 8:
        return {}
    data = api_json(f"https://viacep.com.br/ws/{cep_digits}/json/")
    if not data or data.get("erro"):
        return {}
    return data


def pick(*values):
    """Primeiro valor não vazio (limpo)."""
    for v in values:
        if v:
            v = str(v).strip()
            if v and v.lower() not in ("", "none", "null"):
                return v
    return ""


def asn_line(data):
    """ASN + nome, evitando duplicação quando o nome repete ISP/Org."""
    asn = data.get("as", "")
    nome = data.get("asname", "")
    if nome and nome.lower() not in (str(data.get("isp", "")).lower(),
                                     str(data.get("org", "")).lower()):
        return f"{asn} {nome}".rstrip()
    return asn


def main():
    plain = "--plain" in sys.argv
    ip = next((a for a in sys.argv[1:] if a != "--plain"), "")

    if not ip:
        ip = get_own_ip()
        if not ip:
            print("Nao foi possivel descobrir seu IP")
            sys.exit(1)

    # 1) Geolocalização base (ip-api.com)
    data = api_json(f"http://ip-api.com/json/{ip}?fields={IP_API_FIELDS}")
    if not data or data.get("status") != "success":
        msg = data.get("message", "IP invalido ou nao encontrado") if data else "Sem resposta da API"
        print(f"ERRO: {msg}")
        sys.exit(1)

    lat, lon = data.get("lat"), data.get("lon")
    country_code = data.get("countryCode", "")

    # 2) Reverse geocoding (rua, bairro, CEP via OpenStreetMap)
    geo = reverse_geocode(lat, lon)
    addr = geo.get("address", {})

    # 3) ViaCEP quando o IP é brasileiro
    vc = {}
    cep = format_cep(pick(addr.get("postcode"), data.get("zip")))
    if country_code == "BR" and cep:
        vc = viacep(cep)
        cep = format_cep(pick(vc.get("cep"), cep))

    # ---- Monta os campos ----
    rua = pick(addr.get("road"), addr.get("pedestrian"), addr.get("footway"),
               vc.get("logradouro"))
    numero = pick(addr.get("house_number"), addr.get("address29"))
    bairro = pick(addr.get("neighbourhood"), addr.get("suburb"),
                  addr.get("quarter"), addr.get("city_district"), vc.get("bairro"))
    cidade = pick(addr.get("city"), addr.get("town"), addr.get("village"),
                  addr.get("municipality"), data.get("city"), vc.get("localidade"))
    estado = pick(addr.get("state"), data.get("regionName"))
    uf = pick(addr.get("state_code"), data.get("region"))

    lat_lon = f"{lat}, {lon}" if lat and lon else ""
    mapa = f"https://www.google.com/maps?q={lat},{lon}" if lat and lon else ""

    if plain:
        # ---------- MODO CLI (sem cores) ----------
        print(f"IP: {data.get('query', ip)}")
        print(f"Pais: {data.get('country', '')} ({country_code})")
        print(f"Cidade: {cidade} - {estado} ({uf})")
        if data.get("district"):
            print(f"Distrito: {data['district']}")
        if rua:
            print(f"Rua: {rua}{' - Nº ' + numero if numero else ''}")
        if bairro:
            print(f"Bairro: {bairro}")
        if cep:
            print(f"CEP: {cep}")
        if vc:
            print(f"Complemento: {vc.get('complemento', '')}")
            print(f"DDD: {vc.get('ddd', '')}")
        if lat_lon:
            print(f"Coordenadas: {lat_lon}")
            print(f"Mapa: {mapa}")
        if data.get("timezone"):
            print(f"Fuso: {data['timezone']}")
        if data.get("isp"):
            print(f"ISP: {data['isp']}")
        if data.get("org"):
            print(f"Organizacao: {data['org']}")
        if data.get("as"):
            print(f"ASN: {asn_line(data)}")
        if data.get("reverse"):
            print(f"PTR (hostname): {data['reverse']}")
        if data.get("proxy"):
            print("Proxy/VPN: SIM")
        if data.get("mobile"):
            print("Rede movel: SIM")
        if data.get("hosting"):
            print("Hosting/Datacenter: SIM")
        print("Aviso: localizacao aproximada (nivel ISP)")
        sys.exit(0)

    # ---------- MODO MENU (com cores) ----------
    print(f"{VERDE}════════════════════════════════════════════{RESET}")
    print(f"{AMARELO}🌍 IP:{RESET} {data.get('query', ip)}")
    print(f"{AMARELO}📍 País:{RESET} {data.get('country', '')} ({country_code})")
    print(f"{AMARELO}🏙️ Cidade:{RESET} {cidade} - {estado} ({uf})")
    if data.get("district"):
        print(f"{AMARELO}🗺️ Distrito:{RESET} {data['district']}")
    if rua:
        print(f"{AMARELO}🛣️ Rua:{RESET} {rua}{' - Nº ' + numero if numero else ''}")
    if bairro:
        print(f"{AMARELO}🏘️ Bairro:{RESET} {bairro}")
    if cep:
        print(f"{AMARELO}📮 CEP:{RESET} {cep}")
    if vc:
        if vc.get("complemento"):
            print(f"{AMARELO}➕ Complemento:{RESET} {vc['complemento']}")
        print(f"{AMARELO}📞 DDD:{RESET} {vc.get('ddd', '')}")
    if lat_lon:
        print(f"{AMARELO}🌐 Coord:{RESET} {lat_lon}")
    if data.get("timezone"):
        print(f"{AMARELO}🕐 TZ:{RESET} {data['timezone']}")
    if data.get("isp"):
        print(f"{AMARELO}🏢 ISP:{RESET} {data['isp']}")
    if data.get("org"):
        print(f"{AMARELO}📡 Org:{RESET} {data['org']}")
    if data.get("as"):
        print(f"{AMARELO}🔗 ASN:{RESET} {asn_line(data)}")
    if data.get("reverse"):
        print(f"{AMARELO}🔁 PTR:{RESET} {data['reverse']}")
    if data.get("proxy"):
        print(f"{VERMELHO}🛡️ Proxy/VPN:{RESET} SIM")
    if data.get("mobile"):
        print(f"{AMARELO}📱 Rede móvel:{RESET} SIM")
    if data.get("hosting"):
        print(f"{AMARELO}☁️  Hosting/Datacenter:{RESET} SIM")
    if mapa:
        print(f"{AMARELO}🗺️ Mapa:{RESET} {mapa}")
    print(f"{CIANO}ℹ️  Localização aproximada (nível ISP), não é a casa exata.{RESET}")


if __name__ == "__main__":
    main()
