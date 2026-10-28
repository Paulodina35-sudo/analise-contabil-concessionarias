# Automatização da Análise Contábil com R

Scripts em R que padronizam as demonstrações financeiras de concessionárias de aeroportos e calculam a variação entre dois anos. Fazem parte do pôster **"Proposição de Análise Automatizada Contábil com R"**, apresentado no XI Encontro de Iniciação Acadêmica da UFC.

**Autores:** Paulo Fuakala Dina (Finanças, UFC).
**Orientador:** Francisco Gildemir Ferreira da Silva.

A versão final dos scripts foi revisada com ajuda de IA.

## Funcionalidades

- **Importação de arquivo local** em `.xlsx`, `.xls` ou `.csv` (veja [Importação de arquivo local (CSV)](#importação-de-arquivo-local-csv)).
- **Padronização** do nome da coluna de indicadores e correção de grafia por tabela (veja [Padronização](#padronização)).
- **Variação absoluta e percentual** entre o ano mais recente e o ano anterior, com tratamento de base negativa e de divisão por zero.
- **Detecção automática dos anos**: funciona com 2025 vs 2024, 2024 vs 2023 e assim por diante.
- **Conversão de números em texto** (formato brasileiro por padrão: `1.234,56`, `(500,00)` para negativo, `-` para zero). Texto fora do formato esperado gera erro, em vez de ser lido errado.
- **Exportação em `.xlsx`**, sem nunca sobrescrever o arquivo de entrada.
- **Mensagens de erro claras** quando o arquivo não tem a estrutura esperada.

## Instalação

Este repositório não é um pacote do R: basta baixar os arquivos e instalar duas dependências.

1. Clone o repositório (ou baixe o ZIP pelo botão **Code** do GitHub):

   ```bash
   git clone https://github.com/Paulodina35-sudo/analise-contabil-concessionarias
   ```

2. No R, instale os pacotes:

   ```r
   install.packages(c("readxl", "writexl"))
   ```

   O `writexl` é sempre necessário (grava o resultado). O `readxl` só é usado para ler `.xlsx` e `.xls`; a leitura de `.csv` usa apenas o R base.

3. Abra o projeto no RStudio (ou use `setwd()`) de modo que o diretório de trabalho seja a **raiz do projeto**, a pasta onde está o arquivo `funcoes_padronizacao.R`.

## Exemplo de Uso

O arquivo `exemplo_ficticio.xlsx`, na raiz do projeto, traz **dados fictícios** (inventados, sem relação com nenhuma empresa), só para demonstrar o funcionamento. O conteúdo dele é:

| MEDIDAS FINANCEIRAS | 2025 | 2024 |
|---|---:|---:|
| Receita total | 10000 | 8000 |
| Lucro bruto | 4000 | 3200 |
| Resultado do exercício | 250 | -400 |
| Intagível | 9000 | 8500 |
| Item sem valor no ano base | 100 | 0 |

```r
source("funcoes_padronizacao.R")

padronizar_planilha(
  entrada = "exemplo_ficticio.xlsx",
  saida   = "exemplo_ficticio_padronizado.xlsx"
)
```

A planilha gerada tem estas colunas:

| indicador_original | 2025 | 2024 | variacao | variacao_percentual |
|---|---:|---:|---:|---:|
| Receita total | 10000 | 8000 | 2000 | 25 |
| Lucro bruto | 4000 | 3200 | 800 | 25 |
| Resultado do exercício | 250 | -400 | 650 | 162,5 |
| Intangível | 9000 | 8500 | 500 | 5,88 |
| Item sem valor no ano base | 100 | 0 | 100 | *(vazio)* |

Repare que "Intagível" foi corrigido para "Intangível", que a passagem de prejuízo para lucro aparece como variação positiva e que a variação percentual fica vazia quando o ano base é zero.

Para as concessionárias do projeto, rode o script correspondente (com as planilhas na pasta `Coleta de dados/`):

```r
source("Aeroporto_RJ_2025.R")
```

## Padronização

Para cada arquivo de entrada, a função `padronizar_planilha()`:

1. lê o arquivo e confere se ele tem a coluna `MEDIDAS FINANCEIRAS`;
2. renomeia essa coluna para `indicador_original`;
3. identifica as duas colunas de ano (o mais recente é o ano "atual");
4. converte para número os valores que vierem como texto (formato definido por `dec`, padrão brasileiro) e interrompe com erro se algum valor não seguir o formato;
5. calcula a variação absoluta (`variacao`) e a variação percentual (`variacao_percentual`);
6. remove espaços repetidos nos nomes dos indicadores e corrige a grafia pela tabela `CORRECOES_GRAFIA` (hoje: "Intagível" → "Intangível", sem diferenciar maiúsculas de minúsculas);
7. grava uma nova planilha `.xlsx`, criando a pasta de saída se ela não existir.

**Variação percentual:** `(ano atual − ano base) / |ano base| × 100`, arredondada em 2 casas. Usa-se o valor absoluto do ano base para que a mudança de prejuízo para lucro apareça como variação positiva. Quando o ano base é zero ou está vazio, o resultado fica vazio (`NA`).

**Correção de grafia:** a tabela `CORRECOES_GRAFIA`, no início de `funcoes_padronizacao.R`, tem uma coluna `errado` e uma `certo`. Para acrescentar uma correção, inclua um valor em cada coluna ou passe o argumento `correcoes` (que substitui a tabela padrão; use `rbind(CORRECOES_GRAFIA, ...)` para somar):

```r
padronizar_planilha("dados.csv", "dados_padronizado.xlsx",
                    correcoes = rbind(CORRECOES_GRAFIA,
                                      data.frame(errado = "Recieta", certo = "Receita")))
```

O argumento `correcoes` também aceita um vetor com nomes, como `c("Recieta" = "Receita")`, mas para palavras com acento prefira a tabela, que funciona em qualquer sistema.

## Importação de arquivo local (CSV)

Além de `.xlsx` e `.xls`, a função aceita arquivos `.csv` salvos no computador. O formato é reconhecido pela extensão do arquivo de entrada.

```r
padronizar_planilha(
  entrada = "Coleta de dados/minha_concessionaria.csv",
  saida   = "Coleta de dados/minha_concessionaria_padronizado.xlsx"
)
```

O arquivo `exemplo_ficticio.csv`, na raiz do projeto, traz os mesmos dados fictícios do exemplo em Excel, em CSV no formato brasileiro. Para testar:

```r
padronizar_planilha(
  entrada = "exemplo_ficticio.csv",
  saida   = "exemplo_ficticio_csv_padronizado.xlsx"
)
```

Por padrão, o CSV deve estar no formato brasileiro (separador `;`, decimal `,`, codificação UTF-8, com ou sem BOM). Para outros formatos, use os argumentos:

| Argumento | Padrão | Para que serve |
|---|---|---|
| `sep` | `";"` | Separador de colunas (use `","` para CSV no padrão americano) |
| `dec` | `","` | Separador decimal (use `"."` no padrão americano) |
| `codificacao` | `"UTF-8-BOM"` | Codificação do arquivo (use `"latin1"` para CSV salvo pelo Excel em alguns computadores) |

```r
# CSV com vírgula como separador e ponto decimal
padronizar_planilha("dados.csv", "dados_padronizado.xlsx", sep = ",", dec = ".")

# CSV salvo em latin1
padronizar_planilha("dados.csv", "dados_padronizado.xlsx", codificacao = "latin1")
```

Valores de texto são convertidos em número conforme o argumento `dec`:

- `dec = ","` (padrão): aceita `1.234,56`;
- `dec = "."`: aceita `1,234.56`;
- nos dois casos, `(500,00)` é negativo e `-` (também `–` e `—`) é zero.

Se algum valor não seguir o formato (por exemplo, `1234.56` com `dec = ","`), a função para e informa a coluna e a linha com problema, em vez de ler o número errado. O argumento `dec` vale também para células de texto em arquivos Excel; colunas do Excel que misturam números e texto em formatos diferentes devem ser padronizadas antes.

**Formato esperado do arquivo (CSV ou planilha):** uma aba (no caso do Excel), com a coluna `MEDIDAS FINANCEIRAS` (nome do indicador) e **duas** colunas de ano, por exemplo `2025` e `2024`. Os valores são em R$ mil, conforme as demonstrações financeiras.

## Arquivos

| Arquivo | Função |
|---|---|
| `funcoes_padronizacao.R` | Função `padronizar_planilha()` (usada pelos três scripts), conversão de números e tabela `CORRECOES_GRAFIA` |
| `Aeroporto_RJ_2025.R` | Concessionária Aeroporto Rio de Janeiro, 2025 vs 2024 |
| `PRS_Aeroporto_25.R` | PRS Aeroportos, 2025 vs 2024 |
| `Concessionaria_dos_Aeroportos_de_Manaus.R` | Concessionária dos Aeroportos da Amazônia, 2024 vs 2023 |
| `exemplo_ficticio.xlsx` | Dados fictícios para testar a função (Excel) |
| `exemplo_ficticio.csv` | Os mesmos dados fictícios, em CSV |
| `Poster_Paulo_Dina.pdf` | Pôster apresentado no encontro |

As planilhas das concessionárias **não** estão neste repositório.

## Fontes dos dados

Demonstrações financeiras das três concessionárias (veja as referências no pôster). Os dados do Aeroporto Rio de Janeiro foram obtidos junto à ANAC por pedido de acesso à informação.

## Escopo e próximos passos

Este código faz a **padronização e o cálculo das variações**. Os indicadores que aparecem no pôster (liquidez, endividamento e peso do intangível no ativo) foram calculados em planilha Excel e **ainda não são gerados por este código**.

Próximo passo: automatizar o cálculo dos indicadores (liquidez, estrutura de capital, endividamento e rentabilidade), tendo como base o pacote [adcontabil](https://github.com/LissandroSousa/adcontabil.R).

## Contribuição

Contribuições são bem-vindas. Para sugerir uma melhoria ou relatar um problema:

1. abra uma *issue* descrevendo o que aconteceu (de preferência com a mensagem de erro e um exemplo pequeno, com dados fictícios);
2. para propor uma alteração no código, faça um *fork*, crie uma *branch* e envie um *pull request*.

Para incluir uma nova concessionária, copie um dos scripts (por exemplo, `PRS_Aeroporto_25.R`) e troque os caminhos de entrada e de saída. Não envie demonstrações que não sejam públicas (a pasta `Coleta de dados/` já está no `.gitignore`).

## Licença

MIT.


