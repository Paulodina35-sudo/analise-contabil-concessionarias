# funcoes_padronizacao.R
# Função usada pelos scripts de padronização das demonstrações das concessionárias.
#
# Entrada : planilha .xlsx com a coluna "MEDIDAS FINANCEIRAS" e DUAS colunas de ano
#           (ex.: 2025 e 2024). O ano mais recente é sempre o "atual".
# Saída   : nova planilha .xlsx (a de entrada nunca é sobrescrita) com
#           - indicador_original : nome do indicador (com a grafia corrigida)
#           - variacao           : valor do ano atual menos o do ano base
#           - variacao_percentual: variacao / |valor do ano base| * 100, em %
#                                  (NA quando o ano base é zero ou ausente)
#
# Por que |base| (valor absoluto)? Com base negativa, a fórmula (atual - base) / base
# troca o sinal: prejuízo -> lucro apareceria como variação negativa.
#
# Pacotes necessários: readxl e writexl (install.packages(c("readxl", "writexl"))).

padronizar_planilha <- function(entrada, saida) {

  for (pacote in c("readxl", "writexl")) {
    if (!requireNamespace(pacote, quietly = TRUE)) {
      stop("Instale o pacote '", pacote, "': install.packages(\"", pacote, "\")",
           call. = FALSE)
    }
  }
  if (!file.exists(entrada)) {
    stop("Arquivo de entrada não encontrado: ", entrada,
         "\nConfira o caminho e o diretório de trabalho (getwd()).", call. = FALSE)
  }
  if (identical(normalizePath(entrada), normalizePath(saida, mustWork = FALSE))) {
    stop("A saída não pode ter o mesmo caminho da entrada.", call. = FALSE)
  }

  dados <- readxl::read_excel(entrada)

  # Nome da primeira coluna
  if (!"MEDIDAS FINANCEIRAS" %in% names(dados)) {
    stop("A planilha precisa ter a coluna 'MEDIDAS FINANCEIRAS'.", call. = FALSE)
  }
  names(dados)[names(dados) == "MEDIDAS FINANCEIRAS"] <- "indicador_original"

  # Identifica as duas colunas de ano (o mais recente é o ano atual)
  anos <- grep("^[0-9]{4}$", names(dados), value = TRUE)
  if (length(anos) != 2) {
    stop("Esperava exatamente duas colunas de ano; encontrei: ",
         if (length(anos)) paste(anos, collapse = ", ") else "nenhuma", call. = FALSE)
  }
  anos      <- sort(anos, decreasing = TRUE)
  ano_atual <- anos[1]
  ano_base  <- anos[2]

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
  dados$indicador_original[dados$indicador_original %in% "Intagível"] <- "Intangível"

  dir.create(dirname(saida), showWarnings = FALSE, recursive = TRUE)
  writexl::write_xlsx(dados, saida)
  message("Gerado: ", saida, "  (variação ", ano_atual, " vs ", ano_base, ")")

  invisible(dados)
}
