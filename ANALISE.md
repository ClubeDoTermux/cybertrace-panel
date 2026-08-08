# ANÁLISE — Cybertrace Panel v2.3

Repositório: https://github.com/ClubeDoTermux/cybertrace-panel
Analisado em: 08/08/2026
Ambiente: Termux (Android 13)

Estrutura:
- cybertrace.sh       (1.072 linhas — menu, 12 opções, 12 ferramentas extras, CLI)
- ip_consulta.py      (244 linhas) — consulta de IP com ip-api + OSM + ViaCEP
- cpf_consulta.py     (193 linhas) — CPF completo via Selenium (situacao-cadastral.com)
- README.md, demo.png, .gitignore

Testes executados:
- bash -n cybertrace.sh ............ OK (sintaxe válida)
- bash cybertrace.sh --help ........ OK
- python3 ip_consulta.py 8.8.8.8 --plain ....... OK (dados reais: ASN, PTR, rua, CEP)

=================================================================
1. PONTOS FORTES
=================================================================
- Funciona! Consulta de IP é robusta: ip-api + Nominatim + ViaCEP com fallbacks.
- Bom uso de cores e visual CLI limpo (v2.3).
- CLI direta (--ip, --cnpj, --cep, ...) além do menu interativo.
- python3 para parse de JSON evita dependência de jq.
- User-Agent identificado nas APIs (educado com Nominatim).
- Avisos LGPD no README e na tela de CPF.
- Timeout em todas as requisições (10s).

=================================================================
2. BUGS / PROBLEMAS ENCONTRADOS
=================================================================
[BUG 1] Buscar Placa (opção 3) está QUEBRADA
- O endpoint usado é https://brasilapi.com.br/api/fipe/preco/v1/{PLACA}
- Esse endpoint espera CÓDIGO FIPE (ex: 001004-0), NÃO a placa.
- Teste real com ABC1234 retornou: "Fonte de dados FIPE temporariamente
  indisponível" (e mesmo quando disponível, não aceita placa).
- Resultado: a função quase sempre cai no fallback "API sem dados".
- Placas exigem dados do Detran (pagos). Recomendo: renomear para
  "Consulta FIPE (código)" OU informar claramente que dados de veículo
  por placa não são públicos no Brasil e virar um "guia/links Detran".

[BUG 2] Instalação automática do `dig` no Termux falha
- Linha 1064: `pkg install -y $cmd` — se falta `dig`, roda o pacote
  que se chama dnsutils. No Termux o pacote é dnsutils, não "dig".
  `pkg install -y dig` falha silenciosamente (2>/dev/null).
- Correção: mapear dig -> dnsutils (e curl -> curl, etc).

[BUG 3] Menu recursivo (stack cresce a cada consulta)
- `menu` chama funções que chamam `menu` de novo... recursão infinita.
- Em bash funciona por muito tempo, mas em sessões longas fica lento e
  consome memória. O padrão correto é `while true; do ...; done`.

[BUG 4] `loader()` (linhas 85-95) nunca é usada — código morto.

[BUG 5] Telegram duplicado na lista de redes sociais (opções 8)
- Aparece 2x (linhas 524 e 549). README diz "26 plataformas", mas a
  lista tem 24 únicas. Contagem errada.

[BUG 6] HTTP check de redes sociais gera falsos positivos
- wa.me/$user SEMPRE retorna 200 (não existe página de erro 404).
- Instagram redireciona para login e retorna 200 para perfis inexistentes.
- Resultado: "perfis existentes" com status errado. Mitigação: mostrar
  o código HTTP (já mostra) e avisar que 200 não garante existência.

[BUG 7] --telefone CLI é inferior ao menu
- O menu mostra estado + operadoras do DDD; o CLI `--telefone` só mostra
  DDD/numero/tipo. Inconsistência.

[BUG 8] cli_cnpj e cli_cep imprimem JSON bruto
- `[print(f'{k}: {v}')` para todas as chaves — até "qsa" (sócios) vira
  linha gigante de dicionário. O modo menu formata bem; o CLI não.

[BUG 9] Emoji restante na v2.3 (que prometeu "sem emojis")
- Linha 795: "⏰ Uptime" — restou 1 emoji.

[BUG 10] Sem tratamento de erros de rede
- Sem internet, TODAS as consultas falham silenciosamente (curl -s zera
  a saída). Deveria mostrar "[!] Sem conexão com a internet" uma vez.

[BUG 11] Opção 11 (CPF completo/Selenium) é impraticável no Termux
- Não existe Chrome desktop no Android. Selenium + webdriver_manager
  não roda de forma confiável. Recomendo detectar Termux e informar que
  a opção 11 só funciona no Linux.

[BUG 12] Navegador mínimo (código repetido)
- O bloco case de DDDs (linhas 178-315) é um case gigante de 130 linhas.
  A BrasilAPI tem /api/ddd/v1/{ddd} que retorna estado + TODAS as
  cidades do DDD (testado e funcionando!). Dá para apagar a tabela
  inteira e consultar dinâmico — e ainda ganha a lista de cidades.

