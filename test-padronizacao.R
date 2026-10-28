# Testes de funcoes_padronizacao.R
#
# Como rodar (no R, com o diretório de trabalho na raiz do projeto):
#   install.packages(c("testthat", "readxl", "writexl"))
#   testthat::test_dir("tests/testthat")
#
# Os testes só usam dados fictícios e gravam tudo em pastas temporárias:
# nenhum arquivo do projeto é alterado.

library(testthat)
source(file.path("..", "..", "funcoes_padronizacao.R"), local = TRUE)

# ---- auxiliares -------------------------------------------------------------

# Grava linhas de texto em um CSV temporário (em UTF-8, com ou sem BOM, ou em latin1).
escrever_csv <- function(linhas, bom = FALSE, latin1 = FALSE) {
  arq <- tempfile(fileext = ".csv")
  if (latin1) linhas <- iconv(linhas, from = "UTF-8", to = "latin1")
  con <- file(arq, open = "wb")
  if (bom) writeBin(as.raw(c(0xef, 0xbb, 0xbf)), con)
  writeLines(linhas, con, useBytes = TRUE)
  close(con)
  arq
}

# Roda padronizar_planilha() sem imprimir mensagens e devolve a tabela resultante.
rodar <- function(entrada, ...) {
  saida <- tempfile(fileext = ".xlsx")
  suppressMessages(padronizar_planilha(entrada, saida, ...))
}

# Os mesmos dados fictícios do README (formato brasileiro).
linhas_readme <- c(
  "MEDIDAS FINANCEIRAS;2025;2024",
  "Receita total;\"10.000,00\";\"8.000,00\"",
  "Lucro bruto;\"4.000,00\";\"3.200,00\"",
  "Resultado do exerc\u00edcio;\"250,00\";\"(400,00)\"",
  "Intag\u00edvel;\"9.000,00\";\"8.500,00\"",
  "Item sem valor no ano base;\"100,00\";\"-\""
)

# ---- converter_numero_br() --------------------------------------------------

test_that("converte o formato brasileiro", {
  entrada <- c("1.234,56", "(500,00)", "-", "", NA, " 7 ", "0,5", "1.234", "-1.500,25")
  esperado <- c(1234.56, -500, 0, NA, NA, 7, 0.5, 1234, -1500.25)
  expect_equal(converter_numero_br(entrada), esperado)
})

test_that("meia-risca e travess\u00e3o contam como zero", {
  expect_equal(converter_numero_br(c("\u2013", "\u2014")), c(0, 0))
})

test_that("converte o formato americano quando dec = '.'", {
  entrada <- c("1,234.56", "(1,000)", "12.5", "(500.00)")
  expect_equal(converter_numero_br(entrada, dec = "."), c(1234.56, -1000, 12.5, -500))
})

test_that("n\u00fameros que j\u00e1 s\u00e3o num\u00e9ricos passam sem mudan\u00e7a", {
  expect_identical(converter_numero_br(c(1, 2.5, NA)), c(1, 2.5, NA))
})

test_that("texto fora do formato gera erro, e n\u00e3o um n\u00famero errado", {
  # antes da correção, "1234.56" virava 123456 e "(500.00)" virava -50000
  expect_error(converter_numero_br("1234.56", "2025"), "1234.56", fixed = TRUE)
  expect_error(converter_numero_br("(500.00)", "2025"), "(500.00)", fixed = TRUE)
  expect_error(converter_numero_br("1,234.56", "2025"), "1,234.56", fixed = TRUE)
  expect_error(converter_numero_br("(-500,00)", "2025"))
  expect_error(converter_numero_br("abc", "2025"), "abc", fixed = TRUE)
  expect_error(converter_numero_br("1.5", "2025"), "1.5", fixed = TRUE)
  expect_error(converter_numero_br("12,5", "2025", dec = "."), "12,5", fixed = TRUE)
})

test_that("a mensagem de erro informa coluna e linha (cabe\u00e7alho = linha 1)", {
  expect_error(converter_numero_br(c("1,00", "xx"), "2024"), "2024")
  expect_error(converter_numero_br(c("1,00", "xx"), "2024"), "linha(s) 3", fixed = TRUE)
})

test_that("'dec' inv\u00e1lido gera erro", {
  expect_error(converter_numero_br("1", dec = ";"), "dec")
})

# ---- padronizar_planilha(): exemplos do README ------------------------------

test_that("CSV brasileiro do README gera as varia\u00e7\u00f5es esperadas", {
  skip_if_not_installed("writexl")
  res <- rodar(escrever_csv(linhas_readme))
  expect_equal(res$variacao, c(2000, 800, 650, 500, 100))
  expect_equal(res$variacao_percentual, c(25, 25, 162.5, 5.88, NA))
  expect_equal(res$indicador_original[4], "Intang\u00edvel")
})

