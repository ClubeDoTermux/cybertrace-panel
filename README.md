# 🔍 Cybertrace Panel v2.0

Painel de Investigação Digital com consultas a APIs públicas reais.

## Menu

```
 1. 📍 Buscar IP          (ip-api.com)
 2. 📱 Dados de Telefone   (DDD, operadora, região)
 3. 🚗 Buscar Placa        (BrasilAPI/FIPE)
 4. 🆔 CNPJ                (BrasilAPI - Receita Federal)
 5. 📇 CPF                 (validação de dígitos + UF)
 6. 🌐 Buscar Domínio      (DNS + WHOIS)
 7. 🔍 Buscar Nome         (Google Dorking - 10+ plataformas)
 8. 👤 Redes Sociais       (26 plataformas + HTTP check)
 9. 📧 Consultar E-mail    (MX, Gravatar, HIBP)
10. 📮 CEP                 (ViaCEP - rua, bairro, cidade)
11. 🆔 CPF Completo        (Selenium - requer Chrome)
12. 🛠️ Ferramentas Extras  (QR Code, encurtar URL, etc.)
```

## Instalação Termux

```bash
pkg update && pkg upgrade -y
pkg install -y curl python3 git
git clone https://github.com/carlos46743/cybertrace-panel.git
cd cybertrace-panel
bash cybertrace.sh
```

## Instalação Linux (Debian/Ubuntu)

```bash
sudo apt update && sudo apt install -y curl python3 git dnsutils
git clone https://github.com/carlos46743/cybertrace-panel.git
cd cybertrace-panel
bash cybertrace.sh
```

## Uso via terminal (sem menu)

```bash
bash cybertrace.sh --help
bash cybertrace.sh --ip 8.8.8.8
bash cybertrace.sh --cnpj 00000000000191
bash cybertrace.sh --cep 01310000
bash cybertrace.sh --cpf 52998224725
bash cybertrace.sh --placa ABC1234
```

## CPF Completo (opção 11)

Requer Chrome/Chromium + dependências Python:

```bash
pip install selenium webdriver-manager beautifulsoup4
bash cybertrace.sh
# Escolha a opção 11
```

## APIs utilizadas

| API | Dados | Grátis |
|-----|-------|--------|
| [ip-api.com](http://ip-api.com) | Geolocalização de IP | ✅ |
| [BrasilAPI](https://brasilapi.com.br) | CNPJ (Receita Federal), FIPE (veículos) | ✅ |
| [ViaCEP](https://viacep.com.br) | CEP (rua, bairro, cidade) | ✅ |
| [situacao-cadastral.com](https://www.situacao-cadastral.com) | CPF completo (via Selenium) | ✅ |

## Aviso

Ferramenta para fins educacionais e consultas públicas. Dados pessoais (CPF completo, dono de veículo, telefone) são protegidos pela LGPD e não estão disponíveis em APIs públicas gratuitas.