=================================================================
3. MELHORIAS PRIORITÁRIAS
=================================================================
1. Corrigir placa (BUG 1) — ou vira consulta por código FIPE ou vira guia.
2. Loop `while` no menu em vez de recursão (BUG 3).
3. Tabela de DDD via API (BUG 12) — remove 130 linhas de case.
4. Corrigir instalação do dig (BUG 2).
5. Mensagem global de "sem internet".
6. --telefone CLI completo (BUG 7) e formatação do cli_cnpj/cli_cep (BUG 8).
7. Remover código morto (loader) e emoji (BUG 4/9).
8. Detectar Termux na opção 11 (BUG 11).
9. shellcheck no script (qualidade) — rodar `shellcheck cybertrace.sh`.
10. Criação de install.sh que instala TUDO (curl, python3, git, dnsutils,
    qrencode) de uma vez em Termux e Linux.

=================================================================
4. NOVAS FUNÇÕES SUGERIDAS (todas com API grátis testada)
=================================================================
Já testei as APIs marcadas com [TESTADO] — funcionam agora.

1) [13] Consultar Banco (ISPB) — BrasilAPI
   GET https://brasilapi.com.br/api/banks/v1/341 [TEST]
   -> nome do banco, ISPB, código. Ótimo para validação de PIX/boletos.

2) [14] DDD dinâmico + cidades — BrasilAPI
   GET https://brasilapi.com.br/api/ddd/v1/11 [TEST]
   -> UF + lista de cidades. Substitui o case gigante.

3) [15] Cotações (Dólar, Euro, BTC) — AwesomeAPI
   GET https://economia.awesomeapi.com.br/json/last/USD-BRL,EUR-BRL,BTC-BRL
   -> câmbio em tempo real. Muito procurado.

4. [16] Rastreio de PAC/Encomenda — API Linketrack ou rastreio gratuita
   POST https://linketrack.com/track/json?user=teste&token=teste&codigo=XXX
   -> status do Correio. (usar credenciais demo ou deixar usuário setar)

5. [17] Verificador de certificado SSL do domínio
   echo | openssl s_client -connect dominio:443 2>/dev/null | openssl x509 -noout -dates
   -> data de expiração — alerta antes de vencer.

6. [18] Expiração WHOIS via RDAP (JSON, sem depender de whois)
   GET https://rdap.org/domain/google.com
   -> JSON limpo, sem depender do comando whois.

7. [19] Hash type detector (identifica cheiro do hash)
   MD5=32 hex, SHA1=40, SHA256=64, SHA512=128 — local, sem API.

8. [20] Exportar resultado para arquivo
   Opção "S" para salvar a útima consulta em consultas.log / .txt
   (histórico de investigação numa pasta de trabalho).

9. [21] Consulta em lote (batch)
   Ler arquivo com lista de IPs/CEPs (1 por linha) e consultar tudo,
   salvando em CSV. Ótimo para investigação séria.

10. [22] Feriados nacionais — BrasilAPI
   GET https://brasilapi.com.br/api/feriados/v1/2026 [TEST se quiser]
   -> lista de feriados do ano. 

11. [23] Reverse geocode direto (lat,lon -> endereço)
   Reaproveita ip_consulta.py com argumento --lat --lon.

12. [24] Detector de tipo de dado de entrada
   "Isso é IP, CNPJ, CPF, CEP, e-mail, domínio, telefone, placa?"
   -> auto-detecta e consulta direto (modo inteligente, tipo `--target`.

13. [25] Atualizador automático (git pull)
   Check na inicialização: "Nova versão disponível (v2.4)? [s/N]".

14. [26] Verificador de portas comuns
   /dev/tcp (nc) nas portas 22, 80, 443, 8080, 3306 de um IP — leve.

15. [27] Informações do sistema aprimoradas
   RAM, armazenamento (df -h), CPU, sensor de temperatura (se houver).

16. [28] Gerador de QR salvando em .png (qrencode -o qr.png) + abrir.

17. [28b] Consultar NCM/CNAE — BrasilAPI tem /api/ncm/v1?descricao=... e
   /api/cnaes/v1/... -> útil para quem trabalha com empresas.

18. [29] Maskar/quemar dados: telefone/CPF/CNPJ -> máscara
   Já existe função de máscara aqui e ali; centralizar.

19. [30] Modo "investigação completa" de um alvo:
   digitar e-mail OU telefone OU nome -> roda em cadeia as consultas
   relacionadas (email -> MX + HIBP + Gravatar; telefone -> DDD + cidade...).

=================================================================
5. ARQUITETURA (sugestão para v2.4)
=================================================================
- Manter cybertrace.sh como "frontend" (menu + CLI parsing).
- Migrar TODA consulta pesada para /lib/*.py (ou funcoes.py):
    lib/ip.py, lib/telefone.py, lib/cnpj.py, lib/cep.py, lib/ddd.py...
  Vantagens: teste unitário em Python, menos bugs de quoting de bash
  (hoje o script injeta cores e variáveis dentro de código python via
  heredoc — frágil e difícil de manter).
- Config em config.conf (chaves opcionais: token Linketrack, timeout).
- Histórico em ~/.cybertrace/historico.log (CSV).
- Índice de versão + CHANGELOG.

Nota final: o projeto é bom e funcional para educação/OSINT de dados
públicos. As correções de bugs (placa, dig, DDD) são rápidas e dão
ganho grande. O caminho para v2.4 é: corrigir bugs citados + 5-6 novas
funções com as APIs acima + instalar robusto (install.sh).