test_that("CSV com BOM da o mesmo resultado que sem BOM", {
  skip_if_not_installed("writexl")
  sem_bom <- rodar(escrever_csv(linhas_readme))
  com_bom <- rodar(escrever_csv(linhas_readme, bom = TRUE))
  expect_equal(com_bom$variacao, sem_bom$variacao)
  expect_equal(com_bom$indicador_original, sem_bom$indicador_original)
})

test_that("CSV em latin1 da o mesmo resultado que em UTF-8", {
  skip_if_not_installed("writexl")
  skip_if(!isTRUE(l10n_info()[["UTF-8"]]),
          "a leitura de CSV em latin1 depende de o sistema usar UTF-8")
  sem_bom   <- rodar(escrever_csv(linhas_readme))
  em_latin1 <- rodar(escrever_csv(linhas_readme, latin1 = TRUE), codificacao = "latin1")
  expect_equal(em_latin1$variacao_percentual, sem_bom$variacao_percentual)
  expect_equal(em_latin1$indicador_original, sem_bom$indicador_original)
})

test_that("os arquivos de exemplo do reposit\u00f3rio reproduzem a tabela do README", {
  skip_if_not_installed("writexl")
  esperado_variacao <- c(2000, 800, 650, 500, 100)
  esperado_pct <- c(25, 25, 162.5, 5.88, NA)

  csv <- file.path("..", "..", "exemplo_ficticio.csv")
  skip_if_not(file.exists(csv))
  res_csv <- rodar(csv)
  expect_equal(res_csv$variacao, esperado_variacao)
  expect_equal(res_csv$variacao_percentual, esperado_pct)
  expect_equal(res_csv$indicador_original[4], "Intang\u00edvel")

  xlsx <- file.path("..", "..", "exemplo_ficticio.xlsx")
  skip_if_not(file.exists(xlsx))
  skip_if_not_installed("readxl")
  res_xlsx <- rodar(xlsx)
  expect_equal(res_xlsx$variacao, esperado_variacao)
  expect_equal(res_xlsx$variacao_percentual, esperado_pct)
  expect_equal(res_xlsx$indicador_original[4], "Intang\u00edvel")
})

# ---- padronizar_planilha(): variação percentual -----------------------------

test_that("base negativa, base zero e zero para zero", {
  skip_if_not_installed("writexl")
  linhas <- c(
    "MEDIDAS FINANCEIRAS;2025;2024",
    "Preju\u00edzo menor;-100;-200",
    "Preju\u00edzo maior;-200;-100",
    "Zero para zero;0;0",
    "Zero para positivo;50;0"
  )
  res <- rodar(escrever_csv(linhas))
  expect_equal(res$variacao, c(100, -100, 0, 50))
  expect_equal(res$variacao_percentual, c(50, -100, NA, NA))
})

test_that("o ano mais recente \u00e9 o 'atual', mesmo com as colunas em ordem invertida", {
  skip_if_not_installed("writexl")
  linhas <- c("MEDIDAS FINANCEIRAS;2023;2024", "Receita;100;150")
  res <- rodar(escrever_csv(linhas))
  expect_equal(res$variacao, 50)          # 2024 - 2023
  expect_equal(res$variacao_percentual, 50)
})

# ---- padronizar_planilha(): formatos ----------------------------------------

test_that("CSV americano (sep = ',', dec = '.') com milhar e par\u00eanteses", {
  skip_if_not_installed("writexl")
  linhas <- c(
    "MEDIDAS FINANCEIRAS,2025,2024",
    "Receita total,\"10,000.50\",\"8,000.00\"",
    "Resultado,\"(250.00)\",\"(400.00)\""
  )
  res <- rodar(escrever_csv(linhas), sep = ",", dec = ".")
  expect_equal(res$variacao, c(2000.5, 150))
  expect_equal(res$variacao_percentual, c(25.01, 37.5))
})

test_that("CSV americano lido como brasileiro d\u00e1 erro em vez de n\u00famero errado", {
  skip_if_not_installed("writexl")
  linhas <- c(
    "MEDIDAS FINANCEIRAS;2025;2024",
    "Receita total;\"1234.56\";\"1000.00\""
  )
  expect_error(rodar(escrever_csv(linhas)), "dec")
})

