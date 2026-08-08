# Cybertrace Panel v2.4

Painel de Investigação Digital com consultas a APIs públicas reais.

![Cybertrace Panel Demo](demo.png)

## Menu

```
[1]  Buscar IP            (rua, bairro, CEP, DDD, ISP, ASN, proxy/VPN)
[2]  Dados de Telefone    (DDD dinâmico + cidades via BrasilAPI)
[3]  Veículo              (preço FIPE por código)
[4]  CNPJ                 (BrasilAPI - Receita Federal)
[5]  CPF                  (validação de dígitos + UF)
[6]  Buscar Domínio       (DNS + MX + NS + TXT + WHOIS)
[7]  Buscar Nome          (Google Dorking - 10+ plataformas)
[8]  Redes Sociais        (24 plataformas + HTTP check)
[9] Consultar E-mail     (MX, NS, Gravatar, HIBP, Hunter.io)
[10] CEP                  (ViaCEP - rua, bairro, cidade)
[11] CPF Completo         (Selenium - requer Chrome, só Linux)
[12] Banco                (código/ISPB via BrasilAPI)        [NOVO]
[13] DDD + cidades        (BrasilAPI)                        [NOVO]
[14] Cotações             (Dólar, Euro, BTC - AwesomeAPI)    [NOVO]
[15] Rastrear encomenda   (Correios via Linketrack)          [NOVO]
[16] Feriados nacionais   (BrasilAPI)                        [NOVO]
[17] Certificado SSL      (expiração via openssl)            [NOVO]
[18] WHOIS via RDAP       (JSON - Verisign/registro.br)      [NOVO]
[19] Detector de hash     (identifica MD5/SHA1/SHA256/...)   [NOVO]
[20] Scanner de portas    (21, 22, 80, 443, 3306, 8080...)  [NOVO]
[21] Modo AUTO --target   (detecta o tipo e consulta)        [NOVO]
[22] Consulta em lote     (arquivo de alvos)                 [NOVO]
[23] Histórico            (log automático + exportação)      [NOVO]
[24] Atualizar painel     (git pull)                         [NOVO]
[25] Ferramentas Extras   (10 utilitários)
[0]  Sair
```

## Instalação

### Termux (recomendado)

```bash
pkg update && pkg upgrade -y
bash install.sh
bash cybertrace.sh
```

### Linux (Debian/Ubuntu)

```bash
sudo apt update
bash install.sh --linux
bash cybertrace.sh
```

### Manual

```bash
pkg install -y curl python3 git dnsutils openssl-tool qrencode
git clone https://github.com/ClubeDoTermux/cybertrace-panel.git
cd cybertrace-panel
bash cybertrace.sh
```

## Uso via terminal (sem menu)

```bash
bash cybertrace.sh --help
bash cybertrace.sh --ip 8.8.8.8
bash cybertrace.sh --cnpj 19131243000197
bash cybertrace.sh --cep 01310000
bash cybertrace.sh --cpf 52998224725
bash cybertrace.sh --dominio google.com
bash cybertrace.sh --email contato@exemplo.com
bash cybertrace.sh --telefone 5511999999999
bash cybertrace.sh --tempo "Sao+Paulo"
bash cybertrace.sh --redes clubbedotermux
bash cybertrace.sh --banco 341
bash cybertrace.sh --ddd 11
bash cybertrace.sh --fipe 001004-0
bash cybertrace.sh --cotacoes
bash cybertrace.sh --rastreio LU123456789BR
bash cybertrace.sh --feriados 2026
bash cybertrace.sh --ssl google.com
bash cybertrace.sh --rdap github.com
bash cybertrace.sh --portas 8.8.8.8
bash cybertrace.sh --target 52998224725
bash cybertrace.sh --historico
```

## Rastreio de encomenda

A API Linketrack é gratuita mas o modo demo (teste/teste) é limitado.
Para uso real, cadastre-se em https://linketrack.com e exporte as credenciais:

```bash
export LINKETRACK_USER=seu_usuario
export LINKETRACK_TOKEN=seu_token
bash cybertrace.sh --rastreio 000123456789BR
```

## CPF Completo (opção 11)

Requer Chrome desktop + dependências (não funciona no Termux):

```bash
pip install selenium webdriver-manager beautifulsoup4
python3 cpf_consulta.py SEU_CPF
```

## APIs utilizadas

| API | Dados | Grátis |
|-----|-------|--------|
| [ip-api.com](http://ip-api.com) | Geolocalização de IP + proxy/VPN/hosting | ✅ |
| [Nominatim/OSM](https://nominatim.openstreetmap.org) | Reverse geocoding: rua, bairro, CEP | ✅ |
| [BrasilAPI](https://brasilapi.com.br) | CNPJ, FIPE, DDD, bancos, feriados | ✅ |
| [ViaCEP](https://viacep.com.br) | CEP (rua, bairro, cidade, DDD) | ✅ |
| [AwesomeAPI](https://economia.awesomeapi.com.br) | Cotações USD/EUR/BTC | ✅ |
| [Linketrack](https://linketrack.com) | Rastreio Correios | ✅ |
| [RDAP](https://rdap.org) | WHOIS em JSON (Verisign/.com) | ✅ |
| [wttr.in](https://wttr.in) | Previsão do tempo | ✅ |
| [TinyURL](https://tinyurl.com) | Encurtador de URL | ✅ |

## Novidades da v2.4

- 🟢 **Menu em loop** (sem recursão que crescia a pilha) — código mais limpo
- 🗺️ **DDD dinâmico**: tabela fixa de 130 linhas vira consulta à BrasilAPI com todas as cidades
- 🚗 **Veículo corrigido**: consulta por código FIPE (a antiga por placa não funcionava)
- 🏦 **Banco (ISPB)**: consulta nome/ISPB de qualquer banco brasileiro
- 💱 **Cotações em tempo real**: dólar, euro e bitcoin
- 📦 **Rastreio de encomendas** dos Correios (PAC/SEDEX)
- 🗓 **Feriados nacionais** de qualquer ano
- 🔐 **Certificado SSL**: data de expiração e emissor
- 📋 **WHOIS via RDAP**: JSON limpo, sem depender da ferramenta whois
- 🔑 **Detector de tipo de hash** (MD5, SHA1, SHA256, bcrypt, crypt...)
- 🖥 **Scanner de portas comuns** sem instalar nmap
- 🤖 **--target**: digite qualquer dado e a ferramenta decide a consulta
- 📦 **Consulta em lote**: processa arquivo inteiro de IPs/CEPs/CNPJs
- 🗂 **Histórico automático** de consultas em `.cybertrace_historico.log`
- 🔄 **git pull** integrado (opção 24 / --update)
- 💡 **Reverse geocode**: coordenadas → endereço completo (ferramentas extras [10])
- 📱 **Instalador dedicado** `install.sh` (Termux e Linux)
- 🌐 **Timeouts** em todos os comandos DNS/WHOIS — nada trava a consulta

## Aviso

Ferramenta para fins educacionais e consultas públicas. Dados pessoais (CPF completo, dono de veículo, telefone) são protegidos pela LGPD e não estão disponíveis em APIs públicas gratuitas.