#!/usr/bin/env python3
"""CYBERTRACE v2.1 - Consulta CPF (situacao-cadastral.com)
Requer: pip install selenium webdriver-manager beautifulsoup4
Requer: Google Chrome ou Chromium instalado
"""

import sys
import time
import re
import json

try:
    from selenium import webdriver
    from selenium.webdriver.common.by import By
    from selenium.webdriver.chrome.service import Service
    from selenium.webdriver.chrome.options import Options
    from selenium.common.exceptions import TimeoutException, WebDriverException
    from webdriver_manager.chrome import ChromeDriverManager
    from bs4 import BeautifulSoup
except ImportError as e:
    print("\nERRO: Dependência faltando:", e)
    print("  pip install selenium webdriver-manager beautifulsoup4\n")
    sys.exit(1)


def formatar_cpf(cpf: str) -> str:
    return f"{cpf[:3]}.{cpf[3:6]}.{cpf[6:9]}-{cpf[9:]}"


def validar_digitos_cpf(cpf: str) -> bool:
    if len(cpf) != 11 or not cpf.isdigit():
        return False
    d1, d2 = int(cpf[9]), int(cpf[10])
    r1 = (sum(int(cpf[i]) * (10 - i) for i in range(9)) * 10) % 11
    r2 = (sum(int(cpf[i]) * (11 - i) for i in range(10)) * 10) % 11
    if r1 == 10: r1 = 0
    if r2 == 10: r2 = 0
    return r1 == d1 and r2 == d2


def consultar_cpf(cpf: str) -> dict:
    options = Options()
    options.add_argument("--headless=new")
    options.add_argument("--no-sandbox")
    options.add_argument("--disable-dev-shm-usage")
    options.add_argument("--disable-gpu")
    options.add_argument("--disable-blink-features=AutomationControlled")
    options.add_argument(
        "user-agent=Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
        "AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
    )
    options.add_experimental_option("excludeSwitches", ["enable-automation"])
    options.add_experimental_option("useAutomationExtension", False)

    result = {"cpf": formatar_cpf(cpf), "valido": validar_digitos_cpf(cpf)}

    try:
        print("  Iniciando Chrome...")
        service = Service(ChromeDriverManager().install())
        driver = webdriver.Chrome(service=service, options=options)
        driver.execute_script(
            "Object.defineProperty(navigator, 'webdriver', {get: () => undefined})"
        )
    except Exception as e:
        result["erro"] = f"Chrome: {e}"
        return result

    try:
        print("  Acessando situacao-cadastral.com...")
        driver.set_page_load_timeout(30)
        driver.get("https://www.situacao-cadastral.com/")
        time.sleep(2)

        campo = driver.find_element(By.ID, "doc")
        campo.clear()
        campo.send_keys(cpf)

        driver.find_element(By.ID, "consultar").click()
        time.sleep(4)

        soup = BeautifulSoup(driver.page_source, "html.parser")

        for tabela in soup.find_all("table"):
            for row in tabela.find_all("tr"):
                cols = row.find_all(["td", "th"])
                if len(cols) >= 2:
                    chave = cols[0].get_text(strip=True)
                    valor = cols[1].get_text(strip=True)
                    if chave and valor:
                        result[chave] = valor

        spans = soup.find_all("span", class_=lambda c: c and "dados" in str(c))
        for span in spans:
            classes = " ".join(span.get("class", []))
            texto = span.text.strip()
            if texto:
                chave = classes.replace("dados ", "").strip()
                result[chave] = texto

        if len(result) <= 2:
            texto = soup.get_text()
            for linha in texto.split("\n"):
                linha = linha.strip()
                if ":" in linha and linha[0].isupper():
                    chave, _, valor = linha.partition(":")
                    result[chave.strip()] = valor.strip()

    except TimeoutException:
        result["erro"] = "Timeout ao carregar página"
    except WebDriverException as e:
        result["erro"] = f"Erro Chrome: {e}"
    except Exception as e:
        result["erro"] = str(e)
    finally:
        try:
            driver.quit()
        except Exception:
            pass

    return result


def limpar_resultado(result: dict) -> dict:
    chaves_mapa = {
        "cpf": "CPF",
        "nome": "Nome",
        "Nome": "Nome",
        "nascimento": "Nascimento",
        "Nascimento": "Nascimento",
        "situação": "Situação Cadastral",
        "Situação Cadastral": "Situação Cadastral",
        "Situação": "Situação Cadastral",
        "Situacao Cadastral": "Situação Cadastral",
        "mãe": "Nome da Mãe",
        "Mãe": "Nome da Mãe",
        "Nome da Mãe": "Nome da Mãe",
        "valido": "CPF Válido",
        "erro": "Erro",
    }
    limpo = {}
    for k, v in result.items():
        chave = chaves_mapa.get(k, k)
        limpo[chave] = v
    return limpo


def exibir_resultado(result: dict):
    print("\n" + "=" * 55)
    print("  RESULTADO DA CONSULTA")
    print("=" * 55)
    if result.get("erro"):
        print(f"\n  ERRO: {result['erro']}")
        print("\n  Dicas:")
        print("  • Verifique se o Chrome/Chromium está instalado")
        print("  • pip install selenium webdriver-manager beautifulsoup4")
        print("  • Tente executar sem headless (remova --headless=new)")
    else:
        for chave in ["CPF", "CPF Válido", "Nome", "Nascimento",
                       "Situação Cadastral", "Nome da Mãe"]:
            if chave in result:
                valor = result[chave]
                if chave == "CPF Válido":
                    status = "✓ Sim" if valor else "✗ Não"
                    print(f"  {chave:25}: {status}")
                else:
                    print(f"  {chave:25}: {valor}")

        extras = {k: v for k, v in result.items()
                   if k not in ["cpf", "CPF", "valido", "CPF Válido",
                                "Nome", "Nascimento", "Situação Cadastral",
                                "Nome da Mãe", "erro"]}
        if extras:
            print(f"\n  {'─' * 50}")
            for k, v in extras.items():
                print(f"  {k:25}: {v}")
    print("=" * 55)


if __name__ == "__main__":
    if len(sys.argv) > 1:
        cpf = "".join(c for c in sys.argv[1] if c.isdigit())
    else:
        cpf = input("CPF: ").strip()
        cpf = "".join(c for c in cpf if c.isdigit())

    if len(cpf) != 11:
        print("ERRO: CPF deve ter 11 dígitos")
        sys.exit(1)

    print(f"\n  Consultando CPF {formatar_cpf(cpf)}...\n")
    resultado = consultar_cpf(cpf)
    resultado_limpo = limpar_resultado(resultado)
    exibir_resultado(resultado_limpo)