test_that("l\u00ea .xlsx com texto em formato brasileiro e com n\u00fameros", {
  skip_if_not_installed("readxl")
  skip_if_not_installed("writexl")

  texto <- data.frame(
    "MEDIDAS FINANCEIRAS" = c("Receita total", "Resultado"),
    "2025" = c("10.000,00", "(250,00)"),
    "2024" = c("8.000,00", "(400,00)"),
    check.names = FALSE, stringsAsFactors = FALSE
  )
  arq_texto <- tempfile(fileext = ".xlsx")
  writexl::write_xlsx(texto, arq_texto)
  res_texto <- rodar(arq_texto)
  expect_equal(res_texto$variacao, c(2000, 150))
  expect_equal(res_texto$variacao_percentual, c(25, 37.5))

  numeros <- data.frame(
    "MEDIDAS FINANCEIRAS" = c("Receita total", "Resultado"),
    "2025" = c(10000, 250),
    "2024" = c(8000, -400),
    check.names = FALSE
  )
  arq_numeros <- tempfile(fileext = ".xlsx")
  writexl::write_xlsx(numeros, arq_numeros)
  res_numeros <- rodar(arq_numeros)
  expect_equal(res_numeros$variacao, c(2000, 650))
  expect_equal(res_numeros$variacao_percentual, c(25, 162.5))
})

# ---- padronizar_planilha(): grafia ------------------------------------------

test_that("corrige a grafia ignorando espa\u00e7os extras e mai\u00fasculas/min\u00fasculas", {
  skip_if_not_installed("writexl")
  linhas <- c(
    "MEDIDAS FINANCEIRAS;2025;2024",
    "\" Intag\u00edvel  \";100;50",
    "intag\u00edvel;100;50",
    "\"Receita   total\";100;50"
  )
  res <- rodar(escrever_csv(linhas))
  expect_equal(res$indicador_original,
               c("Intang\u00edvel", "Intang\u00edvel", "Receita total"))
})

test_that("tabela de corre\u00e7\u00f5es pr\u00f3pria substitui a padr\u00e3o; NULL desliga a corre\u00e7\u00e3o", {
  skip_if_not_installed("writexl")
  linhas <- c("MEDIDAS FINANCEIRAS;2025;2024", "Recieta;100;50", "Intag\u00edvel;100;50")
  entrada <- escrever_csv(linhas)

  res_propria <- rodar(entrada, correcoes = c("Recieta" = "Receita"))
  expect_equal(res_propria$indicador_original, c("Receita", "Intag\u00edvel"))

  res_soma <- rodar(entrada, correcoes = rbind(CORRECOES_GRAFIA, data.frame(errado = "Recieta", certo = "Receita")))
  expect_equal(res_soma$indicador_original, c("Receita", "Intang\u00edvel"))

  res_nenhuma <- rodar(entrada, correcoes = NULL)
  expect_equal(res_nenhuma$indicador_original, c("Recieta", "Intag\u00edvel"))
})

test_that("'correcoes' sem nomes gera erro", {
  skip_if_not_installed("writexl")
  entrada <- escrever_csv(linhas_readme)
  expect_error(rodar(entrada, correcoes = c("Receita")), "correcoes")
})

# ---- padronizar_planilha(): erros e segurança -------------------------------

test_that("erros de estrutura s\u00e3o claros", {
  skip_if_not_installed("writexl")
  saida <- tempfile(fileext = ".xlsx")

  sem_coluna <- escrever_csv(c("INDICADOR;2025;2024", "Receita;1;2"))
  expect_error(padronizar_planilha(sem_coluna, saida), "MEDIDAS FINANCEIRAS")

  tres_anos <- escrever_csv(c("MEDIDAS FINANCEIRAS;2025;2024;2023", "Receita;1;2;3"))
  expect_error(padronizar_planilha(tres_anos, saida), "duas colunas de ano")

  expect_error(padronizar_planilha(file.path(tempdir(), "nao_existe.csv"), saida),
               "Arquivo de entrada")

  txt <- tempfile(fileext = ".txt")
  writeLines("qualquer coisa", txt)
  expect_error(padronizar_planilha(txt, saida), "suportado")
})

test_that("a sa\u00edda nunca pode ser o arquivo de entrada", {
  skip_if_not_installed("writexl")
  entrada <- escrever_csv(linhas_readme)
  conteudo <- readLines(entrada, warn = FALSE)
  expect_error(padronizar_planilha(entrada, entrada), "mesmo caminho")
  expect_identical(readLines(entrada, warn = FALSE), conteudo)
})

test_that("cria a pasta de sa\u00edda se ela n\u00e3o existir", {
  skip_if_not_installed("writexl")
  saida <- file.path(tempfile("pasta_nova"), "sub", "resultado.xlsx")
  suppressMessages(padronizar_planilha(escrever_csv(linhas_readme), saida))
  expect_true(file.exists(saida))
})
