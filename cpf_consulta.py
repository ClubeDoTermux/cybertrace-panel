#!/usr/bin/env python3
"""CYBERTRACE - Consulta CPF (situacao-cadastral.com)
Requer: pip install selenium webdriver-manager beautifulsoup4
Requer: Google Chrome ou Chromium instalado
"""

import sys
import os
import time
import json

try:
    from selenium import webdriver
    from selenium.webdriver.common.by import By
    from selenium.webdriver.chrome.service import Service
    from selenium.webdriver.chrome.options import Options
    from webdriver_manager.chrome import ChromeDriverManager
    from bs4 import BeautifulSoup
except ImportError:
    print("ERRO: Instale as dependencias:")
    print("  pip install selenium webdriver-manager beautifulsoup4")
    sys.exit(1)

def consultar_cpf(cpf):
    options = Options()
    options.add_argument("--headless=new")
    options.add_argument("--no-sandbox")
    options.add_argument("--disable-dev-shm-usage")
    options.add_argument("--disable-blink-features=AutomationControlled")
    options.add_argument("user-agent=Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36")

    try:
        service = Service(ChromeDriverManager().install())
        driver = webdriver.Chrome(service=service, options=options)
    except Exception as e:
        print(f"ERRO ao iniciar Chrome: {e}")
        print("Certifique-se de ter o Google Chrome/Chromium instalado")
        sys.exit(1)

    result = {"cpf": cpf, "erro": None}

    try:
        driver.get("https://www.situacao-cadastral.com/")
        time.sleep(2)

        campo = driver.find_element(By.ID, "doc")
        campo.send_keys(cpf)
        driver.find_element(By.ID, "consultar").click()
        time.sleep(3)

        soup = BeautifulSoup(driver.page_source, "html.parser")
        spans = soup.find_all("span", class_=lambda c: c and "dados" in str(c))

        for span in spans:
            classes = " ".join(span.get("class", []))
            texto = span.text.strip()
            if texto:
                result[classes.replace("dados ", "")] = texto

        # Se não achou spans, pega todo texto
        if len(result) <= 1:
            texto = soup.get_text().strip()
            for linha in texto.split("\n"):
                linha = linha.strip()
                if ":" in linha and linha[0].isupper():
                    chave, _, valor = linha.partition(":")
                    result[chave.strip()] = valor.strip()

    except Exception as e:
        result["erro"] = str(e)
    finally:
        driver.quit()

    return result

if __name__ == "__main__":
    cpf = sys.argv[1] if len(sys.argv) > 1 else input("CPF: ")
    cpf = "".join(c for c in cpf if c.isdigit())

    if len(cpf) != 11:
        print("CPF invalido (11 digitos)")
        sys.exit(1)

    print(f"Consultando CPF {cpf}...")
    resultado = consultar_cpf(cpf)

    print("\n" + "=" * 50)
    print("RESULTADO DA CONSULTA")
    print("=" * 50)
    for chave, valor in resultado.items():
        print(f"{chave}: {valor}")
    print("=" * 50)
