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
# Valores em texto: são convertidos conforme o argumento `dec`.
#   dec = ","  (padrão, formato brasileiro) : "1.234,56" -> 1234.56
#   dec = "."  (formato americano)          : "1,234.56" -> 1234.56
#   Nos dois casos: "(500,00)" -> -500 ; "-" (ou "–", "—") -> 0 ; "" -> NA.
#   Texto que não segue o formato escolhido (ex.: "1234.56" com dec = ",") gera ERRO,
#   em vez de ser lido errado em silêncio.
#
# CSV: por padrão espera o formato brasileiro (separador ";" e decimal ","), em UTF-8
#      (com ou sem BOM). Para outro formato, use os argumentos sep, dec e codificacao.
#
# Grafia: os nomes dos indicadores têm espaços repetidos removidos e são corrigidos pela
#      tabela CORRECOES_GRAFIA (colunas `errado` e `certo`; sem diferenciar maiúsculas de
#      minúsculas). Para acrescentar correções, passe o argumento `correcoes`.
#
# Pacotes necessários: readxl e writexl (install.packages(c("readxl", "writexl"))).
# A leitura de CSV usa apenas funções do R base.

# Tabela padrão de correções de grafia: cada linha tem o nome errado e o nome certo.
# Os acentos estão escritos como \u00xx (ex.: \u00ed = í) para funcionar em qualquer
# codificação do sistema. Para acrescentar uma correção, inclua um valor em cada coluna.
CORRECOES_GRAFIA <- data.frame(
  errado = c("Intag\u00edvel"),
  certo  = c("Intang\u00edvel"),
  stringsAsFactors = FALSE
)

# Padrão aceito para um número em texto (já sem parênteses), conforme o decimal.
#   dec = "," : 1234 | 1234,56 | 1.234 | 1.234,56   (milhar com ponto)
#   dec = "." : 1234 | 1234.56 | 1,234 | 1,234.56   (milhar com vírgula)
padrao_numero <- function(dec) {
  if (dec == ",") {
    "^-?([0-9]{1,3}(\\.[0-9]{3})+|[0-9]+)(,[0-9]+)?$"
  } else {
    "^-?([0-9]{1,3}(,[0-9]{3})+|[0-9]+)(\\.[0-9]+)?$"
  }
}

# Converte texto em número, conforme o separador decimal `dec`.
#   dec = ",": "1.234,56" -> 1234.56 ; "(500,00)" -> -500 ; "-" -> 0 ; "" -> NA
#   dec = ".": "1,234.56" -> 1234.56 ; "(500.00)" -> -500
# Se algum valor não vazio não seguir o formato, interrompe com erro claro
# (nunca devolve um número errado em silêncio).
converter_numero_br <- function(x, coluna = "", dec = ",") {
  if (!is.character(x)) return(x)
  if (!(length(dec) == 1 && dec %in% c(",", "."))) {
    stop("O argumento 'dec' deve ser \",\" ou \".\".", call. = FALSE)
  }
  milhar <- if (dec == ",") "." else ","

  # remove espaços das pontas (inclusive o espaço não separável \u00a0, comum em cópias
  # do Excel); gsub com fixed = TRUE evita erro de expressão regular em sistemas não UTF-8
  y <- trimws(gsub("\u00a0", " ", x, fixed = TRUE), whitespace = "[[:space:]]")
  vazio <- is.na(y) | y == ""
  traco <- !vazio & y %in% c("-", "\u2013", "\u2014")   # hífen, meia-risca, travessão
  neg   <- !vazio & grepl("^\\(.*\\)$", y)
  y[neg] <- trimws(sub("^\\((.*)\\)$", "\\1", y[neg]))

  # válido = segue o padrão; "(-500)" (parênteses e sinal) é ambíguo, então é recusado
  valido   <- !vazio & !traco & grepl(padrao_numero(dec), y) & !(neg & grepl("^-", y))
  invalido <- !vazio & !traco & !valido
  if (any(invalido)) {
    stop("A coluna ", coluna, " tem valores que não seguem o formato numérico esperado ",
         "(decimal '", dec, "'): ",
         paste(utils::head(x[invalido], 3), collapse = ", "),
         " (linha(s) ", paste(utils::head(which(invalido) + 1, 3), collapse = ", "),
         ", contando o cabeçalho como linha 1). ",
         if (dec == ",") {
           "Se o arquivo usa ponto como decimal, use dec = \".\"."
         } else {
           "Se o arquivo usa vírgula como decimal, use dec = \",\"."
         },
         call. = FALSE)
  }

  n <- rep(NA_real_, length(y))
  n[traco] <- 0
  txt <- gsub(milhar, "", y[valido], fixed = TRUE)    # tira o separador de milhar
  if (dec == ",") txt <- sub(",", ".", txt, fixed = TRUE)  # decimal vira ponto
  n[valido] <- as.numeric(txt)
  n[neg & valido] <- -n[neg & valido]
  n
}

# Aceita a tabela (colunas `errado` e `certo`), um vetor com nomes (nome errado = nome certo)
# ou NULL (sem correção). Devolve a tabela ou NULL.
# Para palavras com acento, prefira a tabela: nomes de vetor dependem da codificação
# do sistema, as colunas de uma tabela não.
normalizar_correcoes <- function(correcoes) {
  if (length(correcoes) == 0) return(NULL)
  if (is.character(correcoes) && !is.null(names(correcoes))) {
    correcoes <- data.frame(errado = names(correcoes), certo = unname(correcoes),
                            stringsAsFactors = FALSE)
  }
  if (!is.data.frame(correcoes) || !all(c("errado", "certo") %in% names(correcoes))) {
    stop("'correcoes' deve ser uma tabela com as colunas 'errado' e 'certo' ",
         "(como CORRECOES_GRAFIA) ou um vetor com nomes, ",
         "ex.: c(\"Recieta\" = \"Receita\").", call. = FALSE)
  }
  correcoes
}

padronizar_planilha <- function(entrada, saida,
                                sep = ";", dec = ",", codificacao = "UTF-8-BOM",
                                correcoes = CORRECOES_GRAFIA) {

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
  correcoes <- normalizar_correcoes(correcoes)

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

  # Garante colunas numéricas (converte texto conforme `dec`, se for o caso)
  dados[[ano_atual]] <- converter_numero_br(dados[[ano_atual]], ano_atual, dec)
  dados[[ano_base]]  <- converter_numero_br(dados[[ano_base]],  ano_base,  dec)
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

  # Nomes dos indicadores: remove espaços repetidos/das pontas e corrige a grafia
  # pela tabela `correcoes` (sem diferenciar maiúsculas de minúsculas).
  ind <- enc2utf8(as.character(dados$indicador_original))
  ind <- gsub("\u00a0", " ", ind, fixed = TRUE)
  ind <- trimws(gsub("[[:space:]]+", " ", ind))
  if (!is.null(correcoes)) {
    errado   <- enc2utf8(as.character(correcoes$errado))
    certo    <- enc2utf8(as.character(correcoes$certo))
    posicao  <- match(tolower(ind), tolower(errado))
    corrigir <- !is.na(posicao)
    ind[corrigir] <- certo[posicao[corrigir]]
    if (any(corrigir)) {
      message("Grafia corrigida em ", sum(corrigir), " indicador(es).")
    }
  }
  dados$indicador_original <- ind

  dir.create(dirname(saida), showWarnings = FALSE, recursive = TRUE)
  writexl::write_xlsx(dados, saida)
  message("Gerado: ", saida, "  (variação ", ano_atual, " vs ", ano_base, ")")

  invisible(dados)
}
