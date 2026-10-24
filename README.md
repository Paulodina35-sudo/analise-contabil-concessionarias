# Analise contábil automatizada em R

Scripts em R que padronizam as demonstrações financeiras de concessionárias de aeroportos e calculam a variação entre dois anos. Fazem parte do pôster **"Proposição de Análise Automatizada Contábil com R"**, apresentado no XI Encontro de Iniciação Acadêmica da UFC.

**Autores:** Paulo Fuakala Dina e Sofia dos Santos Ferreira (Finanças, UFC). Apoio: PIBITI/CNPq · UFC.

A versão final dos scripts foi revisada por nós, com ajuda de IA (Claude, Anthropic).

## O que o código faz

Para cada planilha de entrada, o código:

1. renomeia a coluna `MEDIDAS FINANCEIRAS` para `indicador_original`;
2. calcula a variação absoluta (`variacao`) entre o ano mais recente e o ano anterior;
3. calcula a variação percentual (`variacao_percentual`);
4. grava uma nova planilha `.xlsx`, sem sobrescrever a de entrada.

**Variação percentual:** `(ano atual − ano base) / |ano base| × 100`, arredondada em 2 casas. Usa-se o valor absoluto do ano base para que a mudança de prejuízo para lucro apareça como variação positiva. Quando o ano base é zero, o resultado fica vazio (`NA`).

## Arquivos

| Arquivo | Função |
|---|---|
| `funcoes_padronizacao.R` | Função `padronizar_planilha()`, usada pelos três scripts |
| `Aeroporto_RJ_2025.R` | Concessionária Aeroporto Rio de Janeiro, 2025 vs 2024 |
| `PRS_Aeroporto_25.R` | PRS Aeroportos, 2025 vs 2024 |
| `Concessionaria_dos_Aeroportos_de_Manaus.R` | Concessionária dos Aeroportos da Amazônia, 2024 vs 2023 |

## Como usar

1. Instale os pacotes: `install.packages(c("readxl", "writexl"))`.
2. Crie a pasta `Coleta de dados/` na raiz do projeto, com as planilhas de entrada (veja o formato abaixo). As planilhas **não** estão neste repositório.
3. Com o diretório de trabalho na raiz do projeto, rode um script, por exemplo: `source("Aeroporto_RJ_2025.R")`.

## Formato da planilha de entrada

Uma aba, com a coluna `MEDIDAS FINANCEIRAS` (nome do indicador) e **duas** colunas numéricas de ano, por exemplo `2025` e `2024`. Os valores são em R$ mil, conforme as demonstrações financeiras. O código identifica os anos sozinho.

## Fontes dos dados

Demonstrações financeiras das três concessionárias (veja as referências no pôster). Os dados do Aeroporto Rio de Janeiro foram obtidos junto à ANAC por pedido de acesso à informação.

## Próximos passos

Automatizar o cálculo dos indicadores (liquidez, estrutura de capital, endividamento e rentabilidade), tendo como base o pacote [adcontabil](https://github.com/LissandroSousa/adcontabil.R).

## Licença

MIT.
