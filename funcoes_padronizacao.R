# funcoes_padronizacao.R
# Função usada pelos scripts de padronização das demonstrações das concessionárias.
#
# Entrada : planilha .xlsx ou arquivo .csv com a coluna "MEDIDAS FINANCEIRAS" e DUAS
#           colunas de ano (ex.: 2025 e 2024). O ano mais recente é sempre o "atual".
# Saída   : nova planilha .xlsx (o arquivo de entrada nunca é sobrescrito) com
#           - indicador_original : nome do indicador (com a grafia corrigida)
#           - variacao           : valor do ano atual menos o do ano base
#           - variacao_percentual: variacao / |valor do ano base| * 100, em %
#                                  (NA quando o ano base é zero ou ausente)
#
# Por que |base| (valor absoluto)? Com base negativa, a fórmula (atual - base) / base
# troca o sinal: prejuízo -> lucro apareceria como variação negativa.
#
# CSV: por padrão espera o formato brasileiro (separador ";" e decimal ","), em UTF-8
#      (com ou sem BOM). Para outro formato, use os argumentos sep, dec e codificacao.
#      Valores como "1.234,56", "(500,00)" (negativo) e "-" (zero) são convertidos.
#
# Pacotes necessários: readxl e writexl (install.packages(c("readxl", "writexl"))).
# A leitura de CSV usa apenas funções do R base.

# Converte texto em formato brasileiro para número.
#   "1.234,56" -> 1234.56 ; "(500,00)" -> -500 ; "-" -> 0 ; "" -> NA
# Se algum valor não vazio não puder ser convertido, interrompe com erro claro.
converter_numero_br <- function(x, coluna = "") {
  if (!is.character(x)) return(x)
  y <- trimws(x)
  vazio <- is.na(y) | y == ""
  traco <- !vazio & y == "-"
  neg   <- !vazio & grepl("^\\(.*\\)$", y)
  y <- gsub("[()]", "", y)
  y <- gsub(".", "", y, fixed = TRUE)    # separador de milhar
  y <- sub(",", ".", y, fixed = TRUE)    # decimal
  n <- suppressWarnings(as.numeric(y))
  n[traco] <- 0
  n[vazio] <- NA_real_
  n[neg]   <- -n[neg]
  invalido <- !vazio & !traco & is.na(n)
  if (any(invalido)) {
    stop("A coluna ", coluna, " tem valores que não são números: ",
         paste(utils::head(x[invalido], 3), collapse = ", "),
         " (linha(s) ", paste(utils::head(which(invalido), 3), collapse = ", "), ").",
         call. = FALSE)
  }
  n
}

padronizar_planilha <- function(entrada, saida,
                                sep = ";", dec = ",", codificacao = "UTF-8-BOM") {

  if (!requireNamespace("writexl", quietly = TRUE)) {
    stop("Instale o pacote 'writexl': install.packages(\"writexl\")", call. = FALSE)
  }
  if (!file.exists(entrada)) {
    stop("Arquivo de entrada não encontrado: ", entrada,
         "\nConfira o caminho e o diretório de trabalho (getwd()).", call. = FALSE)
  }
  if (identical(normalizePath(entrada), normalizePath(saida, mustWork = FALSE))) {
    stop("A saída não pode ter o mesmo caminho da entrada.", call. = FALSE)
  }

  # Leitura: .xlsx/.xls (readxl) ou .csv (R base)
  extensao <- tolower(tools::file_ext(entrada))
  if (extensao %in% c("xlsx", "xls")) {
    if (!requireNamespace("readxl", quietly = TRUE)) {
      stop("Instale o pacote 'readxl': install.packages(\"readxl\")", call. = FALSE)
    }
    dados <- readxl::read_excel(entrada)
  } else if (extensao == "csv") {
    # UTF-8: só marca a codificação (funciona em qualquer sistema/idioma do R).
    # Outras (ex.: "latin1", comum em CSV salvo pelo Excel): converte na leitura.
    if (toupper(codificacao) %in% c("UTF-8", "UTF-8-BOM", "UTF8")) {
      dados <- utils::read.csv(entrada, sep = sep, dec = dec, check.names = FALSE,
                               stringsAsFactors = FALSE, encoding = "UTF-8",
                               strip.white = TRUE)
    } else {
      dados <- utils::read.csv(entrada, sep = sep, dec = dec, check.names = FALSE,
                               stringsAsFactors = FALSE, fileEncoding = codificacao,
                               strip.white = TRUE)
    }
  } else {
    stop("Formato não suportado: .", extensao, ". Use .xlsx, .xls ou .csv.",
         call. = FALSE)
  }

  # Nome da primeira coluna
  # (procura pelo texto, porque um CSV salvo com BOM coloca marcas invisíveis no início)
  col_ind <- which(grepl("MEDIDAS FINANCEIRAS", names(dados), fixed = TRUE, useBytes = TRUE))
  if (length(col_ind) != 1) {
    stop("O arquivo precisa ter a coluna 'MEDIDAS FINANCEIRAS'.",
         if (extensao == "csv") " Se o CSV tiver outro separador, use o argumento 'sep'." else "",
         call. = FALSE)
  }
  names(dados)[col_ind] <- "indicador_original"

  # Identifica as duas colunas de ano (o mais recente é o ano atual)
  anos <- grep("^[0-9]{4}$", names(dados), value = TRUE)
  if (length(anos) != 2) {
    stop("Esperava exatamente duas colunas de ano; encontrei: ",
         if (length(anos)) paste(anos, collapse = ", ") else "nenhuma",
         if (extensao == "csv") ". Se o CSV tiver outro separador, use o argumento 'sep'." else "",
         call. = FALSE)
  }
  anos      <- sort(anos, decreasing = TRUE)
  ano_atual <- anos[1]
  ano_base  <- anos[2]

  # Garante colunas numéricas (converte texto em formato brasileiro, se for o caso)
  dados[[ano_atual]] <- converter_numero_br(dados[[ano_atual]], ano_atual)
  dados[[ano_base]]  <- converter_numero_br(dados[[ano_base]],  ano_base)
  atual <- dados[[ano_atual]]
  base  <- dados[[ano_base]]
  if (!is.numeric(atual) || !is.numeric(base)) {
    stop("As colunas ", ano_atual, " e ", ano_base,
         " precisam ser numéricas (confira textos ou separadores de milhar).",
         call. = FALSE)
  }

  # Variação absoluta e percentual
  dados$variacao <- atual - base
  pct <- (atual - base) / abs(base) * 100          # base 0 -> Inf/NaN
  dados$variacao_percentual <- round(ifelse(is.finite(pct), pct, NA_real_), 2)

  # Grafia
  # (acentos escritos como í para funcionar em qualquer codificação do sistema)
  dados$indicador_original <- enc2utf8(as.character(dados$indicador_original))
  erro_grafia <- charToRaw("Intagível")
  eh_erro <- vapply(dados$indicador_original,
                    function(s) identical(charToRaw(s), erro_grafia), logical(1))
  dados$indicador_original[eh_erro] <- "Intangível"

  dir.create(dirname(saida), showWarnings = FALSE, recursive = TRUE)
  writexl::write_xlsx(dados, saida)
  message("Gerado: ", saida, "  (variação ", ano_atual, " vs ", ano_base, ")")

  invisible(dados)
}
